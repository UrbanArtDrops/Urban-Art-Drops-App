using System.Net.Http.Headers;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using UrbanArtDropFinder.Application.Auth;
using UrbanArtDropFinder.Application.Drops;
using UrbanArtDropFinder.Contracts.Admin;
using UrbanArtDropFinder.Contracts.Art;
using UrbanArtDropFinder.Contracts.Auth;
using UrbanArtDropFinder.Contracts.Comments;
using UrbanArtDropFinder.Contracts.Drops;
using UrbanArtDropFinder.Contracts.Moderation;
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
builder.Services.AddHttpClient("photo-fetcher");
builder.Services.AddCors(options =>
{
    options.AddPolicy("FrontendDev", policy =>
    {
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
    });
});
builder.Services.AddUrbanArtInfrastructure(builder.Configuration);

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("FrontendDev");

await SeedConfigurationAsync(app.Services);

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
    try
    {
        var artPiece = ArtPiece.Create(request.ArtistId, request.Title, request.Description, request.AssetKind);
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
});

artGroup.MapPut("/{id:guid}", async (
    Guid id,
    UpdateArtPieceRequest request,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    IHttpClientFactory httpClientFactory,
    CancellationToken cancellationToken) =>
{
    var artPiece = await dbContext.ArtPieces.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (artPiece is null)
    {
        return Results.NotFound();
    }

    try
    {
        artPiece.UpdateDetails(request.ArtistId, request.Title, request.Description, request.AssetKind);
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
});

artGroup.MapPost("/{id:guid}/publish", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var artPiece = await dbContext.ArtPieces
        .Include(x => x.Photos)
        .Include(x => x.AssetFile)
        .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
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
dropsGroup.MapGet("/", async (HttpContext httpContext, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var drops = await dbContext.Drops
        .Include(x => x.Items)
        .Include(x => x.LocationPhotos)
        .AsNoTracking()
        .ToListAsync(cancellationToken);

    var response = drops
        .Select(drop => ToDropResponse(drop, httpContext.Request))
        .ToList();
    return Results.Ok(response);
});

dropsGroup.MapGet("/{id:guid}", async (Guid id, HttpContext httpContext, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var drop = await dbContext.Drops
        .Include(x => x.Items)
        .Include(x => x.LocationPhotos)
        .AsNoTracking()
        .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    return drop is null ? Results.NotFound() : Results.Ok(ToDropResponse(drop, httpContext.Request));
});

dropsGroup.MapPost("/", async (
    CreateDropRequest request,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    IHttpClientFactory httpClientFactory,
    CancellationToken cancellationToken) =>
{
    try
    {
        var drop = Drop.Create(request.ArtPieceId, request.DropMakerId, request.IsStationary, request.PortableItemCount);

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

        return Results.Created($"/api/drops/{drop.Id}", ToDropResponse(drop, httpContext.Request));
    }
    catch (DomainValidationException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
});

dropsGroup.MapPut("/{id:guid}", async (
    Guid id,
    CreateDropRequest request,
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    IHttpClientFactory httpClientFactory,
    CancellationToken cancellationToken) =>
{
    var drop = await dbContext.Drops.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    if (drop is null)
    {
        return Results.NotFound();
    }

    try
    {
        var currentItems = await dbContext.DropItems
            .Where(item => item.DropId == id)
            .ToListAsync(cancellationToken);
        drop.UpdateTransportSettings(request.IsStationary, request.PortableItemCount);

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
            .AsNoTracking()
            .Where(photo => photo.DropId == id)
            .ToListAsync(cancellationToken);
        foreach (var existingLocationPhoto in existingLocationPhotos)
        {
            dbContext.Entry(existingLocationPhoto).State = EntityState.Deleted;
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
        var reloadedDrop = await dbContext.Drops
            .Include(x => x.Items)
            .Include(x => x.LocationPhotos)
            .AsNoTracking()
            .FirstAsync(x => x.Id == id, cancellationToken);
        return Results.Ok(ToDropResponse(reloadedDrop, httpContext.Request));
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

dropsGroup.MapDelete("/{id:guid}", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var drop = await dbContext.Drops
        .Include(x => x.Items)
        .Include(x => x.LocationPhotos)
        .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

    if (drop is null)
    {
        return Results.NotFound();
    }

    dbContext.Drops.Remove(drop);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.NoContent();
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
    var usersById = request.AuthorUserId.HasValue
        ? await dbContext.UserAccounts
            .AsNoTracking()
            .Where(user => user.Id == request.AuthorUserId.Value)
            .ToDictionaryAsync(user => user.Id, cancellationToken)
        : new Dictionary<Guid, UserAccount>();

    return Results.Created($"/api/comments/{comment.Id}", ToCommentResponse(comment, usersById));
});

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
});

commentsGroup.MapPost("/{id:guid}/hide", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var comment = await dbContext.DropComments.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (comment is null)
    {
        return Results.NotFound();
    }

    comment.Hide(DateTimeOffset.UtcNow);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
});

commentsGroup.MapPost("/{id:guid}/dismiss-report", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var comment = await dbContext.DropComments.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    if (comment is null)
    {
        return Results.NotFound();
    }

    comment.DismissReport();
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
});

var moderationGroup = app.MapGroup("/api/moderation");
moderationGroup.MapGet("/reports", async (
    HttpContext httpContext,
    UrbanArtDbContext dbContext,
    CancellationToken cancellationToken) =>
{
    var reportedComments = await dbContext.DropComments
        .AsNoTracking()
        .Where(comment => comment.IsReported)
        .OrderByDescending(comment => comment.ReportedAtUtc ?? comment.CreatedAtUtc)
        .ToListAsync(cancellationToken);
    var reportedArtPieces = await dbContext.ArtPieces
        .Include(artPiece => artPiece.Photos)
        .AsNoTracking()
        .Where(artPiece => artPiece.IsReported)
        .OrderByDescending(artPiece => artPiece.ReportedAtUtc)
        .ToListAsync(cancellationToken);

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
});

moderationGroup.MapPost("/comments/{id:guid}/hide", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var comment = await dbContext.DropComments.FirstOrDefaultAsync(entry => entry.Id == id, cancellationToken);
    if (comment is null)
    {
        return Results.NotFound();
    }

    comment.Hide(DateTimeOffset.UtcNow);
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
});

moderationGroup.MapPost("/comments/{id:guid}/dismiss-report", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var comment = await dbContext.DropComments.FirstOrDefaultAsync(entry => entry.Id == id, cancellationToken);
    if (comment is null)
    {
        return Results.NotFound();
    }

    comment.DismissReport();
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
});

