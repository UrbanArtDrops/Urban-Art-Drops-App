using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using UrbanArtDropFinder.Application.Auth;
using UrbanArtDropFinder.Application.Drops;
using UrbanArtDropFinder.Contracts.Admin;
using UrbanArtDropFinder.Contracts.Art;
using UrbanArtDropFinder.Contracts.Auth;
using UrbanArtDropFinder.Contracts.Comments;
using UrbanArtDropFinder.Contracts.Drops;
using UrbanArtDropFinder.Domain.Art;
using UrbanArtDropFinder.Domain.Comments;
using UrbanArtDropFinder.Domain.Configuration;
using UrbanArtDropFinder.Domain.Drops;
using UrbanArtDropFinder.Domain.Shared;
using UrbanArtDropFinder.Domain.Users;
using UrbanArtDropFinder.Api.Services;
using UrbanArtDropFinder.Infrastructure.DependencyInjection;
using UrbanArtDropFinder.Persistence.Db;

var builder = WebApplication.CreateBuilder(args);
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
builder.Services.AddUrbanArtInfrastructure(builder.Configuration);

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

await SeedConfigurationAsync(app.Services);

app.MapGet("/api/health", () => Results.Ok(new { status = "ok", utcNow = DateTimeOffset.UtcNow }))
    .WithName("Health");
app.MapGrpcService<HealthGrpcService>();

var authGroup = app.MapGroup("/api/auth");
authGroup.MapPost("/register-local", async (
    RegisterLocalRequest request,
    AuthApplicationService authService,
    CancellationToken cancellationToken) =>
{
    var result = await authService.RegisterLocalAsync(request, cancellationToken);
    return result.Success ? Results.Ok(result) : Results.BadRequest(result);
});

