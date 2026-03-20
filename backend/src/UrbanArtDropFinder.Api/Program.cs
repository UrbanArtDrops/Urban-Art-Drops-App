using System.Security.Claims;
using System.Text;
using System.Net.Http.Headers;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using Microsoft.IdentityModel.Tokens;
using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Application.Auth;
using UrbanArtDropFinder.Application.Drops;
using UrbanArtDropFinder.Contracts.Admin;
using UrbanArtDropFinder.Contracts.Art;
using UrbanArtDropFinder.Contracts.Auth;
using UrbanArtDropFinder.Contracts.Comments;
using UrbanArtDropFinder.Contracts.Drops;
using UrbanArtDropFinder.Contracts.Moderation;
using UrbanArtDropFinder.Contracts.Profile;
using UrbanArtDropFinder.Domain.Art;
using UrbanArtDropFinder.Domain.Comments;
using UrbanArtDropFinder.Domain.Configuration;
using UrbanArtDropFinder.Domain.Drops;
using UrbanArtDropFinder.Domain.Shared;
using UrbanArtDropFinder.Domain.Users;
using UrbanArtDropFinder.Api.Services;
using UrbanArtDropFinder.Infrastructure.DependencyInjection;
using UrbanArtDropFinder.Infrastructure.Authentication;
using UrbanArtDropFinder.Persistence.Db;

var builder = WebApplication.CreateBuilder(args);
var jwtOptions = JwtAuthenticationOptionsResolver.Resolve(builder.Configuration, builder.Environment.EnvironmentName);

builder.WebHost.ConfigureKestrel(options =>
{
    options.ConfigureEndpointDefaults(endpointOptions =>
    {
        endpointOptions.Protocols = HttpProtocols.Http1AndHttp2;
    });
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddGrpc();
builder.Services.AddHttpClient("photo-fetcher");
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateIssuerSigningKey = true,
            ValidateLifetime = true,
            ValidIssuer = jwtOptions.Issuer,
            ValidAudience = jwtOptions.Audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtOptions.SigningKey!)),
            ClockSkew = TimeSpan.FromMinutes(1)
        };
    });
builder.Services.AddAuthorization(options =>
{
    options.AddPolicy(AuthPolicies.ApprovedAccount, policy => policy.RequireAuthenticatedUser());
    options.AddPolicy(AuthPolicies.ArtistOrAdmin, policy =>
        policy.RequireRole(UserRole.Artist.ToString(), UserRole.Admin.ToString()));
    options.AddPolicy(AuthPolicies.DropCreator, policy =>
        policy.RequireRole(UserRole.Artist.ToString(), UserRole.DropMaker.ToString(), UserRole.Admin.ToString()));
    options.AddPolicy(AuthPolicies.ModerationAccess, policy =>
        policy.RequireRole(
            UserRole.Artist.ToString(),
            UserRole.DropMaker.ToString(),
            UserRole.Moderator.ToString(),
            UserRole.Admin.ToString()));
    options.AddPolicy(AuthPolicies.AdminOnly, policy => policy.RequireRole(UserRole.Admin.ToString()));
});
builder.Services.AddCors(options =>
{
    options.AddPolicy("FrontendDev", policy =>
    {
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
    });
});
builder.Services.AddUrbanArtInfrastructure(builder.Configuration, jwtOptions);

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("FrontendDev");
app.UseAuthentication();
app.UseAuthorization();

await SeedConfigurationAsync(app.Services);

var bootstrapGroup = app.MapGroup("/api/bootstrap");
bootstrapGroup.MapGet("/status", async (UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var adminExists = await dbContext.UserAccounts.AnyAsync(user => user.Role == UserRole.Admin, cancellationToken);
    return Results.Ok(new BootstrapStatusResponse(
        BootstrapRequired: !adminExists,
        AdminUserExists: adminExists,
        ModeratorBootstrapAvailable: adminExists));
});

bootstrapGroup.MapPost("/admin", async (
    BootstrapAdminRequest request,
    IPasswordHasher passwordHasher,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    if (await dbContext.UserAccounts.AnyAsync(user => user.Role == UserRole.Admin, cancellationToken))
    {
        return Results.Conflict(new { error = "Admin bootstrap is no longer available." });
    }

    if (await dbContext.UserAccounts.AnyAsync(
            user => user.Email == request.Email.Trim().ToLowerInvariant(),
            cancellationToken))
    {
        return Results.BadRequest(new { error = "Email already exists." });
    }

    if (await dbContext.UserAccounts.AnyAsync(
            user => user.UserName == request.UserName.Trim(),
            cancellationToken))
    {
        return Results.BadRequest(new { error = "User name already exists." });
    }

    var passwordValidation = PasswordPolicy.Validate(request.Password);
    if (!passwordValidation.IsValid)
    {
        return Results.BadRequest(new { error = passwordValidation.Error ?? "Invalid password." });
    }

    var passwordHash = passwordHasher.Hash(request.Password);
    var user = UserAccount.CreateLocal(
        request.Email,
        request.UserName,
        UserRole.Admin,
        passwordHash,
        approved: true);
    user.MarkEmailVerified();

    await dbContext.UserAccounts.AddAsync(user, cancellationToken);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Created($"/api/admin/users/{user.Id}", ToManagedUserResponse(user, includeEmail: true));
});

app.MapGet("/api/health", () => Results.Ok(new { status = "ok", utcNow = DateTimeOffset.UtcNow }))
    .WithName("Health");
app.MapGrpcService<HealthGrpcService>();

var mediaGroup = app.MapGroup("/api/media");
mediaGroup.MapGet("/art-piece-photos/{photoId:guid}", async (
    Guid photoId,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var photo = await dbContext.ArtPiecePhotos.AsNoTracking().FirstOrDefaultAsync(x => x.Id == photoId, cancellationToken);
    return photo is null
        ? Results.NotFound()
        : Results.File(photo.BinaryData, photo.ContentType, enableRangeProcessing: false);
});

mediaGroup.MapGet("/art-piece-assets/{assetId:guid}", async (
    Guid assetId,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var asset = await dbContext.ArtPieceAssetFiles.AsNoTracking().FirstOrDefaultAsync(x => x.Id == assetId, cancellationToken);
    return asset is null
        ? Results.NotFound()
        : Results.File(
            asset.BinaryData,
            asset.ContentType,
            fileDownloadName: asset.FileName,
            enableRangeProcessing: false);
});

mediaGroup.MapGet("/drop-location-photos/{photoId:guid}", async (
    Guid photoId,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var photo = await dbContext.DropLocationPhotos.AsNoTracking().FirstOrDefaultAsync(x => x.Id == photoId, cancellationToken);
    return photo is null
        ? Results.NotFound()
        : Results.File(photo.BinaryData, photo.ContentType, enableRangeProcessing: false);
});

mediaGroup.MapGet("/user-profile-images/{photoId:guid}", async (
    Guid photoId,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var photo = await dbContext.UserProfileImages.AsNoTracking().FirstOrDefaultAsync(x => x.Id == photoId, cancellationToken);
    return photo is null
        ? Results.NotFound()
        : Results.File(photo.BinaryData, photo.ContentType, enableRangeProcessing: false);
});

var authGroup = app.MapGroup("/api/auth");
var supportedExternalProviders = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
{
    "google",
    "facebook",
    "instagram",
    "tiktok",
    "microsoft"
};
authGroup.MapPost("/register-local", async (
    RegisterLocalRequest request,
    AuthApplicationService authService,
    CancellationToken cancellationToken) =>
{
    var result = await authService.RegisterLocalAsync(request, cancellationToken);
    return result.Success ? Results.Ok(result) : Results.BadRequest(result);
});

authGroup.MapGet("/providers", (ExternalProviderStatusService providerStatusService) =>
    Results.Ok(
        providerStatusService.GetProviderStatuses()
            .Where(status => status.VisibleOnLogin)
            .Select(status => new AvailableExternalAuthProviderResponse(status.Provider, status.DisplayName))
            .ToList()));

authGroup.MapPost("/provider-login/begin", (
    BeginExternalProviderLoginRequest request,
    HttpContext httpContext,
    ExternalProviderAuthFlowService externalProviderAuthFlowService) =>
{
    if (!supportedExternalProviders.Contains(request.Provider))
    {
        return Results.BadRequest(new AuthResult(false, "Unsupported provider for v1."));
    }

    try
    {
        var result = externalProviderAuthFlowService.BeginLogin(request, httpContext.Request);
        return Results.Ok(result);
    }
    catch (InvalidOperationException ex)
    {
        return Results.BadRequest(new AuthResult(false, ex.Message));
    }
});

authGroup.MapPost("/provider-register/begin", (
    BeginExternalProviderRegistrationRequest request,
    HttpContext httpContext,
    ExternalProviderAuthFlowService externalProviderAuthFlowService) =>
{
    if (!supportedExternalProviders.Contains(request.Provider))
    {
        return Results.BadRequest(new AuthResult(false, "Unsupported provider for v1."));
    }

    try
    {
        var result = externalProviderAuthFlowService.BeginRegistration(request, httpContext.Request);
        return Results.Ok(result);
    }
    catch (InvalidOperationException ex)
    {
        return Results.BadRequest(new AuthResult(false, ex.Message));
    }
});

authGroup.MapGet("/provider/callback", async (
    HttpContext httpContext,
    ExternalProviderAuthFlowService externalProviderAuthFlowService,
    CancellationToken cancellationToken) =>
{
    var callbackResult = await externalProviderAuthFlowService.HandleCallbackAsync(
        httpContext.Request,
        cancellationToken);
    if (!callbackResult.IsSuccess)
    {
        return Results.BadRequest(new { error = callbackResult.ErrorMessage });
    }

    return Results.Redirect(callbackResult.RedirectUrl!);
});

authGroup.MapPost("/provider/complete", (
    CompleteExternalProviderAuthRequest request,
    ExternalProviderAuthFlowService externalProviderAuthFlowService) =>
{
    var result = externalProviderAuthFlowService.ConsumeCompletedAuthResult(request.ProviderSessionId);
    if (result is null)
    {
        return Results.BadRequest(new AuthResult(false, "The external provider session is invalid or has expired."));
    }

    return result.Success ? Results.Ok(result) : Results.BadRequest(result);
});

authGroup.MapPost("/register-provider", async (
    RegisterProviderRequest request,
    AuthApplicationService authService,
    CancellationToken cancellationToken) =>
{
    if (!supportedExternalProviders.Contains(request.Provider))
    {
        return Results.BadRequest(new AuthResult(false, "Unsupported provider for v1."));
    }

    var result = await authService.RegisterProviderAsync(request, cancellationToken);
    return result.Success ? Results.Ok(result) : Results.BadRequest(result);
});

authGroup.MapPost("/login-local", async (
    LoginLocalRequest request,
    AuthApplicationService authService,
    CancellationToken cancellationToken) =>
{
    var result = await authService.LoginLocalAsync(request, cancellationToken);
    return result.Success ? Results.Ok(result) : Results.BadRequest(result);
});

authGroup.MapPost("/login-provider", async (
    LoginProviderRequest request,
    AuthApplicationService authService,
    CancellationToken cancellationToken) =>
{
    if (!supportedExternalProviders.Contains(request.Provider))
    {
        return Results.BadRequest(new AuthResult(false, "Unsupported provider for v1."));
    }

    var result = await authService.LoginProviderAsync(request, cancellationToken);
    return result.Success ? Results.Ok(result) : Results.BadRequest(result);
});

authGroup.MapPost("/mfa/complete", async (
    CompleteMfaChallengeRequest request,
    AuthApplicationService authService,
    CancellationToken cancellationToken) =>
{
    var result = await authService.CompleteMfaChallengeAsync(request, cancellationToken);
    return result.Success ? Results.Ok(result) : Results.BadRequest(result);
});