moderationGroup.MapPost("/art-pieces/{id:guid}/depublish", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var artPiece = await dbContext.ArtPieces.FirstOrDefaultAsync(entry => entry.Id == id, cancellationToken);
    if (artPiece is null)
    {
        return Results.NotFound();
    }

    artPiece.Depublish();
    artPiece.DismissReport();
    await dbContext.SaveChangesAsync(cancellationToken);
    return Results.Ok();
});

moderationGroup.MapPost("/art-pieces/{id:guid}/dismiss-report", async (Guid id, UrbanArtDbContext dbContext, CancellationToken cancellationToken) =>
{
    var artPiece = await dbContext.ArtPieces.FirstOrDefaultAsync(entry => entry.Id == id, cancellationToken);
    if (artPiece is null)
    {
        return Results.NotFound();
    }

    artPiece.DismissReport();
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

static DropResponseDto ToDropResponse(Drop drop, HttpRequest request)
{
    var baseUri = $"{request.Scheme}://{request.Host}";
    var locationPhotos = drop.LocationPhotos
        .Select(photo => new PhotoReferenceDto(photo.Id, $"{baseUri}/api/media/drop-location-photos/{photo.Id}"))
        .ToList();
    var items = drop.Items
        .Select(item => new DropItemResponseDto(
            item.Id,
            item.QrToken,
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
        drop.Latitude,
        drop.Longitude,
        drop.IsPublished,
        locationPhotos,
        items);
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

    return false;
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
    double? Latitude,
    double? Longitude,
    bool IsPublished,
    IReadOnlyCollection<PhotoReferenceDto> LocationPhotos,
    IReadOnlyCollection<DropItemResponseDto> Items);

internal readonly record struct ResolvedPhotoPayload(byte[] BinaryData, string ContentType);
internal readonly record struct ResolvedAssetPayload(byte[] BinaryData, string ContentType, string FileName);

internal enum MediaPhotoKind
{
    ArtPiece = 0,
    DropLocation = 1
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

internal sealed record UpdateManagedUserProfileRequest(string UserName);

public partial class Program
{
}