authGroup.MapPost("/register-provider", async (
    RegisterProviderRequest request,
    AuthApplicationService authService,
    CancellationToken cancellationToken) =>
{
    var allowedProviders = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
    {
        "google",
        "facebook",
        "instagram",
        "tiktok"
    };

    if (!allowedProviders.Contains(request.Provider))
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

var artGroup = app.MapGroup("/api/art-pieces");
artGroup.MapGet("/", async (UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
    Results.Ok(await dbContext.ArtPieces
        .Include(x => x.Photos)
        .AsNoTracking()
        .ToListAsync(cancellationToken)));

artGroup.MapGet("/{id:guid}", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var item = await dbContext.ArtPieces
        .Include(x => x.Photos)
        .AsNoTracking()
        .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    return item is null ? Results.NotFound() : Results.Ok(item);
});

artGroup.MapPost("/", async (CreateArtPieceRequest request, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    try
    {
        var artPiece = ArtPiece.Create(request.ArtistId, request.Title, request.Description, request.AssetKind);
        foreach (var photo in request.PhotoUrls)
        {
            artPiece.AddPhoto(photo);
        }

        await dbContext.ArtPieces.AddAsync(artPiece, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        return Results.Created($"/api/art-pieces/{artPiece.Id}", artPiece);
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
});

artGroup.MapPut("/{id:guid}", async (Guid id, UpdateArtPieceRequest request, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var artPiece = await dbContext.ArtPieces.Include(x => x.Photos).FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (artPiece is null)
    {
        return Results.NotFound();
    }

    try
    {
        artPiece.UpdateDetails(request.Title, request.Description);
        artPiece.ReplacePhotos(request.PhotoUrls);
        await dbContext.SaveChangesAsync(cancellationToken);
        return Results.Ok(artPiece);
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
});

artGroup.MapPost("/{id:guid}/publish", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var artPiece = await dbContext.ArtPieces.Include(x => x.Photos).FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (artPiece is null)
    {
        return Results.NotFound();
    }

    try
    {
        artPiece.Publish();
        await dbContext.SaveChangesAsync(cancellationToken);
        return Results.Ok();
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
});

artGroup.MapPost("/{id:guid}/depublish", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var artPiece = await dbContext.ArtPieces.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (artPiece is null)
    {
        return Results.NotFound();
    }

    artPiece.Depublish();
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
});

artGroup.MapDelete("/{id:guid}", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var artPiece = await dbContext.ArtPieces.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (artPiece is null)
    {
        return Results.NotFound();
    }

    dbContext.ArtPieces.Remove(artPiece);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.NoContent();
});

var dropsGroup = app.MapGroup("/api/drops");
dropsGroup.MapGet("/", async (UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
    Results.Ok(await dbContext.Drops
        .Include(x => x.Items)
        .Include(x => x.LocationPhotos)
        .AsNoTracking()
        .ToListAsync(cancellationToken)));

dropsGroup.MapGet("/{id:guid}", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var drop = await dbContext.Drops
        .Include(x => x.Items)
        .Include(x => x.LocationPhotos)
        .AsNoTracking()
        .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    return drop is null ? Results.NotFound() : Results.Ok(drop);
});

dropsGroup.MapPost("/", async (
    CreateDropRequest request,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    try
    {
        var drop = Drop.Create(request.ArtPieceId, request.DropMakerId, request.IsStationary, request.PortableItemCount);

        if (request.Latitude.HasValue && request.Longitude.HasValue)
        {
            drop.SetLocation(request.Latitude.Value, request.Longitude.Value);
        }

        foreach (var photo in request.LocationPhotoUrls)
        {
            drop.AddLocationPhoto(photo);
        }

        for (var i = 0; i < request.ItemCount; i += 1)
        {
            drop.AddItem(Guid.NewGuid().ToString("N"));
        }

        await dbContext.Drops.AddAsync(drop, cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);

        return Results.Created($"/api/drops/{drop.Id}", drop);
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
});

dropsGroup.MapPut("/{id:guid}", async (
    Guid id,
    CreateDropRequest request,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var drop = await dbContext.Drops
        .Include(x => x.Items)
        .Include(x => x.LocationPhotos)
        .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    if (drop is null)
    {
        return Results.NotFound();
    }

    try
    {
        drop.UpdateTransportSettings(request.IsStationary, request.PortableItemCount);

        if (request.Latitude.HasValue && request.Longitude.HasValue)
        {
            drop.SetLocation(request.Latitude.Value, request.Longitude.Value);
        }
        else
        {
            drop.ClearLocation();
        }

        drop.ReplaceLocationPhotos(request.LocationPhotoUrls);

        var tokens = Enumerable.Range(0, request.ItemCount).Select(_ => Guid.NewGuid().ToString("N"));
        drop.ReplaceItems(tokens);

        await dbContext.SaveChangesAsync(cancellationToken);
        return Results.Ok(drop);
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
});

dropsGroup.MapPost("/{id:guid}/publish", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var drop = await dbContext.Drops
        .Include(x => x.Items)
        .Include(x => x.LocationPhotos)
        .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    if (drop is null)
    {
        return Results.NotFound();
    }

    try
    {
        drop.Publish();
        await dbContext.SaveChangesAsync(cancellationToken);
        return Results.Ok();
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
});

dropsGroup.MapPost("/{id:guid}/depublish", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var drop = await dbContext.Drops.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (drop is null)
    {
        return Results.NotFound();
    }

    drop.Depublish();
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
});

dropsGroup.MapPost("/{id:guid}/mark-all-claimed", async (
    Guid id,
    ClaimDropItemRequest request,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var drop = await dbContext.Drops.Include(x => x.Items).FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (drop is null)
    {
        return Results.NotFound();
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

    try
    {
        await dropClaimService.ClaimAsync(drop, item, request.HunterUserId, request.AnonymousNickname, cancellationToken);
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
    Results.Ok(await dbContext.DropComments
        .AsNoTracking()
        .Where(x => x.DropId == dropId && !x.IsHidden)
        .OrderByDescending(x => x.CreatedAtUtc)
        .ToListAsync(cancellationToken)));

commentsGroup.MapPost("/", async (CreateCommentRequest request, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    if (string.IsNullOrWhiteSpace(request.Content))
    {
        return Results.BadRequest(new { error = "Comment content is required." });
    }

    if (!request.AuthorUserId.HasValue && string.IsNullOrWhiteSpace(request.AnonymousNickname))
    {
        return Results.BadRequest(new { error = "Anonymous comments require nickname." });
    }

    var comment = new DropComment
    {
        DropId = request.DropId,
        AuthorUserId = request.AuthorUserId,
        AnonymousNickname = request.AnonymousNickname?.Trim(),
        Content = request.Content.Trim(),
        CreatedAtUtc = DateTimeOffset.UtcNow
    };

    await dbContext.DropComments.AddAsync(comment, cancellationToken);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Created($"/api/comments/{comment.Id}", comment);
});

commentsGroup.MapPost("/{id:guid}/report", async (Guid id, ReportCommentRequest _, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var comment = await dbContext.DropComments.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (comment is null)
    {
        return Results.NotFound();
    }

    comment.Report();
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok(new { mailAlertTriggered = true });
});

commentsGroup.MapPost("/{id:guid}/hide", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var comment = await dbContext.DropComments.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (comment is null)
    {
        return Results.NotFound();
    }

    comment.Hide();
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
});

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
adminGroup.MapGet("/configuration", async (UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
    Results.Ok(await GetConfigurationAsync(dbContext, cancellationToken)));

adminGroup.MapPut("/configuration", async (
    UpdateAppConfigurationRequest request,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var config = await GetConfigurationAsync(dbContext, cancellationToken);
    config.SmtpHost = request.SmtpHost;
    config.MainMapRadiusKm = request.MainMapRadiusKm;
    config.MiniMapRadiusKm = request.MiniMapRadiusKm;
    config.UnclaimedDropRadiusKm = request.UnclaimedDropRadiusKm;
    config.ShowExactPositionWhenFullyClaimed = request.ShowExactPositionWhenFullyClaimed;

    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok(config);
});

adminGroup.MapGet("/users", async (UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
    Results.Ok(await dbContext.UserAccounts.AsNoTracking().OrderBy(x => x.UserName).ToListAsync(cancellationToken)));

adminGroup.MapPost("/users", async (
    CreateManagedUserRequest request,
    AuthApplicationService authService,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    if (request.IsProviderAccount)
    {
        var providerResult = await authService.RegisterProviderAsync(
            new RegisterProviderRequest(request.Provider ?? string.Empty, request.ProviderSubject ?? string.Empty, request.Email, request.UserName, request.Role),
            cancellationToken);

        if (!providerResult.Success)
        {
            return Results.BadRequest(providerResult);
        }

        var providerUser = await dbContext.UserAccounts.FirstOrDefaultAsync(x => x.Id == providerResult.UserId, cancellationToken);
        if (providerUser is not null)
        {
            providerUser.SetApproval(request.IsApproved);
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        return Results.Ok(providerResult);
    }

    var localResult = await authService.RegisterLocalAsync(
        new RegisterLocalRequest(request.Email, request.UserName, request.Password ?? string.Empty, request.Role),
        cancellationToken);

    if (!localResult.Success)
    {
        return Results.BadRequest(localResult);
    }

    var user = await dbContext.UserAccounts.FirstOrDefaultAsync(x => x.Id == localResult.UserId, cancellationToken);
    if (user is not null)
    {
        user.SetApproval(request.IsApproved);
        if (request.IsEmailVerified)
        {
            user.MarkEmailVerified();
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    return Results.Ok(localResult);
});

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
});

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
});

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
});

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

    user.ChangeUserName(request.UserName);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
});

app.Run();

static async Task SeedConfigurationAsync(IServiceProvider services)
{
    using var scope = services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<UrbanArtDbContext>();

    await dbContext.Database.EnsureCreatedAsync();

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

internal sealed record UpdateManagedUserProfileRequest(string UserName);

public partial class Program
{
}