authGroup.MapPost("/verify-email/{userId:guid}", async (
    Guid userId,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var user = await dbContext.UserAccounts.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);
    if (user is null)
    {
        return Results.NotFound();
    }

    user.MarkEmailVerified();
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
});

var profileGroup = app.MapGroup("/api/profile");
profileGroup.MapGet("/", async (
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var actor = actorResolution.Actor!;
    var profileImage = await dbContext.UserProfileImages
        .AsNoTracking()
        .FirstOrDefaultAsync(image => image.UserAccountId == actor.Id, cancellationToken);

    return Results.Ok(ToCurrentUserProfileResponse(actor, profileImage, httpContext.Request));
}).RequireAuthorization(AuthPolicies.ApprovedAccount);

profileGroup.MapGet("/notifications", async (
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var notifications = await dbContext.UserNotifications
        .AsNoTracking()
        .Where(notification => notification.UserAccountId == actorResolution.Actor!.Id)
        .OrderByDescending(notification => notification.CreatedAtUtc)
        .Take(50)
        .ToListAsync(cancellationToken);

    return Results.Ok(notifications.Select(ToUserNotificationResponse).ToList());
}).RequireAuthorization(AuthPolicies.ApprovedAccount);

profileGroup.MapPut("/", async (
    UpdateCurrentUserProfileRequest request,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    IHttpClientFactory httpClientFactory,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var actor = actorResolution.Actor!;
    var user = await dbContext.UserAccounts.FirstOrDefaultAsync(account => account.Id == actor.Id, cancellationToken);
    if (user is null)
    {
        return Results.Unauthorized();
    }

    try
    {
        var normalizedEmail = request.Email.Trim().ToLowerInvariant();
        if (await dbContext.UserAccounts.AnyAsync(
                account => account.Id != user.Id && account.Email == normalizedEmail,
                cancellationToken))
        {
            return Results.BadRequest(new { error = "Email already exists." });
        }

        var normalizedUserName = request.UserName.Trim();
        if (await dbContext.UserAccounts.AnyAsync(
                account => account.Id != user.Id && account.UserName == normalizedUserName,
                cancellationToken))
        {
            return Results.BadRequest(new { error = "User name already exists." });
        }

        user.ChangeEmail(request.Email);
        user.ChangeUserName(request.UserName);
        await ReplaceUserProfileImageAsync(
            user.Id,
            request.ProfileImageSource,
            dbContext,
            httpClientFactory,
            cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        var profileImage = await dbContext.UserProfileImages
            .AsNoTracking()
            .FirstOrDefaultAsync(image => image.UserAccountId == user.Id, cancellationToken);
        return Results.Ok(ToCurrentUserProfileResponse(user, profileImage, httpContext.Request));
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
}).RequireAuthorization(AuthPolicies.ApprovedAccount);

profileGroup.MapPost("/role-application", async (
    ApplyForRoleRequest request,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    IClock clock,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var user = await dbContext.UserAccounts.FirstOrDefaultAsync(
        account => account.Id == actorResolution.Actor!.Id,
        cancellationToken);
    if (user is null)
    {
        return Results.Unauthorized();
    }

    try
    {
        user.ApplyForRole(request.Role, clock.UtcNow);
        await dbContext.SaveChangesAsync(cancellationToken);

        var profileImage = await dbContext.UserProfileImages
            .AsNoTracking()
            .FirstOrDefaultAsync(image => image.UserAccountId == user.Id, cancellationToken);
        return Results.Ok(ToCurrentUserProfileResponse(user, profileImage, httpContext.Request));
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
}).RequireAuthorization(AuthPolicies.ApprovedAccount);

profileGroup.MapPost("/notifications/{notificationId:guid}/mark-read", async (
    Guid notificationId,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var notification = await dbContext.UserNotifications
        .FirstOrDefaultAsync(
            entry => entry.Id == notificationId && entry.UserAccountId == actorResolution.Actor!.Id,
            cancellationToken);
    if (notification is null)
    {
        return Results.NotFound();
    }

    notification.MarkRead();
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok(ToUserNotificationResponse(notification));
}).RequireAuthorization(AuthPolicies.ApprovedAccount);

profileGroup.MapPost("/mfa/setup", async (
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    AuthApplicationService authService,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var result = authService.BeginCurrentUserMfaSetup(actorResolution.Actor!);
    return Results.Ok(result);
}).RequireAuthorization(AuthPolicies.ApprovedAccount);

profileGroup.MapPost("/mfa/disable", async (
    DisableCurrentUserMfaRequest request,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    AuthApplicationService authService,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var actor = actorResolution.Actor!;
    var result = await authService.DisableCurrentUserMfaAsync(actor.Id, request.Code, cancellationToken);
    if (!result.Success)
    {
        return Results.BadRequest(result);
    }

    var updatedUser = await dbContext.UserAccounts
        .AsNoTracking()
        .FirstOrDefaultAsync(account => account.Id == actor.Id, cancellationToken);
    if (updatedUser is null)
    {
        return Results.Unauthorized();
    }

    var profileImage = await dbContext.UserProfileImages
        .AsNoTracking()
        .FirstOrDefaultAsync(image => image.UserAccountId == updatedUser.Id, cancellationToken);
    return Results.Ok(ToCurrentUserProfileResponse(updatedUser, profileImage, httpContext.Request));
}).RequireAuthorization(AuthPolicies.ApprovedAccount);

var usersGroup = app.MapGroup("/api/users");
usersGroup.MapGet("/directory", async (UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var users = await dbContext.UserAccounts
        .AsNoTracking()
        .Where(user => user.IsApproved && !user.IsSuspended)
        .OrderBy(user => user.UserName)
        .ToListAsync(cancellationToken);

    return Results.Ok(users.Select(user => ToManagedUserResponse(user, includeEmail: false)).ToList());
});

var artGroup = app.MapGroup("/api/art-pieces");
artGroup.MapGet("/", async (HttpContext httpContext, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var artPieces = await dbContext.ArtPieces
        .Include(x => x.Photos)
        .Include(x => x.AssetFile)
        .AsNoTracking()
        .ToListAsync(cancellationToken);

    var response = artPieces
        .Select(artPiece => ToArtPieceResponse(artPiece, httpContext.Request))
        .ToList();
    return Results.Ok(response);
});

artGroup.MapGet("/manageable", async (
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var query = dbContext.ArtPieces
        .Include(x => x.Photos)
        .Include(x => x.AssetFile)
        .AsNoTracking()
        .AsQueryable();

    if (actorResolution.Actor!.Role == UserRole.Artist)
    {
        query = query.Where(artPiece => artPiece.ArtistId == actorResolution.Actor.Id);
    }

    var artPieces = await query.ToListAsync(cancellationToken);
    var response = artPieces
        .Select(artPiece => ToArtPieceResponse(artPiece, httpContext.Request))
        .ToList();
    return Results.Ok(response);
}).RequireAuthorization(AuthPolicies.ArtistOrAdmin);

artGroup.MapGet("/{id:guid}", async (Guid id, HttpContext httpContext, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var item = await dbContext.ArtPieces
        .Include(x => x.Photos)
        .Include(x => x.AssetFile)
        .AsNoTracking()
        .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    return item is null ? Results.NotFound() : Results.Ok(ToArtPieceResponse(item, httpContext.Request));
});

artGroup.MapPost("/", async (
    CreateArtPieceRequest request,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    IHttpClientFactory httpClientFactory,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    if (!CanCreateArtPiece(actorResolution.Actor!, request.ArtistId))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    try
    {
        var artPiece = ArtPiece.Create(
            request.ArtistId,
            request.Title,
            request.Subtitle,
            request.Description,
            request.AssetKind);
        var photoPayloads = await ResolvePhotoSourcesAsync(request.PhotoUrls, dbContext, httpClientFactory, cancellationToken);
        foreach (var photo in photoPayloads)
        {
            artPiece.AddPhoto(photo.BinaryData, photo.ContentType);
        }

        if (request.AssetKind == ArtPieceAssetKind.Model3d)
        {
            var assetPayload = await ResolveAssetSourceAsync(
                request.AssetSource,
                request.AssetFileName,
                dbContext,
                httpClientFactory,
                cancellationToken);
            artPiece.SetAssetFile(assetPayload.BinaryData, assetPayload.ContentType, assetPayload.FileName);
        }

        await dbContext.ArtPieces.AddAsync(artPiece, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        return Results.Created($"/api/art-pieces/{artPiece.Id}", ToArtPieceResponse(artPiece, httpContext.Request));
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
}).RequireAuthorization(AuthPolicies.ArtistOrAdmin);

artGroup.MapPut("/{id:guid}", async (
    Guid id,
    UpdateArtPieceRequest request,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    IHttpClientFactory httpClientFactory,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var artPiece = await dbContext.ArtPieces.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (artPiece is null)
    {
        return Results.NotFound();
    }

    if (!CanManageArtPiece(actorResolution.Actor!, artPiece, request.ArtistId))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    try
    {
        var originalArtistId = artPiece.ArtistId;
        artPiece.UpdateDetails(
            request.ArtistId,
            request.Title,
            request.Subtitle,
            request.Description,
            request.AssetKind);
        var photoPayloads = await ResolvePhotoSourcesAsync(request.PhotoUrls, dbContext, httpClientFactory, cancellationToken);
        var existingPhotos = await dbContext.ArtPiecePhotos
            .AsNoTracking()
            .Where(photo => photo.ArtPieceId == id)
            .ToListAsync(cancellationToken);
        if (existingPhotos.Count > 0)
        {
            dbContext.ArtPiecePhotos.RemoveRange(existingPhotos);
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        foreach (var photoPayload in photoPayloads)
        {
            await dbContext.ArtPiecePhotos.AddAsync(
                new ArtPiecePhoto
                {
                    ArtPieceId = artPiece.Id,
                    BinaryData = photoPayload.BinaryData,
                    ContentType = photoPayload.ContentType
                },
                cancellationToken);
        }

        var existingAssetFile = await dbContext.ArtPieceAssetFiles.FirstOrDefaultAsync(x => x.ArtPieceId == id, cancellationToken);
        if (request.AssetKind == ArtPieceAssetKind.Model3d)
        {
            if (!string.IsNullOrWhiteSpace(request.AssetSource))
            {
                var assetPayload = await ResolveAssetSourceAsync(
                    request.AssetSource,
                    request.AssetFileName,
                    dbContext,
                    httpClientFactory,
                    cancellationToken);
                if (existingAssetFile is null)
                {
                    await dbContext.ArtPieceAssetFiles.AddAsync(
                        new ArtPieceAssetFile
                        {
                            ArtPieceId = artPiece.Id,
                            BinaryData = assetPayload.BinaryData,
                            ContentType = assetPayload.ContentType,
                            FileName = assetPayload.FileName
                        },
                        cancellationToken);
                }
                else
                {
                    existingAssetFile.BinaryData = assetPayload.BinaryData;
                    existingAssetFile.ContentType = assetPayload.ContentType;
                    existingAssetFile.FileName = assetPayload.FileName;
                }
            }

            if (existingAssetFile is null && string.IsNullOrWhiteSpace(request.AssetSource))
            {
                throw new DomainValidationException("3D model asset is required.");
            }
        }
        else if (existingAssetFile is not null)
        {
            dbContext.ArtPieceAssetFiles.Remove(existingAssetFile);
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        await NotifyAdminArtPieceStakeholdersAsync(
            actorResolution.Actor!,
            dbContext,
            artPiece,
            "bearbeitet",
            cancellationToken,
            originalArtistId,
            request.ArtistId);
        var reloadedArtPiece = await dbContext.ArtPieces
            .Include(x => x.Photos)
            .Include(x => x.AssetFile)
            .AsNoTracking()
            .FirstAsync(x => x.Id == id, cancellationToken);
        return Results.Ok(ToArtPieceResponse(reloadedArtPiece, httpContext.Request));
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
}).RequireAuthorization(AuthPolicies.ArtistOrAdmin);

artGroup.MapPost("/{id:guid}/publish", async (Guid id, HttpContext httpContext, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var artPiece = await dbContext.ArtPieces
        .Include(x => x.Photos)
        .Include(x => x.AssetFile)
        .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (artPiece is null)
    {
        return Results.NotFound();
    }

    if (!CanManageArtPiece(actorResolution.Actor!, artPiece))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    try
    {
        artPiece.Publish();
        await dbContext.SaveChangesAsync(cancellationToken);
        await NotifyAdminArtPieceStakeholdersAsync(
            actorResolution.Actor!,
            dbContext,
            artPiece,
            "veroeffentlicht",
            cancellationToken);
        return Results.Ok();
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
}).RequireAuthorization(AuthPolicies.ApprovedAccount);

artGroup.MapPost("/{id:guid}/depublish", async (Guid id, HttpContext httpContext, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var artPiece = await dbContext.ArtPieces.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (artPiece is null)
    {
        return Results.NotFound();
    }

    if (!CanManageArtPiece(actorResolution.Actor!, artPiece))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    artPiece.Depublish();
    await dbContext.SaveChangesAsync(cancellationToken);
    await NotifyAdminArtPieceStakeholdersAsync(
        actorResolution.Actor!,
        dbContext,
        artPiece,
        "depubliziert",
        cancellationToken);
    return Results.Ok();
}).RequireAuthorization(AuthPolicies.ArtistOrAdmin);

artGroup.MapPost("/{id:guid}/report", async (
    Guid id,
    ReportArtPieceRequest request,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var artPiece = await dbContext.ArtPieces.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (artPiece is null)
    {
        return Results.NotFound();
    }

    artPiece.Report(request.Reason, DateTimeOffset.UtcNow);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok(new { mailAlertTriggered = true });
});

artGroup.MapDelete("/{id:guid}", async (Guid id, HttpContext httpContext, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var artPiece = await dbContext.ArtPieces.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (artPiece is null)
    {
        return Results.NotFound();
    }

    if (!CanManageArtPiece(actorResolution.Actor!, artPiece))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    dbContext.ArtPieces.Remove(artPiece);
    await dbContext.SaveChangesAsync(cancellationToken);
    await NotifyAdminArtPieceStakeholdersAsync(
        actorResolution.Actor!,
        dbContext,
        artPiece,
        "geloescht",
        cancellationToken);
    return Results.NoContent();
});

var dropsGroup = app.MapGroup("/api/drops");
dropsGroup.MapGet("/", async (HttpContext httpContext, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var drops = await dbContext.Drops
        .Include(x => x.Items)
        .Include(x => x.LocationPhotos)
        .Include(x => x.SocialChannels)
        .AsNoTracking()
        .ToListAsync(cancellationToken);
    var configuration = await GetConfigurationAsync(dbContext, cancellationToken);

    var response = drops
        .Select(drop => ToDropResponse(drop, httpContext.Request, configuration))
        .ToList();
    return Results.Ok(response);
});

dropsGroup.MapGet("/{id:guid}", async (Guid id, HttpContext httpContext, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var drop = await dbContext.Drops
        .Include(x => x.Items)
        .Include(x => x.LocationPhotos)
        .Include(x => x.SocialChannels)
        .AsNoTracking()
        .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    if (drop is null)
    {
        return Results.NotFound();
    }

    var configuration = await GetConfigurationAsync(dbContext, cancellationToken);
    return Results.Ok(ToDropResponse(drop, httpContext.Request, configuration));
});

dropsGroup.MapPost("/", async (
    CreateDropRequest request,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    IHttpClientFactory httpClientFactory,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    if (!await CanCreateDropAsync(actorResolution.Actor!, request, dbContext, cancellationToken))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    try
    {
        var drop = Drop.Create(
            request.ArtPieceId,
            request.DropMakerId,
            request.IsStationary,
            request.PortableItemCount,
            request.DropMakerComment,
            request.SocialChannels);

        if (request.Latitude.HasValue && request.Longitude.HasValue)
        {
            drop.SetLocation(request.Latitude.Value, request.Longitude.Value);
        }

        var locationPhotoPayloads = await ResolvePhotoSourcesAsync(
            request.LocationPhotoUrls,
            dbContext,
            httpClientFactory,
            cancellationToken);

        foreach (var photo in locationPhotoPayloads)
        {
            drop.AddLocationPhoto(photo.BinaryData, photo.ContentType);
        }

        for (var i = 0; i < request.ItemCount; i += 1)
        {
            drop.AddItem(Guid.NewGuid().ToString("N"));
        }

        await dbContext.Drops.AddAsync(drop, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        var configuration = await GetConfigurationAsync(dbContext, cancellationToken);
        return Results.Created($"/api/drops/{drop.Id}", ToDropResponse(drop, httpContext.Request, configuration));
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
}).RequireAuthorization(AuthPolicies.DropCreator);

dropsGroup.MapPut("/{id:guid}", async (
    Guid id,
    CreateDropRequest request,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    IHttpClientFactory httpClientFactory,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var drop = await dbContext.Drops.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    if (drop is null)
    {
        return Results.NotFound();
    }

    if (!await CanManageDropAsync(actorResolution.Actor!, drop, request.DropMakerId, dbContext, cancellationToken))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    try
    {
        var originalDropMakerId = drop.DropMakerId;
        drop.UpdateDetails(
            request.IsStationary,
            request.PortableItemCount,
            request.DropMakerComment,
            [],
            request.ItemCount);

        if (request.Latitude.HasValue && request.Longitude.HasValue)
        {
            drop.SetLocation(request.Latitude.Value, request.Longitude.Value);
        }
        else
        {
            drop.ClearLocation();
        }

        var locationPhotoPayloads = await ResolvePhotoSourcesAsync(
            request.LocationPhotoUrls,
            dbContext,
            httpClientFactory,
            cancellationToken);
        var existingLocationPhotos = await dbContext.DropLocationPhotos
            .Where(photo => photo.DropId == id)
            .ToListAsync(cancellationToken);
        if (existingLocationPhotos.Count > 0)
        {
            dbContext.DropLocationPhotos.RemoveRange(existingLocationPhotos);
        }

        foreach (var locationPhotoPayload in locationPhotoPayloads)
        {
            await dbContext.DropLocationPhotos.AddAsync(
                new DropLocationPhoto
                {
                    DropId = drop.Id,
                    BinaryData = locationPhotoPayload.BinaryData,
                    ContentType = locationPhotoPayload.ContentType
                },
                cancellationToken);
        }

        var normalizedSocialChannels = request.SocialChannels
            .Select(DropSocialChannelSelection.NormalizeChannel)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
        var existingSocialChannels = await dbContext.DropSocialChannelSelections
            .Where(selection => selection.DropId == id)
            .ToListAsync(cancellationToken);
        if (existingSocialChannels.Count > 0)
        {
            dbContext.DropSocialChannelSelections.RemoveRange(existingSocialChannels);
        }

        foreach (var channel in normalizedSocialChannels)
        {
            await dbContext.DropSocialChannelSelections.AddAsync(
                new DropSocialChannelSelection
                {
                    DropId = drop.Id,
                    Channel = channel
                },
                cancellationToken);
        }

        var currentItems = await dbContext.DropItems
            .Where(item => item.DropId == id)
            .ToListAsync(cancellationToken);
        var claimedItems = currentItems.Where(item => item.IsClaimed).ToList();
        if (request.ItemCount < 1)
        {
            throw new DomainValidationException("Drop requires at least one item.");
        }

        if (request.ItemCount < claimedItems.Count)
        {
            throw new DomainValidationException("Claimed drop items cannot be removed.");
        }

        var unclaimedItems = currentItems.Where(item => !item.IsClaimed).ToList();
        var targetUnclaimedItemCount = request.ItemCount - claimedItems.Count;
        if (unclaimedItems.Count > targetUnclaimedItemCount)
        {
            var removableItems = unclaimedItems.Skip(targetUnclaimedItemCount).ToList();
            dbContext.DropItems.RemoveRange(removableItems);
        }

        if (unclaimedItems.Count < targetUnclaimedItemCount)
        {
            var itemsToAdd = targetUnclaimedItemCount - unclaimedItems.Count;
            for (var i = 0; i < itemsToAdd; i += 1)
            {
                await dbContext.DropItems.AddAsync(
                    new DropItem
                    {
                        DropId = drop.Id,
                        QrToken = Guid.NewGuid().ToString("N")
                    },
                    cancellationToken);
            }
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        await NotifyAdminDropStakeholdersAsync(
            actorResolution.Actor!,
            dbContext,
            drop,
            "bearbeitet",
            cancellationToken,
            originalDropMakerId,
            request.DropMakerId);
        var configuration = await GetConfigurationAsync(dbContext, cancellationToken);
        var reloadedDrop = await dbContext.Drops
            .Include(x => x.Items)
            .Include(x => x.LocationPhotos)
            .Include(x => x.SocialChannels)
            .AsNoTracking()
            .FirstAsync(x => x.Id == id, cancellationToken);
        return Results.Ok(ToDropResponse(reloadedDrop, httpContext.Request, configuration));
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
}).RequireAuthorization(AuthPolicies.DropCreator);

dropsGroup.MapPost("/{id:guid}/publish", async (Guid id, HttpContext httpContext, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var drop = await dbContext.Drops
        .Include(x => x.Items)
        .Include(x => x.LocationPhotos)
        .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    if (drop is null)
    {
        return Results.NotFound();
    }

    if (!await CanManageDropAsync(actorResolution.Actor!, drop, drop.DropMakerId, dbContext, cancellationToken))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    try
    {
        drop.Publish();
        await dbContext.SaveChangesAsync(cancellationToken);
        await NotifyAdminDropStakeholdersAsync(
            actorResolution.Actor!,
            dbContext,
            drop,
            "veroeffentlicht",
            cancellationToken);
        return Results.Ok();
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
}).RequireAuthorization(AuthPolicies.DropCreator);

dropsGroup.MapPost("/{id:guid}/depublish", async (Guid id, HttpContext httpContext, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var drop = await dbContext.Drops.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (drop is null)
    {
        return Results.NotFound();
    }

    if (!await CanManageDropAsync(actorResolution.Actor!, drop, drop.DropMakerId, dbContext, cancellationToken))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    drop.Depublish();
    await dbContext.SaveChangesAsync(cancellationToken);
    await NotifyAdminDropStakeholdersAsync(
        actorResolution.Actor!,
        dbContext,
        drop,
        "depubliziert",
        cancellationToken);
    return Results.Ok();
}).RequireAuthorization(AuthPolicies.DropCreator);

dropsGroup.MapDelete("/{id:guid}", async (Guid id, HttpContext httpContext, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var drop = await dbContext.Drops
        .Include(x => x.Items)
        .Include(x => x.LocationPhotos)
        .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    if (drop is null)
    {
        return Results.NotFound();
    }

    if (!await CanManageDropAsync(actorResolution.Actor!, drop, drop.DropMakerId, dbContext, cancellationToken))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    dbContext.Drops.Remove(drop);
    await dbContext.SaveChangesAsync(cancellationToken);
    await NotifyAdminDropStakeholdersAsync(
        actorResolution.Actor!,
        dbContext,
        drop,
        "geloescht",
        cancellationToken);
    return Results.NoContent();
});

dropsGroup.MapPost("/{id:guid}/mark-all-claimed", async (
    Guid id,
    ClaimDropItemRequest request,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var drop = await dbContext.Drops.Include(x => x.Items).FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (drop is null)
    {
        return Results.NotFound();
    }

    if (!await CanManageDropAsync(actorResolution.Actor!, drop, drop.DropMakerId, dbContext, cancellationToken))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    try
    {
        drop.MarkAllClaimed(request.HunterUserId, request.AnonymousNickname, DateTimeOffset.UtcNow);
        await dbContext.SaveChangesAsync(cancellationToken);
        return Results.Ok();
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
});

dropsGroup.MapPost("/{dropId:guid}/items/{itemId:guid}/claim", async (
    Guid dropId,
    Guid itemId,
    ClaimDropItemRequest request,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    DropClaimApplicationService dropClaimService,
    CancellationToken cancellationToken) =>
{
    var drop = await dbContext.Drops
        .Include(x => x.Items)
        .FirstOrDefaultAsync(x => x.Id == dropId, cancellationToken);

    if (drop is null)
    {
        return Results.NotFound();
    }

    var item = drop.Items.FirstOrDefault(x => x.Id == itemId);
    if (item is null)
    {
        return Results.NotFound();
    }

    var claimActor = await ResolveClaimActorAsync(httpContext, dbContext, request.HunterUserId, cancellationToken);
    if (claimActor.Failure is not null)
    {
        return claimActor.Failure;
    }

    try
    {
        await dropClaimService.ClaimAsync(
            drop,
            item,
            claimActor.HunterUserId,
            claimActor.AnonymousNickname ?? request.AnonymousNickname,
            cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        return Results.Ok();
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
});

var claimsGroup = app.MapGroup("/api/claims");
claimsGroup.MapGet("/by-token/{qrToken}", async (
    string qrToken,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var normalizedToken = qrToken.Trim();
    var dropItem = await dbContext.DropItems
        .AsNoTracking()
        .FirstOrDefaultAsync(item => item.QrToken == normalizedToken, cancellationToken);
    if (dropItem is null)
    {
        return Results.NotFound();
    }

    var drop = await dbContext.Drops
        .AsNoTracking()
        .FirstOrDefaultAsync(entry => entry.Id == dropItem.DropId, cancellationToken);
    if (drop is null)
    {
        return Results.NotFound();
    }

    var artPiece = await dbContext.ArtPieces
        .AsNoTracking()
        .FirstOrDefaultAsync(entry => entry.Id == drop.ArtPieceId, cancellationToken);
    if (artPiece is null)
    {
        return Results.NotFound();
    }

    string? claimedByDisplayName = null;
    if (dropItem.ClaimedByUserId.HasValue)
    {
        var claimedByUser = await dbContext.UserAccounts
            .AsNoTracking()
            .FirstOrDefaultAsync(user => user.Id == dropItem.ClaimedByUserId.Value, cancellationToken);
        claimedByDisplayName = claimedByUser?.UserName;
    }

    claimedByDisplayName ??= dropItem.ClaimedByAnonymousNickname;
    return Results.Ok(ToClaimPreviewResponse(drop, dropItem, artPiece, claimedByDisplayName));
});

claimsGroup.MapPost("/by-token", async (
    ClaimDropItemByTokenRequest request,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    DropClaimApplicationService dropClaimService,
    CancellationToken cancellationToken) =>
{
    var normalizedToken = request.QrToken.Trim();
    var dropItem = await dbContext.DropItems
        .FirstOrDefaultAsync(item => item.QrToken == normalizedToken, cancellationToken);
    if (dropItem is null)
    {
        return Results.NotFound();
    }

    var drop = await dbContext.Drops
        .Include(entry => entry.Items)
        .FirstOrDefaultAsync(entry => entry.Id == dropItem.DropId, cancellationToken);
    if (drop is null)
    {
        return Results.NotFound();
    }

    var claimActor = await ResolveClaimActorAsync(httpContext, dbContext, request.HunterUserId, cancellationToken);
    if (claimActor.Failure is not null)
    {
        return claimActor.Failure;
    }

    try
    {
        await dropClaimService.ClaimAsync(
            drop,
            dropItem,
            claimActor.HunterUserId,
            claimActor.AnonymousNickname ?? request.AnonymousNickname,
            cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        return Results.Ok();
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
});

var commentsGroup = app.MapGroup("/api/comments");
commentsGroup.MapGet("/drop/{dropId:guid}", async (Guid dropId, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var comments = await dbContext.DropComments
        .AsNoTracking()
        .Where(x => x.DropId == dropId && !x.IsHidden)
        .OrderByDescending(x => x.CreatedAtUtc)
        .ToListAsync(cancellationToken);
    var authorIds = comments
        .Where(comment => comment.AuthorUserId.HasValue)
        .Select(comment => comment.AuthorUserId!.Value)
        .Distinct()
        .ToList();
    var usersById = await dbContext.UserAccounts
        .AsNoTracking()
        .Where(user => authorIds.Contains(user.Id))
        .ToDictionaryAsync(user => user.Id, cancellationToken);

    return Results.Ok(comments.Select(comment => ToCommentResponse(comment, usersById)).ToList());
});

commentsGroup.MapPost("/", async (CreateCommentRequest request, HttpContext httpContext, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    if (string.IsNullOrWhiteSpace(request.Content))
    {
        return Results.BadRequest(new { error = "Comment content is required." });
    }

    if (!CanCreateComment(actorResolution.Actor!))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    var comment = new DropComment
    {
        DropId = request.DropId,
        AuthorUserId = actorResolution.Actor!.Id,
        AnonymousNickname = null,
        Content = request.Content.Trim(),
        CreatedAtUtc = DateTimeOffset.UtcNow
    };

    await dbContext.DropComments.AddAsync(comment, cancellationToken);
    await dbContext.SaveChangesAsync(cancellationToken);
    var usersById = comment.AuthorUserId.HasValue
        ? await dbContext.UserAccounts
            .AsNoTracking()
            .Where(user => user.Id == comment.AuthorUserId.Value)
            .ToDictionaryAsync(user => user.Id, cancellationToken)
        : new Dictionary<Guid, UserAccount>();

    return Results.Created($"/api/comments/{comment.Id}", ToCommentResponse(comment, usersById));
}).RequireAuthorization(AuthPolicies.ApprovedAccount);

commentsGroup.MapPost("/{id:guid}/report", async (
    Guid id,
    ReportCommentRequest request,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var comment = await dbContext.DropComments.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (comment is null)
    {
        return Results.NotFound();
    }

    comment.Report(request.Reason, DateTimeOffset.UtcNow);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok(new { mailAlertTriggered = true });
}).RequireAuthorization(AuthPolicies.ApprovedAccount);

commentsGroup.MapPost("/{id:guid}/hide", async (
    Guid id,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveModerationActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var comment = await dbContext.DropComments.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (comment is null)
    {
        return Results.NotFound();
    }

    if (!await CanModerateCommentAsync(actorResolution.Actor!, comment.DropId, dbContext, cancellationToken))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    comment.Hide(DateTimeOffset.UtcNow);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
}).RequireAuthorization(AuthPolicies.ModerationAccess);

commentsGroup.MapPost("/{id:guid}/dismiss-report", async (
    Guid id,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveModerationActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var comment = await dbContext.DropComments.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (comment is null)
    {
        return Results.NotFound();
    }

    if (!await CanModerateCommentAsync(actorResolution.Actor!, comment.DropId, dbContext, cancellationToken))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    comment.DismissReport();
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
}).RequireAuthorization(AuthPolicies.ModerationAccess);

var moderationGroup = app.MapGroup("/api/moderation");
moderationGroup.MapGet("/reports", async (
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveModerationActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var actor = actorResolution.Actor!;
    if (!CanAccessModerationQueue(actor))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    IQueryable<DropComment> reportedCommentsQuery = dbContext.DropComments
        .AsNoTracking()
        .Where(comment => comment.IsReported);
    if (actor.Role == UserRole.Artist)
    {
        reportedCommentsQuery =
            from comment in dbContext.DropComments.AsNoTracking()
            join drop in dbContext.Drops.AsNoTracking() on comment.DropId equals drop.Id
            join artPiece in dbContext.ArtPieces.AsNoTracking() on drop.ArtPieceId equals artPiece.Id
            where comment.IsReported && artPiece.ArtistId == actor.Id
            select comment;
    }
    else if (actor.Role == UserRole.DropMaker)
    {
        reportedCommentsQuery =
            from comment in dbContext.DropComments.AsNoTracking()
            join drop in dbContext.Drops.AsNoTracking() on comment.DropId equals drop.Id
            where comment.IsReported && drop.DropMakerId == actor.Id
            select comment;
    }

    var reportedComments = await reportedCommentsQuery
        .OrderByDescending(comment => comment.ReportedAtUtc ?? comment.CreatedAtUtc)
        .ToListAsync(cancellationToken);
    var reportedArtPieces = CanModerateArtPieceReports(actor)
        ? await dbContext.ArtPieces
            .Include(artPiece => artPiece.Photos)
            .AsNoTracking()
            .Where(artPiece => artPiece.IsReported)
            .OrderByDescending(artPiece => artPiece.ReportedAtUtc)
            .ToListAsync(cancellationToken)
        : [];

    var commentAuthorIds = reportedComments
        .Where(comment => comment.AuthorUserId.HasValue)
        .Select(comment => comment.AuthorUserId!.Value);
    var artistIds = reportedArtPieces.Select(artPiece => artPiece.ArtistId);
    var userIds = commentAuthorIds
        .Concat(artistIds)
        .Distinct()
        .ToList();
    var usersById = await dbContext.UserAccounts
        .AsNoTracking()
        .Where(user => userIds.Contains(user.Id))
        .ToDictionaryAsync(user => user.Id, cancellationToken);

    var reportedCommentDropIds = reportedComments
        .Select(comment => comment.DropId)
        .Distinct()
        .ToList();
    var dropsById = await dbContext.Drops
        .AsNoTracking()
        .Where(drop => reportedCommentDropIds.Contains(drop.Id))
        .ToDictionaryAsync(drop => drop.Id, cancellationToken);

    var dropArtPieceIds = dropsById.Values.Select(drop => drop.ArtPieceId);
    var requiredArtPieceIds = reportedArtPieces
        .Select(artPiece => artPiece.Id)
        .Concat(dropArtPieceIds)
        .Distinct()
        .ToList();
    var artPiecesById = await dbContext.ArtPieces
        .Include(artPiece => artPiece.Photos)
        .AsNoTracking()
        .Where(artPiece => requiredArtPieceIds.Contains(artPiece.Id))
        .ToDictionaryAsync(artPiece => artPiece.Id, cancellationToken);

    var baseUri = $"{httpContext.Request.Scheme}://{httpContext.Request.Host}";
    var commentResponses = reportedComments
        .Select(comment =>
        {
            string dropTitle;
            if (dropsById.TryGetValue(comment.DropId, out var drop) &&
                artPiecesById.TryGetValue(drop.ArtPieceId, out var artPieceForDrop))
            {
                dropTitle = artPieceForDrop.Title;
            }
            else
            {
                dropTitle = comment.DropId.ToString();
            }

            return new ReportedCommentResponse(
                comment.Id,
                comment.DropId,
                dropTitle,
                comment.AuthorUserId,
                ResolveCommentAuthorDisplayName(comment, usersById),
                comment.Content,
                comment.ReportReason,
                comment.CreatedAtUtc,
                comment.ReportedAtUtc);
        })
        .ToList();
    var artPieceResponses = reportedArtPieces
        .Select(artPiece =>
        {
            string? previewImageUrl = artPiece.Photos
                .Select(photo => $"{baseUri}/api/media/art-piece-photos/{photo.Id}")
                .FirstOrDefault();

            return new ReportedArtPieceResponse(
                artPiece.Id,
                artPiece.ArtistId,
                artPiece.Title,
                usersById.TryGetValue(artPiece.ArtistId, out var artist)
                    ? artist.UserName
                    : artPiece.ArtistId.ToString(),
                artPiece.IsPublished,
                artPiece.ReportReason,
                artPiece.ReportedAtUtc,
                previewImageUrl);
        })
        .ToList();

    return Results.Ok(new ModerationQueueResponse(commentResponses, artPieceResponses));
}).RequireAuthorization(AuthPolicies.ModerationAccess);

moderationGroup.MapPost("/comments/{id:guid}/hide", async (
    Guid id,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveModerationActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var comment = await dbContext.DropComments.FirstOrDefaultAsync(entry => entry.Id == id, cancellationToken);
    if (comment is null)
    {
        return Results.NotFound();
    }

    if (!await CanModerateCommentAsync(actorResolution.Actor!, comment.DropId, dbContext, cancellationToken))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    comment.Hide(DateTimeOffset.UtcNow);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
}).RequireAuthorization(AuthPolicies.ModerationAccess);

moderationGroup.MapPost("/comments/{id:guid}/dismiss-report", async (
    Guid id,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveModerationActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    var comment = await dbContext.DropComments.FirstOrDefaultAsync(entry => entry.Id == id, cancellationToken);
    if (comment is null)
    {
        return Results.NotFound();
    }

    if (!await CanModerateCommentAsync(actorResolution.Actor!, comment.DropId, dbContext, cancellationToken))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    comment.DismissReport();
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
}).RequireAuthorization(AuthPolicies.ModerationAccess);

moderationGroup.MapPost("/art-pieces/{id:guid}/depublish", async (
    Guid id,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveModerationActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    if (!CanModerateArtPieceReports(actorResolution.Actor!))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    var artPiece = await dbContext.ArtPieces.FirstOrDefaultAsync(entry => entry.Id == id, cancellationToken);
    if (artPiece is null)
    {
        return Results.NotFound();
    }

    artPiece.Depublish();
    artPiece.DismissReport();
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
}).RequireAuthorization(AuthPolicies.ModerationAccess);

moderationGroup.MapPost("/art-pieces/{id:guid}/dismiss-report", async (
    Guid id,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var actorResolution = await ResolveModerationActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution.Failure;
    }

    if (!CanModerateArtPieceReports(actorResolution.Actor!))
    {
        return Results.StatusCode(StatusCodes.Status403Forbidden);
    }

    var artPiece = await dbContext.ArtPieces.FirstOrDefaultAsync(entry => entry.Id == id, cancellationToken);
    if (artPiece is null)
    {
        return Results.NotFound();
    }

    artPiece.DismissReport();
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
}).RequireAuthorization(AuthPolicies.ModerationAccess);

var discoveryGroup = app.MapGroup("/api/discovery");
discoveryGroup.MapGet("/drops", async (
    UrbanArtDbContext dbContext,
    string? search,
    string? sortBy,
    double? latitude,
    double? longitude,
    CancellationToken cancellationToken) =>
{
    var configuration = await GetConfigurationAsync(dbContext, cancellationToken);

    var query = dbContext.Drops
        .Include(x => x.Items)
        .Include(x => x.LocationPhotos)
        .AsNoTracking()
        .Where(x => x.IsPublished);

    var drops = await query.ToListAsync(cancellationToken);

    var projected = drops.Select(drop =>
    {
        var allClaimed = drop.Items.Count > 0 && drop.Items.All(item => item.IsClaimed);
        var shouldShowExact = allClaimed && configuration.ShowExactPositionWhenFullyClaimed;

        double? shownLat = null;
        double? shownLng = null;

        if (drop.Latitude.HasValue && drop.Longitude.HasValue)
        {
            if (shouldShowExact)
            {
                shownLat = drop.Latitude;
                shownLng = drop.Longitude;
            }
            else
            {
                shownLat = Math.Round(drop.Latitude.Value, 1);
                shownLng = Math.Round(drop.Longitude.Value, 1);
            }
        }

        var distanceKm = latitude.HasValue && longitude.HasValue && shownLat.HasValue && shownLng.HasValue
            ? HaversineDistanceKm(latitude.Value, longitude.Value, shownLat.Value, shownLng.Value)
            : (double?)null;

        return new DiscoveryDropDto(
            drop.Id,
            drop.ArtPieceId,
            drop.IsStationary,
            drop.PortableItemCount,
            allClaimed,
            shownLat,
            shownLng,
            distanceKm,
            configuration.MainMapRadiusKm,
            configuration.MiniMapRadiusKm,
            configuration.UnclaimedDropRadiusKm);
    });

    if (!string.IsNullOrWhiteSpace(search))
    {
        projected = projected.Where(x => x.DropId.ToString().Contains(search, StringComparison.OrdinalIgnoreCase));
    }

    var ordered = string.Equals(sortBy, "distance", StringComparison.OrdinalIgnoreCase)
        ? projected.OrderBy(x => x.DistanceKm ?? double.MaxValue)
        : projected.OrderBy(x => x.DropId);

    return Results.Ok(ordered.ToList());
});

discoveryGroup.MapGet("/leaderboard", async (UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var leaderboard = await dbContext.DropItems
        .AsNoTracking()
        .Where(x => x.IsClaimed)
        .GroupBy(x => x.ClaimedByUserId.HasValue ? x.ClaimedByUserId.Value.ToString() : $"anon:{x.ClaimedByAnonymousNickname}")
        .Select(group => new
        {
            hunter = group.Key,
            claims = group.Count()
        })
        .OrderByDescending(x => x.claims)
        .ThenBy(x => x.hunter)
        .ToListAsync(cancellationToken);

    return Results.Ok(leaderboard);
});

var adminGroup = app.MapGroup("/api/admin");
adminGroup.MapGet("/configuration", async (
    UrbanArtDbContext dbContext,
    ExternalProviderStatusService providerStatusService,
    CancellationToken cancellationToken) =>
    Results.Ok(
        ToAppConfigurationResponse(
            await GetConfigurationAsync(dbContext, cancellationToken),
            providerStatusService.GetProviderStatuses())))
    .RequireAuthorization(AuthPolicies.AdminOnly);

adminGroup.MapPut("/configuration", async (
    UpdateAppConfigurationRequest request,
    UrbanArtDbContext dbContext,
    ExternalProviderStatusService providerStatusService,
    CancellationToken cancellationToken) =>
{
    var config = await GetConfigurationAsync(dbContext, cancellationToken);
    config.SmtpHost = request.SmtpHost;
    config.PublicAppBaseUrl = NormalizeOptionalBaseUrl(request.PublicAppBaseUrl);
    config.MainMapRadiusKm = request.MainMapRadiusKm;
    config.MiniMapRadiusKm = request.MiniMapRadiusKm;
    config.UnclaimedDropRadiusKm = request.UnclaimedDropRadiusKm;
    config.ShowExactPositionWhenFullyClaimed = request.ShowExactPositionWhenFullyClaimed;

    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok(ToAppConfigurationResponse(config, providerStatusService.GetProviderStatuses()));
}).RequireAuthorization(AuthPolicies.AdminOnly);

adminGroup.MapGet("/users", async (UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var users = await dbContext.UserAccounts
        .AsNoTracking()
        .OrderBy(user => user.UserName)
        .ToListAsync(cancellationToken);
    return Results.Ok(users.Select(user => ToManagedUserResponse(user, includeEmail: true)).ToList());
})
    .RequireAuthorization(AuthPolicies.AdminOnly);

adminGroup.MapPost("/users", async (
    CreateManagedUserRequest request,
    IPasswordHasher passwordHasher,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    if (await dbContext.UserAccounts.AnyAsync(user => user.Email == request.Email.Trim().ToLowerInvariant(), cancellationToken))
    {
        return Results.BadRequest(new { error = "Email already exists." });
    }

    if (await dbContext.UserAccounts.AnyAsync(user => user.UserName == request.UserName.Trim(), cancellationToken))
    {
        return Results.BadRequest(new { error = "User name already exists." });
    }

    if (request.IsProviderAccount)
    {
        if (string.IsNullOrWhiteSpace(request.Provider) || string.IsNullOrWhiteSpace(request.ProviderSubject))
        {
            return Results.BadRequest(new { error = "Provider and provider subject are required for provider accounts." });
        }

        var provider = request.Provider.Trim();
        var providerSubject = request.ProviderSubject.Trim();
        var providerExists = await dbContext.UserProviderLinks.AnyAsync(
            link => link.Provider == provider && link.ProviderSubject == providerSubject,
            cancellationToken);
        if (providerExists)
        {
            return Results.BadRequest(new { error = "Provider subject is already linked." });
        }

        var providerUser = UserAccount.CreateProvider(request.Email, request.UserName, request.Role, provider, request.IsApproved);
        if (request.IsEmailVerified)
        {
            providerUser.MarkEmailVerified();
        }

        providerUser.SetApproval(request.IsApproved);
        providerUser.SetSuspended(false);
        await dbContext.UserAccounts.AddAsync(providerUser, cancellationToken);
        await dbContext.UserProviderLinks.AddAsync(
            new UserProviderLink
            {
                UserAccountId = providerUser.Id,
                Provider = provider,
                ProviderSubject = providerSubject
            },
            cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        return Results.Ok(new AuthResult(true, "Managed user created.", providerUser.Id, providerUser.Role, providerUser.UserName, providerUser.Email));
    }

    if (string.IsNullOrWhiteSpace(request.Password))
    {
        return Results.BadRequest(new { error = "Password is required for local accounts." });
    }

    var passwordValidation = PasswordPolicy.Validate(request.Password);
    if (!passwordValidation.IsValid)
    {
        return Results.BadRequest(new { error = passwordValidation.Error ?? "Invalid password." });
    }

    var passwordHash = passwordHasher.Hash(request.Password);
    var user = UserAccount.CreateLocal(request.Email, request.UserName, request.Role, passwordHash, request.IsApproved);
    if (request.IsEmailVerified)
    {
        user.MarkEmailVerified();
    }

    user.SetApproval(request.IsApproved);
    user.SetSuspended(false);
    await dbContext.UserAccounts.AddAsync(user, cancellationToken);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok(new AuthResult(true, "Managed user created.", user.Id, user.Role, user.UserName, user.Email));
}).RequireAuthorization(AuthPolicies.AdminOnly);

adminGroup.MapPatch("/users/{userId:guid}/approval", async (Guid userId, bool approved, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var user = await dbContext.UserAccounts.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);
    if (user is null)
    {
        return Results.NotFound();
    }

    user.SetApproval(approved);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
}).RequireAuthorization(AuthPolicies.AdminOnly);

adminGroup.MapPatch("/users/{userId:guid}/suspension", async (Guid userId, bool suspended, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var user = await dbContext.UserAccounts.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);
    if (user is null)
    {
        return Results.NotFound();
    }

    user.SetSuspended(suspended);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
}).RequireAuthorization(AuthPolicies.AdminOnly);

adminGroup.MapPatch("/users/{userId:guid}/role", async (Guid userId, UserRole role, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var user = await dbContext.UserAccounts.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);
    if (user is null)
    {
        return Results.NotFound();
    }

    user.ChangeRole(role);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
}).RequireAuthorization(AuthPolicies.AdminOnly);

adminGroup.MapPost("/users/{userId:guid}/role-application/approve", async (
    Guid userId,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var user = await dbContext.UserAccounts.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);
    if (user is null)
    {
        return Results.NotFound();
    }

    try
    {
        user.ApproveRoleApplication();
        await dbContext.SaveChangesAsync(cancellationToken);
        return Results.Ok(ToManagedUserResponse(user, includeEmail: true));
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
}).RequireAuthorization(AuthPolicies.AdminOnly);

adminGroup.MapPost("/users/{userId:guid}/role-application/reject", async (
    Guid userId,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var user = await dbContext.UserAccounts.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);
    if (user is null)
    {
        return Results.NotFound();
    }

    try
    {
        user.RejectRoleApplication();
        await dbContext.SaveChangesAsync(cancellationToken);
        return Results.Ok(ToManagedUserResponse(user, includeEmail: true));
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
}).RequireAuthorization(AuthPolicies.AdminOnly);

adminGroup.MapPatch("/users/{userId:guid}/profile", async (
    Guid userId,
    UpdateManagedUserProfileRequest request,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var user = await dbContext.UserAccounts.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);
    if (user is null)
    {
        return Results.NotFound();
    }

    var normalizedEmail = request.Email.Trim().ToLowerInvariant();
    if (await dbContext.UserAccounts.AnyAsync(
            account => account.Id != userId && account.Email == normalizedEmail,
            cancellationToken))
    {
        return Results.BadRequest(new { error = "Email already exists." });
    }

    var normalizedUserName = request.UserName.Trim();
    if (await dbContext.UserAccounts.AnyAsync(
            account => account.Id != userId && account.UserName == normalizedUserName,
            cancellationToken))
    {
        return Results.BadRequest(new { error = "User name already exists." });
    }

    user.ChangeEmail(request.Email);
    user.ChangeUserName(request.UserName);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
}).RequireAuthorization(AuthPolicies.AdminOnly);

app.Run();

static async Task SeedConfigurationAsync(IServiceProvider services)
{
    using var scope = services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<UrbanArtDbContext>();

    if (dbContext.Database.IsRelational())
    {
        await dbContext.Database.MigrateAsync();
    }
    else
    {
        await dbContext.Database.EnsureCreatedAsync();
    }

    if (!await dbContext.AppConfigurations.AnyAsync())
    {
        dbContext.AppConfigurations.Add(new AppConfiguration());
        await dbContext.SaveChangesAsync();
    }
}

static async Task<AppConfiguration> GetConfigurationAsync(UrbanArtDbContext dbContext, CancellationToken cancellationToken)
{
    var config = await dbContext.AppConfigurations.FirstOrDefaultAsync(cancellationToken);
    if (config is not null)
    {
        return config;
    }

    config = new AppConfiguration();
    await dbContext.AppConfigurations.AddAsync(config, cancellationToken);
    await dbContext.SaveChangesAsync(cancellationToken);
    return config;
}

static AppConfigurationResponse ToAppConfigurationResponse(
    AppConfiguration configuration,
    IReadOnlyCollection<ExternalProviderStatusSnapshot> providerStatuses) =>
    new(
        configuration.SmtpHost,
        configuration.PublicAppBaseUrl,
        configuration.MainMapRadiusKm,
        configuration.MiniMapRadiusKm,
        configuration.UnclaimedDropRadiusKm,
        configuration.ShowExactPositionWhenFullyClaimed,
        providerStatuses
            .Select(ToExternalProviderConfigurationStatusResponse)
            .ToList());

static ExternalProviderConfigurationStatusResponse ToExternalProviderConfigurationStatusResponse(
    ExternalProviderStatusSnapshot providerStatus) =>
    new(
        providerStatus.Provider,
        providerStatus.DisplayName,
        providerStatus.Enabled,
        providerStatus.VisibleOnLogin,
        providerStatus.HasClientId,
        providerStatus.HasClientSecret,
        providerStatus.UsesPkce);

static string? NormalizeOptionalBaseUrl(string? value)
{
    var normalized = value?.Trim();
    if (string.IsNullOrWhiteSpace(normalized))
    {
        return null;
    }

    return normalized.TrimEnd('/');
}

static async Task<(UserAccount? Actor, IResult? Failure)> ResolveAuthenticatedActorAsync(
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken)
{
    if (!TryGetAuthenticatedUserId(httpContext.User, out var actorUserId))
    {
        return (null, Results.Unauthorized());
    }

    var actor = await dbContext.UserAccounts
        .AsNoTracking()
        .FirstOrDefaultAsync(user => user.Id == actorUserId, cancellationToken);
    if (actor is null)
    {
        return (null, Results.Unauthorized());
    }

    if (!actor.IsApproved || actor.IsSuspended)
    {
        return (null, Results.StatusCode(StatusCodes.Status403Forbidden));
    }

    return (actor, null);
}

static async Task<(Guid? HunterUserId, string? AnonymousNickname, IResult? Failure)> ResolveClaimActorAsync(
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    Guid? requestedHunterUserId,
    CancellationToken cancellationToken)
{
    if (TryGetAuthenticatedUserId(httpContext.User, out var authenticatedUserId))
    {
        if (requestedHunterUserId.HasValue && requestedHunterUserId.Value != authenticatedUserId)
        {
            return (null, null, Results.BadRequest(new { error = "Authenticated claim user does not match requested hunter user." }));
        }

        var actor = await dbContext.UserAccounts
            .AsNoTracking()
            .FirstOrDefaultAsync(user => user.Id == authenticatedUserId, cancellationToken);
        if (actor is null)
        {
            return (null, null, Results.Unauthorized());
        }

        if (!actor.IsApproved || actor.IsSuspended)
        {
            return (null, null, Results.StatusCode(StatusCodes.Status403Forbidden));
        }

        return (actor.Id, null, null);
    }

    if (requestedHunterUserId.HasValue)
    {
        return (null, null, Results.BadRequest(new { error = "Anonymous claims cannot impersonate a registered hunter." }));
    }

    return (null, null, null);
}

static async Task<(UserAccount? Actor, IResult? Failure)> ResolveModerationActorAsync(
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken)
{
    var actorResolution = await ResolveAuthenticatedActorAsync(httpContext, dbContext, cancellationToken);
    if (actorResolution.Failure is not null)
    {
        return actorResolution;
    }

    var actor = actorResolution.Actor!;
    if (!CanAccessModerationQueue(actor))
    {
        return (null, Results.StatusCode(StatusCodes.Status403Forbidden));
    }

    return (actor, null);
}

static bool TryGetAuthenticatedUserId(ClaimsPrincipal principal, out Guid userId)
{
    userId = Guid.Empty;
    var rawUserId = principal.FindFirstValue(ClaimTypes.NameIdentifier);
    return !string.IsNullOrWhiteSpace(rawUserId) && Guid.TryParse(rawUserId, out userId);
}

static bool CanCreateArtPiece(UserAccount actor, Guid artistId)
    => actor.Role == UserRole.Admin || (actor.Role == UserRole.Artist && actor.Id == artistId);

static bool CanManageArtPiece(UserAccount actor, ArtPiece artPiece, Guid? requestedArtistId = null)
{
    if (actor.Role == UserRole.Admin)
    {
        return true;
    }

    if (actor.Role != UserRole.Artist)
    {
        return false;
    }

    if (artPiece.ArtistId != actor.Id)
    {
        return false;
    }

    return !requestedArtistId.HasValue || requestedArtistId.Value == actor.Id;
}

static async Task<bool> CanCreateDropAsync(
    UserAccount actor,
    CreateDropRequest request,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken)
{
    if (actor.Role == UserRole.Admin)
    {
        return true;
    }

    if (actor.Role == UserRole.DropMaker)
    {
        return actor.Id == request.DropMakerId;
    }

    if (actor.Role != UserRole.Artist)
    {
        return false;
    }

    if (request.DropMakerId != actor.Id)
    {
        return false;
    }

    return await dbContext.ArtPieces
        .AsNoTracking()
        .AnyAsync(artPiece => artPiece.Id == request.ArtPieceId && artPiece.ArtistId == actor.Id, cancellationToken);
}

static async Task<bool> CanManageDropAsync(
    UserAccount actor,
    Drop drop,
    Guid requestedDropMakerId,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken)
{
    if (actor.Role == UserRole.Admin)
    {
        return true;
    }

    if (requestedDropMakerId != drop.DropMakerId)
    {
        return false;
    }

    if (actor.Role == UserRole.DropMaker)
    {
        return drop.DropMakerId == actor.Id;
    }

    if (actor.Role == UserRole.Artist)
    {
        if (drop.DropMakerId == actor.Id)
        {
            return true;
        }

        return await dbContext.ArtPieces
            .AsNoTracking()
            .AnyAsync(artPiece => artPiece.Id == drop.ArtPieceId && artPiece.ArtistId == actor.Id, cancellationToken);
    }

    return false;
}

static bool CanAccessModerationQueue(UserAccount actor)
    => actor.Role is UserRole.Artist or UserRole.DropMaker or UserRole.Moderator or UserRole.Admin;

static bool CanModerateArtPieceReports(UserAccount actor)
    => actor.Role is UserRole.Moderator or UserRole.Admin;

static bool CanCreateComment(UserAccount actor)
    => actor.Role is UserRole.Hunter or UserRole.Artist or UserRole.DropMaker or UserRole.Moderator or UserRole.Admin;

static async Task<bool> CanModerateCommentAsync(
    UserAccount actor,
    Guid dropId,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken)
{
    if (actor.Role is UserRole.Moderator or UserRole.Admin)
    {
        return true;
    }

    if (actor.Role == UserRole.DropMaker)
    {
        return await dbContext.Drops
            .AsNoTracking()
            .AnyAsync(drop => drop.Id == dropId && drop.DropMakerId == actor.Id, cancellationToken);
    }

    if (actor.Role != UserRole.Artist)
    {
        return false;
    }

    return await dbContext.Drops
        .AsNoTracking()
        .Where(drop => drop.Id == dropId)
        .Join(
            dbContext.ArtPieces.AsNoTracking(),
            drop => drop.ArtPieceId,
            artPiece => artPiece.Id,
            (_, artPiece) => artPiece.ArtistId)
        .AnyAsync(artistId => artistId == actor.Id, cancellationToken);
}

static ArtPieceResponseDto ToArtPieceResponse(ArtPiece artPiece, HttpRequest request)
{
    var baseUri = $"{request.Scheme}://{request.Host}";
    var photos = artPiece.Photos
        .Select(photo => new PhotoReferenceDto(photo.Id, $"{baseUri}/api/media/art-piece-photos/{photo.Id}"))
        .ToList();
    BinaryAssetReferenceDto? assetFile = null;
    if (artPiece.AssetFile is not null)
    {
        assetFile = new BinaryAssetReferenceDto(
            artPiece.AssetFile.Id,
            $"{baseUri}/api/media/art-piece-assets/{artPiece.AssetFile.Id}",
            artPiece.AssetFile.FileName,
            artPiece.AssetFile.ContentType,
            artPiece.AssetFile.BinaryData.LongLength);
    }

    return new ArtPieceResponseDto(
        artPiece.Id,
        artPiece.ArtistId,
        artPiece.Title,
        artPiece.Subtitle,
        artPiece.Description,
        artPiece.AssetKind,
        artPiece.IsPublished,
        artPiece.IsReported,
        artPiece.ReportReason,
        artPiece.ReportedAtUtc,
        photos,
        assetFile);
}

static CommentResponse ToCommentResponse(DropComment comment, IReadOnlyDictionary<Guid, UserAccount> usersById)
    => new(
        comment.Id,
        comment.DropId,
        comment.AuthorUserId,
        ResolveCommentAuthorDisplayName(comment, usersById),
        comment.AnonymousNickname,
        comment.Content,
        comment.IsReported,
        comment.IsHidden,
        comment.ReportReason,
        comment.CreatedAtUtc,
        comment.ReportedAtUtc);

static string ResolveCommentAuthorDisplayName(DropComment comment, IReadOnlyDictionary<Guid, UserAccount> usersById)
{
    if (comment.AuthorUserId.HasValue &&
        usersById.TryGetValue(comment.AuthorUserId.Value, out var user))
    {
        return user.UserName;
    }

    var nickname = comment.AnonymousNickname?.Trim();
    return string.IsNullOrWhiteSpace(nickname) ? "-" : nickname;
}

static UserNotificationResponse ToUserNotificationResponse(UserNotification notification)
    => new(
        notification.Id,
        notification.Title,
        notification.Message,
        notification.Category,
        notification.IsRead,
        notification.CreatedAtUtc,
        notification.RelatedEntityId,
        notification.RelatedEntityType);

static DropResponseDto ToDropResponse(Drop drop, HttpRequest request, AppConfiguration? configuration = null)
{
    var apiBaseUri = $"{request.Scheme}://{request.Host}";
    var appBaseUri = ResolvePublicAppBaseUrl(configuration, request);
    var locationPhotos = drop.LocationPhotos
        .Select(photo => new PhotoReferenceDto(photo.Id, $"{apiBaseUri}/api/media/drop-location-photos/{photo.Id}"))
        .ToList();
    var socialChannels = drop.SocialChannels
        .Select(channel => channel.Channel)
        .OrderBy(channel => channel, StringComparer.OrdinalIgnoreCase)
        .ToList();
    var items = drop.Items
        .Select(item => new DropItemResponseDto(
            item.Id,
            item.QrToken,
            BuildClaimUrl(appBaseUri, item.QrToken),
            item.IsClaimed,
            item.ClaimedByUserId,
            item.ClaimedByAnonymousNickname,
            item.ClaimedAtUtc))
        .ToList();

    return new DropResponseDto(
        drop.Id,
        drop.ArtPieceId,
        drop.DropMakerId,
        drop.IsStationary,
        drop.PortableItemCount,
        drop.DropMakerComment,
        socialChannels,
        drop.Latitude,
        drop.Longitude,
        drop.IsPublished,
        locationPhotos,
        items);
}

static ClaimPreviewResponseDto ToClaimPreviewResponse(
    Drop drop,
    DropItem dropItem,
    ArtPiece artPiece,
    string? claimedByDisplayName)
    => new(
        drop.Id,
        dropItem.Id,
        drop.ArtPieceId,
        artPiece.Title,
        dropItem.IsClaimed,
        claimedByDisplayName);

static string ResolvePublicAppBaseUrl(AppConfiguration? configuration, HttpRequest request)
    => NormalizeOptionalBaseUrl(configuration?.PublicAppBaseUrl) ?? $"{request.Scheme}://{request.Host}";

static string BuildClaimUrl(string appBaseUri, string qrToken)
    => $"{appBaseUri}/hunter/claim?token={Uri.EscapeDataString(qrToken)}";

static ManagedUserResponseDto ToManagedUserResponse(UserAccount user, bool includeEmail)
    => new(
        user.Id,
        includeEmail ? user.Email : string.Empty,
        user.UserName,
        user.Role,
        user.PendingRoleApplication,
        user.PendingRoleApplicationRequestedAtUtc,
        user.IsApproved,
        user.IsSuspended,
        user.IsEmailVerified,
        user.IsProviderAccount);

static CurrentUserProfileResponse ToCurrentUserProfileResponse(
    UserAccount user,
    UserProfileImage? profileImage,
    HttpRequest request)
{
    var baseUri = $"{request.Scheme}://{request.Host}";
    var profileImageReference = profileImage is null
        ? null
        : new ProfileImageReferenceResponse(
            profileImage.Id,
            $"{baseUri}/api/media/user-profile-images/{profileImage.Id}");

    return new CurrentUserProfileResponse(
        user.Id,
        user.Email,
        user.UserName,
        user.Role,
        user.PendingRoleApplication,
        user.PendingRoleApplicationRequestedAtUtc,
        user.IsProviderAccount,
        user.IsMfaEnabled,
        IsMfaRequiredByPolicy(user),
        profileImageReference);
}

static bool IsMfaRequiredByPolicy(UserAccount user)
    => user.Role is UserRole.Admin or UserRole.Moderator;

static async Task NotifyAdminArtPieceStakeholdersAsync(
    UserAccount actor,
    UrbanArtDbContext dbContext,
    ArtPiece artPiece,
    string action,
    CancellationToken cancellationToken,
    Guid? previousArtistId = null,
    Guid? requestedArtistId = null)
{
    if (actor.Role != UserRole.Admin)
    {
        return;
    }

    var recipientIds = new HashSet<Guid> { artPiece.ArtistId };
    if (previousArtistId.HasValue)
    {
        recipientIds.Add(previousArtistId.Value);
    }

    if (requestedArtistId.HasValue)
    {
        recipientIds.Add(requestedArtistId.Value);
    }

    await QueueUserNotificationsAsync(
        dbContext,
        recipientIds,
        actor.Id,
        $"Admin hat Kunstwerk {action}",
        $"Administrator {actor.UserName} hat das Kunstwerk \"{artPiece.Title}\" {action}.",
        "admin-art-piece",
        artPiece.Id,
        nameof(ArtPiece),
        cancellationToken);
}

static async Task NotifyAdminDropStakeholdersAsync(
    UserAccount actor,
    UrbanArtDbContext dbContext,
    Drop drop,
    string action,
    CancellationToken cancellationToken,
    Guid? previousDropMakerId = null,
    Guid? requestedDropMakerId = null)
{
    if (actor.Role != UserRole.Admin)
    {
        return;
    }

    var recipientIds = new HashSet<Guid> { drop.DropMakerId };
    if (previousDropMakerId.HasValue)
    {
        recipientIds.Add(previousDropMakerId.Value);
    }

    if (requestedDropMakerId.HasValue)
    {
        recipientIds.Add(requestedDropMakerId.Value);
    }

    var artPieceTitle = await dbContext.ArtPieces
        .AsNoTracking()
        .Where(artPiece => artPiece.Id == drop.ArtPieceId)
        .Select(artPiece => artPiece.Title)
        .FirstOrDefaultAsync(cancellationToken)
        ?? drop.ArtPieceId.ToString();

    await QueueUserNotificationsAsync(
        dbContext,
        recipientIds,
        actor.Id,
        $"Admin hat Drop {action}",
        $"Administrator {actor.UserName} hat den Drop zu \"{artPieceTitle}\" {action}.",
        "admin-drop",
        drop.Id,
        nameof(Drop),
        cancellationToken);
}

static async Task QueueUserNotificationsAsync(
    UrbanArtDbContext dbContext,
    IEnumerable<Guid> recipientIds,
    Guid actorUserId,
    string title,
    string message,
    string category,
    Guid relatedEntityId,
    string relatedEntityType,
    CancellationToken cancellationToken)
{
    var normalizedRecipients = recipientIds
        .Where(recipientId => recipientId != Guid.Empty && recipientId != actorUserId)
        .Distinct()
        .ToList();
    if (normalizedRecipients.Count == 0)
    {
        return;
    }

    var existingRecipientIds = await dbContext.UserAccounts
        .AsNoTracking()
        .Where(user => normalizedRecipients.Contains(user.Id))
        .Select(user => user.Id)
        .ToListAsync(cancellationToken);
    if (existingRecipientIds.Count == 0)
    {
        return;
    }

    foreach (var recipientId in existingRecipientIds)
    {
        await dbContext.UserNotifications.AddAsync(
            UserNotification.Create(
                recipientId,
                title,
                message,
                category,
                relatedEntityId,
                relatedEntityType),
            cancellationToken);
    }

    await dbContext.SaveChangesAsync(cancellationToken);
}

static async Task<IReadOnlyList<ResolvedPhotoPayload>> ResolvePhotoSourcesAsync(
    IEnumerable<string>? photoSources,
    UrbanArtDbContext dbContext,
    IHttpClientFactory httpClientFactory,
    CancellationToken cancellationToken)
{
    var resolvedPayloads = new List<ResolvedPhotoPayload>();
    foreach (var source in photoSources ?? [])
    {
        var payload = await ResolvePhotoSourceAsync(source, dbContext, httpClientFactory, cancellationToken);
        resolvedPayloads.Add(payload);
    }

    return resolvedPayloads;
}

static async Task<ResolvedPhotoPayload> ResolvePhotoSourceAsync(
    string source,
    UrbanArtDbContext dbContext,
    IHttpClientFactory httpClientFactory,
    CancellationToken cancellationToken)
{
    var normalizedSource = source?.Trim() ?? string.Empty;
    if (string.IsNullOrWhiteSpace(normalizedSource))
    {
        throw new DomainValidationException("Photo source is required.");
    }

    if (TryParseDataUrl(normalizedSource, out var dataUrlPayload))
    {
        ValidateBinaryPhotoPayload(dataUrlPayload.BinaryData);
        return dataUrlPayload;
    }

    if (TryParseMediaPhotoReference(normalizedSource, out var mediaKind, out var mediaPhotoId))
    {
        return await ReadStoredPhotoPayloadAsync(mediaKind, mediaPhotoId, dbContext, cancellationToken);
    }

    if (!Uri.TryCreate(normalizedSource, UriKind.Absolute, out var photoUri) ||
        (photoUri.Scheme != Uri.UriSchemeHttp && photoUri.Scheme != Uri.UriSchemeHttps))
    {
        throw new DomainValidationException("Photo source must be an http(s) URL, data URL or existing media URL.");
    }

    var client = httpClientFactory.CreateClient("photo-fetcher");
    using var request = new HttpRequestMessage(HttpMethod.Get, photoUri);
    request.Headers.Accept.Add(new MediaTypeWithQualityHeaderValue("image/*"));

    using var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
    if (!response.IsSuccessStatusCode)
    {
        throw new DomainValidationException($"Photo could not be loaded from '{normalizedSource}'.");
    }

    var binaryData = await response.Content.ReadAsByteArrayAsync(cancellationToken);
    ValidateBinaryPhotoPayload(binaryData);

    var contentType = response.Content.Headers.ContentType?.MediaType;
    if (string.IsNullOrWhiteSpace(contentType))
    {
        contentType = "application/octet-stream";
    }

    return new ResolvedPhotoPayload(binaryData, contentType);
}

static async Task<ResolvedAssetPayload> ResolveAssetSourceAsync(
    string? assetSource,
    string? assetFileName,
    UrbanArtDbContext dbContext,
    IHttpClientFactory httpClientFactory,
    CancellationToken cancellationToken)
{
    var normalizedSource = assetSource?.Trim() ?? string.Empty;
    if (string.IsNullOrWhiteSpace(normalizedSource))
    {
        throw new DomainValidationException("Asset source is required.");
    }

    if (TryParseDataUrl(normalizedSource, out var dataUrlPayload))
    {
        ValidateBinaryAssetPayload(dataUrlPayload.BinaryData);
        var inlineFileName = NormalizeAssetFileName(assetFileName, "art-piece-asset.bin");
        return new ResolvedAssetPayload(dataUrlPayload.BinaryData, dataUrlPayload.ContentType, inlineFileName);
    }

    if (TryParseArtPieceAssetReference(normalizedSource, out var assetId))
    {
        return await ReadStoredArtPieceAssetPayloadAsync(assetId, assetFileName, dbContext, cancellationToken);
    }

    if (!Uri.TryCreate(normalizedSource, UriKind.Absolute, out var assetUri) ||
        (assetUri.Scheme != Uri.UriSchemeHttp && assetUri.Scheme != Uri.UriSchemeHttps))
    {
        throw new DomainValidationException("Asset source must be an http(s) URL, data URL or existing media URL.");
    }

    var client = httpClientFactory.CreateClient("photo-fetcher");
    using var request = new HttpRequestMessage(HttpMethod.Get, assetUri);

    using var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
    if (!response.IsSuccessStatusCode)
    {
        throw new DomainValidationException($"Asset could not be loaded from '{normalizedSource}'.");
    }

    var binaryData = await response.Content.ReadAsByteArrayAsync(cancellationToken);
    ValidateBinaryAssetPayload(binaryData);

    var contentType = response.Content.Headers.ContentType?.MediaType;
    if (string.IsNullOrWhiteSpace(contentType))
    {
        contentType = "application/octet-stream";
    }

    var resolvedFileName = NormalizeAssetFileName(
        assetFileName,
        GetFileNameFromUri(assetUri) ?? "art-piece-asset.bin");
    return new ResolvedAssetPayload(binaryData, contentType, resolvedFileName);
}

static async Task<ResolvedPhotoPayload> ReadStoredPhotoPayloadAsync(
    MediaPhotoKind mediaKind,
    Guid photoId,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken)
{
    if (mediaKind == MediaPhotoKind.ArtPiece)
    {
        var artPiecePhoto = await dbContext.ArtPiecePhotos.AsNoTracking().FirstOrDefaultAsync(x => x.Id == photoId, cancellationToken);
        if (artPiecePhoto is null)
        {
            throw new DomainValidationException("Referenced art piece photo does not exist.");
        }

        ValidateBinaryPhotoPayload(artPiecePhoto.BinaryData);
        return new ResolvedPhotoPayload(artPiecePhoto.BinaryData, artPiecePhoto.ContentType);
    }

    if (mediaKind == MediaPhotoKind.UserProfile)
    {
        var userProfileImage = await dbContext.UserProfileImages.AsNoTracking().FirstOrDefaultAsync(x => x.Id == photoId, cancellationToken);
        if (userProfileImage is null)
        {
            throw new DomainValidationException("Referenced profile image does not exist.");
        }

        ValidateBinaryPhotoPayload(userProfileImage.BinaryData);
        return new ResolvedPhotoPayload(userProfileImage.BinaryData, userProfileImage.ContentType);
    }

    var dropLocationPhoto = await dbContext.DropLocationPhotos.AsNoTracking().FirstOrDefaultAsync(x => x.Id == photoId, cancellationToken);
    if (dropLocationPhoto is null)
    {
        throw new DomainValidationException("Referenced drop location photo does not exist.");
    }

    ValidateBinaryPhotoPayload(dropLocationPhoto.BinaryData);
    return new ResolvedPhotoPayload(dropLocationPhoto.BinaryData, dropLocationPhoto.ContentType);
}

static async Task<ResolvedAssetPayload> ReadStoredArtPieceAssetPayloadAsync(
    Guid assetId,
    string? requestedFileName,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken)
{
    var assetFile = await dbContext.ArtPieceAssetFiles.AsNoTracking().FirstOrDefaultAsync(x => x.Id == assetId, cancellationToken);
    if (assetFile is null)
    {
        throw new DomainValidationException("Referenced art piece asset does not exist.");
    }

    ValidateBinaryAssetPayload(assetFile.BinaryData);
    return new ResolvedAssetPayload(
        assetFile.BinaryData,
        assetFile.ContentType,
        NormalizeAssetFileName(requestedFileName, assetFile.FileName));
}

static bool TryParseMediaPhotoReference(string source, out MediaPhotoKind mediaKind, out Guid photoId)
{
    mediaKind = MediaPhotoKind.ArtPiece;
    photoId = Guid.Empty;

    var path = source;
    if (Uri.TryCreate(source, UriKind.Absolute, out var absoluteUri))
    {
        path = absoluteUri.AbsolutePath;
    }

    if (!path.StartsWith("/", StringComparison.Ordinal))
    {
        path = "/" + path;
    }

    var segments = path.Split('/', StringSplitOptions.RemoveEmptyEntries);
    if (segments.Length != 4 ||
        !segments[0].Equals("api", StringComparison.OrdinalIgnoreCase) ||
        !segments[1].Equals("media", StringComparison.OrdinalIgnoreCase) ||
        !Guid.TryParse(segments[3], out photoId))
    {
        return false;
    }

    if (segments[2].Equals("art-piece-photos", StringComparison.OrdinalIgnoreCase))
    {
        mediaKind = MediaPhotoKind.ArtPiece;
        return true;
    }

    if (segments[2].Equals("drop-location-photos", StringComparison.OrdinalIgnoreCase))
    {
        mediaKind = MediaPhotoKind.DropLocation;
        return true;
    }

    if (segments[2].Equals("user-profile-images", StringComparison.OrdinalIgnoreCase))
    {
        mediaKind = MediaPhotoKind.UserProfile;
        return true;
    }

    return false;
}

static async Task ReplaceUserProfileImageAsync(
    Guid userId,
    string? profileImageSource,
    UrbanArtDbContext dbContext,
    IHttpClientFactory httpClientFactory,
    CancellationToken cancellationToken)
{
    if (profileImageSource is null)
    {
        return;
    }

    var existingImage = await dbContext.UserProfileImages
        .FirstOrDefaultAsync(image => image.UserAccountId == userId, cancellationToken);
    if (string.IsNullOrWhiteSpace(profileImageSource))
    {
        if (existingImage is not null)
        {
            dbContext.UserProfileImages.Remove(existingImage);
        }

        return;
    }

    var payload = await ResolvePhotoSourceAsync(
        profileImageSource,
        dbContext,
        httpClientFactory,
        cancellationToken);
    if (existingImage is null)
    {
        await dbContext.UserProfileImages.AddAsync(
            new UserProfileImage
            {
                UserAccountId = userId,
                BinaryData = payload.BinaryData,
                ContentType = payload.ContentType
            },
            cancellationToken);
        return;
    }

    existingImage.BinaryData = payload.BinaryData;
    existingImage.ContentType = payload.ContentType;
}

static bool TryParseArtPieceAssetReference(string source, out Guid assetId)
{
    assetId = Guid.Empty;

    var path = source;
    if (Uri.TryCreate(source, UriKind.Absolute, out var absoluteUri))
    {
        path = absoluteUri.AbsolutePath;
    }

    if (!path.StartsWith("/", StringComparison.Ordinal))
    {
        path = "/" + path;
    }

    var segments = path.Split('/', StringSplitOptions.RemoveEmptyEntries);
    return segments.Length == 4 &&
           segments[0].Equals("api", StringComparison.OrdinalIgnoreCase) &&
           segments[1].Equals("media", StringComparison.OrdinalIgnoreCase) &&
           segments[2].Equals("art-piece-assets", StringComparison.OrdinalIgnoreCase) &&
           Guid.TryParse(segments[3], out assetId);
}

static bool TryParseDataUrl(string source, out ResolvedPhotoPayload payload)
{
    payload = default;
    if (!source.StartsWith("data:", StringComparison.OrdinalIgnoreCase))
    {
        return false;
    }

    var separatorIndex = source.IndexOf(',');
    if (separatorIndex < 0)
    {
        throw new DomainValidationException("Photo data URL is invalid.");
    }

    var metadata = source["data:".Length..separatorIndex];
    var encodedPayload = source[(separatorIndex + 1)..];
    var metadataParts = metadata.Split(';', StringSplitOptions.RemoveEmptyEntries);
    var isBase64 = metadataParts.Any(part => part.Equals("base64", StringComparison.OrdinalIgnoreCase));
    if (!isBase64)
    {
        throw new DomainValidationException("Photo data URL must use base64 encoding.");
    }

    var contentType = metadataParts.FirstOrDefault(part => !part.Equals("base64", StringComparison.OrdinalIgnoreCase));
    if (string.IsNullOrWhiteSpace(contentType))
    {
        contentType = "application/octet-stream";
    }

    byte[] binaryData;
    try
    {
        binaryData = Convert.FromBase64String(encodedPayload);
    }
    catch (FormatException)
    {
        throw new DomainValidationException("Photo data URL payload is not valid base64.");
    }

    payload = new ResolvedPhotoPayload(binaryData, contentType);
    return true;
}

static void ValidateBinaryPhotoPayload(byte[]? binaryData)
{
    const int MaxPhotoSizeBytes = 10 * 1024 * 1024;
    if (binaryData is null || binaryData.Length == 0)
    {
        throw new DomainValidationException("Photo binary data is required.");
    }

    if (binaryData.Length > MaxPhotoSizeBytes)
    {
        throw new DomainValidationException("Photo exceeds max size of 10 MB.");
    }
}

static void ValidateBinaryAssetPayload(byte[]? binaryData)
{
    const int MaxAssetSizeBytes = 50 * 1024 * 1024;
    if (binaryData is null || binaryData.Length == 0)
    {
        throw new DomainValidationException("Asset binary data is required.");
    }

    if (binaryData.Length > MaxAssetSizeBytes)
    {
        throw new DomainValidationException("Asset exceeds max size of 50 MB.");
    }
}

static string NormalizeAssetFileName(string? requestedFileName, string fallback)
{
    var candidate = requestedFileName?.Trim();
    if (!string.IsNullOrWhiteSpace(candidate))
    {
        return candidate;
    }

    return fallback;
}

static string? GetFileNameFromUri(Uri uri)
{
    if (uri.Segments.Length == 0)
    {
        return null;
    }

    var lastSegment = uri.Segments[^1].Trim('/');
    return string.IsNullOrWhiteSpace(lastSegment) ? null : lastSegment;
}

static double HaversineDistanceKm(double lat1, double lon1, double lat2, double lon2)
{
    const double EarthRadiusKm = 6371;

    var dLat = DegreesToRadians(lat2 - lat1);
    var dLon = DegreesToRadians(lon2 - lon1);

    var a =
        Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
        Math.Cos(DegreesToRadians(lat1)) *
        Math.Cos(DegreesToRadians(lat2)) *
        Math.Sin(dLon / 2) *
        Math.Sin(dLon / 2);

    var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
    return EarthRadiusKm * c;
}

static double DegreesToRadians(double value) => value * Math.PI / 180;

internal sealed record DiscoveryDropDto(
    Guid DropId,
    Guid ArtPieceId,
    bool IsStationary,
    int? PortableItemCount,
    bool AllItemsClaimed,
    double? DisplayLatitude,
    double? DisplayLongitude,
    double? DistanceKm,
    int MainMapRadiusKm,
    int MiniMapRadiusKm,
    int UnclaimedDropRadiusKm);

internal sealed record PhotoReferenceDto(Guid Id, string Url);
internal sealed record BinaryAssetReferenceDto(Guid Id, string Url, string FileName, string ContentType, long SizeBytes);

internal sealed record ArtPieceResponseDto(
    Guid Id,
    Guid ArtistId,
    string Title,
    string Subtitle,
    string Description,
    ArtPieceAssetKind AssetKind,
    bool IsPublished,
    bool IsReported,
    string? ReportReason,
    DateTimeOffset? ReportedAtUtc,
    IReadOnlyCollection<PhotoReferenceDto> Photos,
    BinaryAssetReferenceDto? AssetFile);

internal sealed record DropItemResponseDto(
    Guid Id,
    string QrToken,
    string ClaimUrl,
    bool IsClaimed,
    Guid? ClaimedByUserId,
    string? ClaimedByAnonymousNickname,
    DateTimeOffset? ClaimedAtUtc);

internal sealed record DropResponseDto(
    Guid Id,
    Guid ArtPieceId,
    Guid DropMakerId,
    bool IsStationary,
    int? PortableItemCount,
    string? DropMakerComment,
    IReadOnlyCollection<string> SocialChannels,
    double? Latitude,
    double? Longitude,
    bool IsPublished,
    IReadOnlyCollection<PhotoReferenceDto> LocationPhotos,
    IReadOnlyCollection<DropItemResponseDto> Items);

internal sealed record ClaimPreviewResponseDto(
    Guid DropId,
    Guid DropItemId,
    Guid ArtPieceId,
    string ArtPieceTitle,
    bool IsClaimed,
    string? ClaimedByDisplayName);

internal sealed record ManagedUserResponseDto(
    Guid Id,
    string Email,
    string UserName,
    UserRole Role,
    UserRole? PendingRoleApplication,
    DateTimeOffset? PendingRoleApplicationRequestedAtUtc,
    bool IsApproved,
    bool IsSuspended,
    bool IsEmailVerified,
    bool IsProviderAccount);

internal readonly record struct ResolvedPhotoPayload(byte[] BinaryData, string ContentType);
internal readonly record struct ResolvedAssetPayload(byte[] BinaryData, string ContentType, string FileName);

internal enum MediaPhotoKind
{
    ArtPiece = 0,
    DropLocation = 1,
    UserProfile = 2
}

internal sealed record CreateManagedUserRequest(
    string Email,
    string UserName,
    UserRole Role,
    bool IsApproved,
    bool IsEmailVerified,
    bool IsProviderAccount,
    string? Password,
    string? Provider,
    string? ProviderSubject);

internal sealed record UpdateManagedUserProfileRequest(string UserName, string Email);

internal static class AuthPolicies
{
    public const string ApprovedAccount = "ApprovedAccount";
    public const string ArtistOrAdmin = "ArtistOrAdmin";
    public const string DropCreator = "DropCreator";
    public const string ModerationAccess = "ModerationAccess";
    public const string AdminOnly = "AdminOnly";
}

public partial class Program
{
}
