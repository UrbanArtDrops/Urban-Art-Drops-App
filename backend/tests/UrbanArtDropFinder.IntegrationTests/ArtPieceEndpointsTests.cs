using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using UrbanArtDropFinder.Contracts.Art;
using UrbanArtDropFinder.Domain.Art;
using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class ArtPieceEndpointsTests : IClassFixture<TestWebApplicationFactory>
{
    private const string SamplePngDataUrl =
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/w8AAgMBgJ/gG1cAAAAASUVORK5CYII=";
    private const string SampleGlbDataUrl =
        "data:model/gltf-binary;base64,Z2xURg==";

    private readonly HttpClient _client;
    private readonly TestWebApplicationFactory _factory;

    public ArtPieceEndpointsTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task ArtPieceCrudFlow_CreatesUpdatesPublishesAndDeletesResource()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var admin = await _factory.CreateAuthenticatedUserAsync(UserRole.Admin, $"admin.art.{uniqueId}");
        var createRequest = new
        {
            artistId = Guid.NewGuid(),
            title = $"Crystal Owl {uniqueId}",
            subtitle = "Moonlit alley edition",
            description = "This artwork description is long enough for validation.",
            assetKind = ArtPieceAssetKind.Model3d,
            photoUrls = new[] { SamplePngDataUrl },
            assetSource = SampleGlbDataUrl,
            assetFileName = "crystal-owl.glb"
        };

        var createResponse = await _client.PostAuthorizedAsJsonAsync("/api/art-pieces/", createRequest, admin.AccessToken);

        await EnsureSuccessWithBodyAsync(createResponse);
        var createdArtPiece = await createResponse.Content.ReadFromJsonAsync<ArtPieceResponseDto>();
        Assert.NotNull(createdArtPiece);
        Assert.Equal(createRequest.artistId, createdArtPiece!.ArtistId);
        Assert.Equal(createRequest.title, createdArtPiece.Title);
        Assert.Equal(createRequest.subtitle, createdArtPiece.Subtitle);
        Assert.Equal(ArtPieceAssetKind.Model3d, createdArtPiece.AssetKind);
        Assert.Single(createdArtPiece.Photos);
        Assert.NotNull(createdArtPiece.AssetFile);
        Assert.Equal("crystal-owl.glb", createdArtPiece.AssetFile!.FileName);

        var mediaResponse = await _client.GetAsync(createdArtPiece.Photos.First().Url);
        mediaResponse.EnsureSuccessStatusCode();
        Assert.Equal("image/png", mediaResponse.Content.Headers.ContentType?.MediaType);

        var assetResponse = await _client.GetAsync(createdArtPiece.AssetFile.Url);
        await EnsureSuccessWithBodyAsync(assetResponse);
        Assert.Equal("model/gltf-binary", assetResponse.Content.Headers.ContentType?.MediaType);
        Assert.Equal("attachment", assetResponse.Content.Headers.ContentDisposition?.DispositionType);
        Assert.Equal("crystal-owl.glb", assetResponse.Content.Headers.ContentDisposition?.FileNameStar);

        var getResponse = await _client.GetAsync($"/api/art-pieces/{createdArtPiece.Id}");
        await EnsureSuccessWithBodyAsync(getResponse);
        var loadedArtPiece = await getResponse.Content.ReadFromJsonAsync<ArtPieceResponseDto>();
        Assert.NotNull(loadedArtPiece);
        Assert.Equal(createdArtPiece.Id, loadedArtPiece!.Id);

        var updatedArtistId = Guid.NewGuid();
        var updateRequest = new
        {
            artistId = updatedArtistId,
            title = $"Steel Fox {uniqueId}",
            subtitle = "Rain edition",
            description = "This updated artwork description is also long enough.",
            assetKind = ArtPieceAssetKind.Model3d,
            photoUrls = new[] { SamplePngDataUrl },
            assetSource = SampleGlbDataUrl,
            assetFileName = "steel-fox.glb"
        };

        var updateResponse = await _client.PutAuthorizedAsJsonAsync(
            $"/api/art-pieces/{createdArtPiece.Id}",
            updateRequest,
            admin.AccessToken);

        await EnsureSuccessWithBodyAsync(updateResponse);
        var updatedArtPiece = await updateResponse.Content.ReadFromJsonAsync<ArtPieceResponseDto>();
        Assert.NotNull(updatedArtPiece);
        Assert.Equal(updatedArtistId, updatedArtPiece!.ArtistId);
        Assert.Equal(updateRequest.title, updatedArtPiece.Title);
        Assert.Equal(updateRequest.subtitle, updatedArtPiece.Subtitle);
        Assert.Equal(ArtPieceAssetKind.Model3d, updatedArtPiece.AssetKind);
        Assert.False(updatedArtPiece.IsPublished);
        Assert.NotNull(updatedArtPiece.AssetFile);
        Assert.Equal("steel-fox.glb", updatedArtPiece.AssetFile!.FileName);

        var publishResponse = await _client.PostAuthorizedAsync(
            $"/api/art-pieces/{createdArtPiece.Id}/publish",
            admin.AccessToken);

        await EnsureSuccessWithBodyAsync(publishResponse);
        var publishedArtPiece = await _client.GetFromJsonAsync<ArtPieceResponseDto>(
            $"/api/art-pieces/{createdArtPiece.Id}");
        Assert.NotNull(publishedArtPiece);
        Assert.True(publishedArtPiece!.IsPublished);

        var deleteResponse = await _client.DeleteAuthorizedAsync($"/api/art-pieces/{createdArtPiece.Id}", admin.AccessToken);
        deleteResponse.EnsureSuccessStatusCode();

        var deletedGetResponse = await _client.GetAsync($"/api/art-pieces/{createdArtPiece.Id}");
        Assert.Equal(System.Net.HttpStatusCode.NotFound, deletedGetResponse.StatusCode);
    }

    [Fact]
    public async Task UpdateArtPiece_WhenAdminEditsArtwork_CreatesNotificationsForImpactedArtists()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var admin = await _factory.CreateAuthenticatedUserAsync(UserRole.Admin, $"admin.notify.art.{uniqueId}");
        var originalArtist = await _factory.CreateAuthenticatedUserAsync(UserRole.Artist, $"artist.original.{uniqueId}");
        var reassignedArtist = await _factory.CreateAuthenticatedUserAsync(UserRole.Artist, $"artist.reassigned.{uniqueId}");

        var createResponse = await _client.PostAuthorizedAsJsonAsync(
            "/api/art-pieces/",
            new
            {
                artistId = originalArtist.Id,
                title = $"Neon Sparrow {uniqueId}",
                subtitle = "Original owner",
                description = "A long enough artwork description for the admin notification test.",
                assetKind = ArtPieceAssetKind.Image,
                photoUrls = new[] { SamplePngDataUrl }
            },
            admin.AccessToken);
        await EnsureSuccessWithBodyAsync(createResponse);
        var createdArtPiece = await createResponse.Content.ReadFromJsonAsync<ArtPieceResponseDto>();
        Assert.NotNull(createdArtPiece);

        var updateResponse = await _client.PutAuthorizedAsJsonAsync(
            $"/api/art-pieces/{createdArtPiece!.Id}",
            new
            {
                artistId = reassignedArtist.Id,
                title = $"Neon Sparrow {uniqueId} Updated",
                subtitle = "Reassigned owner",
                description = "An updated artwork description that is also long enough for validation.",
                assetKind = ArtPieceAssetKind.Image,
                photoUrls = new[] { SamplePngDataUrl }
            },
            admin.AccessToken);
        await EnsureSuccessWithBodyAsync(updateResponse);

        var originalArtistNotifications = await _client.GetAuthorizedAsync(
            "/api/profile/notifications",
            originalArtist.AccessToken);
        await EnsureSuccessWithBodyAsync(originalArtistNotifications);
        var originalArtistPayload = await originalArtistNotifications.Content.ReadFromJsonAsync<List<UserNotificationDto>>();
        Assert.NotNull(originalArtistPayload);
        Assert.Contains(
            originalArtistPayload!,
            notification => notification.Category == "admin-art-piece"
                && notification.RelatedEntityId == createdArtPiece.Id
                && notification.Message.Contains("bearbeitet", StringComparison.OrdinalIgnoreCase));

        var reassignedArtistNotifications = await _client.GetAuthorizedAsync(
            "/api/profile/notifications",
            reassignedArtist.AccessToken);
        await EnsureSuccessWithBodyAsync(reassignedArtistNotifications);
        var reassignedArtistPayload =
            await reassignedArtistNotifications.Content.ReadFromJsonAsync<List<UserNotificationDto>>();
        Assert.NotNull(reassignedArtistPayload);
        Assert.Contains(
            reassignedArtistPayload!,
            notification => notification.Category == "admin-art-piece"
                && notification.RelatedEntityId == createdArtPiece.Id);
    }

    private sealed record ArtPieceResponseDto(
        Guid Id,
        Guid ArtistId,
        string Title,
        string Subtitle,
        string Description,
        ArtPieceAssetKind AssetKind,
        bool IsPublished,
        IReadOnlyCollection<PhotoReferenceDto> Photos,
        BinaryFileReferenceDto? AssetFile);

    private sealed record PhotoReferenceDto(Guid Id, string Url);
    private sealed record BinaryFileReferenceDto(Guid Id, string Url, string FileName, string ContentType, long SizeBytes);

    private sealed record UserNotificationDto(
        Guid Id,
        string Title,
        string Message,
        string Category,
        bool IsRead,
        DateTimeOffset CreatedAtUtc,
        Guid? RelatedEntityId,
        string? RelatedEntityType);

    private static async Task EnsureSuccessWithBodyAsync(HttpResponseMessage response)
    {
        if (response.IsSuccessStatusCode)
        {
            return;
        }

        var body = await response.Content.ReadAsStringAsync();
        throw new Xunit.Sdk.XunitException($"Unexpected status {(int)response.StatusCode}: {body}");
    }
}
