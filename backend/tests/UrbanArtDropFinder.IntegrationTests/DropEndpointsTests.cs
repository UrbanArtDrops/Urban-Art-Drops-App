using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using UrbanArtDropFinder.Domain.Art;
using UrbanArtDropFinder.Domain.Users;
using UrbanArtDropFinder.Persistence.Db;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class DropEndpointsTests : IClassFixture<TestWebApplicationFactory>
{
    private const string SamplePngDataUrl =
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/w8AAgMBgJ/gG1cAAAAASUVORK5CYII=";

    private readonly HttpClient _client;
    private readonly TestWebApplicationFactory _factory;

    public DropEndpointsTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task UpdateDrop_WhenItemCountChangesMultipleTimes_KeepsEndpointStableAndPreservesExistingTokens()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var admin = await _factory.CreateAuthenticatedUserAsync(UserRole.Admin, $"admin.drop.{uniqueId}");
        var createRequest = new
        {
            artPieceId = Guid.NewGuid(),
            dropMakerId = Guid.NewGuid(),
            isStationary = true,
            portableItemCount = (int?)null,
            dropMakerComment = "Placed during the midnight run.",
            socialChannels = new[] { "Instagram", "TikTok" },
            latitude = 50.1109,
            longitude = 8.6821,
            locationPhotoUrls = new[] { SamplePngDataUrl },
            itemCount = 2
        };

        var createResponse = await _client.PostAuthorizedAsJsonAsync("/api/drops/", createRequest, admin.AccessToken);
        await EnsureSuccessWithBodyAsync(createResponse);
        var createdDrop = await createResponse.Content.ReadFromJsonAsync<DropResponseDto>();
        Assert.NotNull(createdDrop);
        Assert.Equal(2, createdDrop!.Items.Count);
        Assert.Equal(createRequest.dropMakerComment, createdDrop.DropMakerComment);
        Assert.Equal(createRequest.socialChannels, createdDrop.SocialChannels);
        var originalTokens = createdDrop.Items.Select(item => item.QrToken).ToHashSet(StringComparer.Ordinal);

        var expandedResponse = await _client.PutAuthorizedAsJsonAsync(
            $"/api/drops/{createdDrop.Id}",
            new
            {
                createRequest.artPieceId,
                createRequest.dropMakerId,
                createRequest.isStationary,
                createRequest.portableItemCount,
                createRequest.dropMakerComment,
                createRequest.socialChannels,
                createRequest.latitude,
                createRequest.longitude,
                createRequest.locationPhotoUrls,
                itemCount = 4
            },
            admin.AccessToken);
        await EnsureSuccessWithBodyAsync(expandedResponse);
        var expandedDrop = await expandedResponse.Content.ReadFromJsonAsync<DropResponseDto>();
        Assert.NotNull(expandedDrop);
        Assert.Equal(4, expandedDrop!.Items.Count);
        Assert.True(originalTokens.IsSubsetOf(expandedDrop.Items.Select(item => item.QrToken).ToHashSet(StringComparer.Ordinal)));

        var reducedResponse = await _client.PutAuthorizedAsJsonAsync(
            $"/api/drops/{createdDrop.Id}",
            new
            {
                createRequest.artPieceId,
                createRequest.dropMakerId,
                createRequest.isStationary,
                createRequest.portableItemCount,
                createRequest.dropMakerComment,
                createRequest.socialChannels,
                createRequest.latitude,
                createRequest.longitude,
                createRequest.locationPhotoUrls,
                itemCount = 3
            },
            admin.AccessToken);
        await EnsureSuccessWithBodyAsync(reducedResponse);
        var reducedDrop = await reducedResponse.Content.ReadFromJsonAsync<DropResponseDto>();
        Assert.NotNull(reducedDrop);
        Assert.Equal(3, reducedDrop!.Items.Count);
        Assert.True(originalTokens.Overlaps(reducedDrop.Items.Select(item => item.QrToken)));
    }

    [Fact]
    public async Task UpdateDrop_WhenRequestedItemCountDropsBelowClaimedItems_ReturnsBadRequest()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var admin = await _factory.CreateAuthenticatedUserAsync(UserRole.Admin, $"admin.drop.invalid.{uniqueId}");
        var createResponse = await _client.PostAuthorizedAsJsonAsync(
            "/api/drops/",
            new
            {
                artPieceId = Guid.NewGuid(),
                dropMakerId = Guid.NewGuid(),
                isStationary = true,
                portableItemCount = (int?)null,
                latitude = 50.1109,
                longitude = 8.6821,
                locationPhotoUrls = new[] { SamplePngDataUrl },
                itemCount = 2
            },
            admin.AccessToken);
        await EnsureSuccessWithBodyAsync(createResponse);
        var createdDrop = await createResponse.Content.ReadFromJsonAsync<DropResponseDto>();
        Assert.NotNull(createdDrop);

        var claimedItemId = createdDrop!.Items.First().Id;
        var claimResponse = await _client.PostAsJsonAsync(
            $"/api/drops/{createdDrop.Id}/items/{claimedItemId}/claim",
            new { hunterUserId = (Guid?)null, anonymousNickname = "visitor-alpha" });
        await EnsureSuccessWithBodyAsync(claimResponse);

        var invalidUpdateResponse = await _client.PutAuthorizedAsJsonAsync(
            $"/api/drops/{createdDrop.Id}",
            new
            {
                createdDrop.ArtPieceId,
                createdDrop.DropMakerId,
                createdDrop.IsStationary,
                createdDrop.PortableItemCount,
                createdDrop.DropMakerComment,
                createdDrop.SocialChannels,
                createdDrop.Latitude,
                createdDrop.Longitude,
                locationPhotoUrls = new[] { SamplePngDataUrl },
                itemCount = 0
            },
            admin.AccessToken);

        Assert.Equal(HttpStatusCode.BadRequest, invalidUpdateResponse.StatusCode);
    }

    [Fact]
    public async Task ClaimByToken_ReturnsPreviewAndClaimsItemUsingConfiguredAppBaseUrl()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var admin = await _factory.CreateAuthenticatedUserAsync(UserRole.Admin, $"admin.drop.claim.{uniqueId}");

        Guid artPieceId;
        const string artPieceTitle = "Echoes of the Alley";
        using (var scope = _factory.Services.CreateScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<UrbanArtDbContext>();
            var configuration = await dbContext.AppConfigurations.SingleAsync();
            configuration.PublicAppBaseUrl = "https://app.urbanartdrops.test";

            var artPiece = ArtPiece.Create(
                Guid.NewGuid(),
                artPieceTitle,
                "Subline for the QR claim test.",
                "A descriptive mural concept with enough text to satisfy validation.",
                ArtPieceAssetKind.Image);
            artPiece.AddPhoto([0x01], "image/png");
            dbContext.ArtPieces.Add(artPiece);
            await dbContext.SaveChangesAsync();
            artPieceId = artPiece.Id;
        }

        var createResponse = await _client.PostAuthorizedAsJsonAsync(
            "/api/drops/",
            new
            {
                artPieceId,
                dropMakerId = Guid.NewGuid(),
                isStationary = true,
                portableItemCount = (int?)null,
                dropMakerComment = "Placed at the museum gate.",
                socialChannels = new[] { "Instagram" },
                latitude = 50.1109,
                longitude = 8.6821,
                locationPhotoUrls = new[] { SamplePngDataUrl },
                itemCount = 1
            },
            admin.AccessToken);
        await EnsureSuccessWithBodyAsync(createResponse);

        var createdDrop = await createResponse.Content.ReadFromJsonAsync<DropResponseDto>();
        Assert.NotNull(createdDrop);
        var createdItem = createdDrop!.Items.Single();
        Assert.Equal(
            $"https://app.urbanartdrops.test/hunter/claim?token={Uri.EscapeDataString(createdItem.QrToken)}",
            createdItem.ClaimUrl);

        var previewResponse = await _client.GetAsync($"/api/claims/by-token/{Uri.EscapeDataString(createdItem.QrToken)}");
        await EnsureSuccessWithBodyAsync(previewResponse);
        var preview = await previewResponse.Content.ReadFromJsonAsync<ClaimPreviewResponseDto>();
        Assert.NotNull(preview);
        Assert.Equal(createdDrop.Id, preview!.DropId);
        Assert.Equal(createdItem.Id, preview.DropItemId);
        Assert.Equal(artPieceId, preview.ArtPieceId);
        Assert.Equal(artPieceTitle, preview.ArtPieceTitle);
        Assert.False(preview.IsClaimed);

        var claimResponse = await _client.PostAsJsonAsync(
            "/api/claims/by-token",
            new
            {
                qrToken = createdItem.QrToken,
                anonymousNickname = "street-hunter"
            });
        await EnsureSuccessWithBodyAsync(claimResponse);

        var claimedPreviewResponse = await _client.GetAsync($"/api/claims/by-token/{Uri.EscapeDataString(createdItem.QrToken)}");
        await EnsureSuccessWithBodyAsync(claimedPreviewResponse);
        var claimedPreview = await claimedPreviewResponse.Content.ReadFromJsonAsync<ClaimPreviewResponseDto>();
        Assert.NotNull(claimedPreview);
        Assert.True(claimedPreview!.IsClaimed);
        Assert.Equal("street-hunter", claimedPreview.ClaimedByDisplayName);
    }

    [Fact]
    public async Task UpdateDrop_WhenAdminEditsDrop_CreatesNotificationsForImpactedDropMakers()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var admin = await _factory.CreateAuthenticatedUserAsync(UserRole.Admin, $"admin.drop.notify.{uniqueId}");
        var originalDropMaker = await _factory.CreateAuthenticatedUserAsync(UserRole.DropMaker, $"dropmaker.original.{uniqueId}");
        var reassignedDropMaker =
            await _factory.CreateAuthenticatedUserAsync(UserRole.DropMaker, $"dropmaker.reassigned.{uniqueId}");

        Guid artPieceId;
        using (var scope = _factory.Services.CreateScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<UrbanArtDbContext>();
            var artPiece = ArtPiece.Create(
                Guid.NewGuid(),
                $"Drop Notification Art {uniqueId}",
                "Admin update notification test",
                "A sufficiently detailed artwork description for the drop notification integration test.",
                ArtPieceAssetKind.Image);
            artPiece.AddPhoto([0x01], "image/png");
            dbContext.ArtPieces.Add(artPiece);
            await dbContext.SaveChangesAsync();
            artPieceId = artPiece.Id;
        }

        var createResponse = await _client.PostAuthorizedAsJsonAsync(
            "/api/drops/",
            new
            {
                artPieceId,
                dropMakerId = originalDropMaker.Id,
                isStationary = true,
                portableItemCount = (int?)null,
                dropMakerComment = "Original comment",
                socialChannels = new[] { "Instagram" },
                latitude = 50.1109,
                longitude = 8.6821,
                locationPhotoUrls = new[] { SamplePngDataUrl },
                itemCount = 1
            },
            admin.AccessToken);
        await EnsureSuccessWithBodyAsync(createResponse);
        var createdDrop = await createResponse.Content.ReadFromJsonAsync<DropResponseDto>();
        Assert.NotNull(createdDrop);

        var updateResponse = await _client.PutAuthorizedAsJsonAsync(
            $"/api/drops/{createdDrop!.Id}",
            new
            {
                artPieceId,
                dropMakerId = reassignedDropMaker.Id,
                isStationary = true,
                portableItemCount = (int?)null,
                dropMakerComment = "Updated by admin",
                socialChannels = new[] { "Instagram", "TikTok" },
                latitude = 50.1201,
                longitude = 8.6901,
                locationPhotoUrls = new[] { SamplePngDataUrl },
                itemCount = 2
            },
            admin.AccessToken);
        await EnsureSuccessWithBodyAsync(updateResponse);

        var originalNotifications = await _client.GetAuthorizedAsync(
            "/api/profile/notifications",
            originalDropMaker.AccessToken);
        await EnsureSuccessWithBodyAsync(originalNotifications);
        var originalPayload = await originalNotifications.Content.ReadFromJsonAsync<List<UserNotificationDto>>();
        Assert.NotNull(originalPayload);
        Assert.Contains(
            originalPayload!,
            notification => notification.Category == "admin-drop"
                && notification.RelatedEntityId == createdDrop.Id
                && notification.Message.Contains("bearbeitet", StringComparison.OrdinalIgnoreCase));

        var reassignedNotifications = await _client.GetAuthorizedAsync(
            "/api/profile/notifications",
            reassignedDropMaker.AccessToken);
        await EnsureSuccessWithBodyAsync(reassignedNotifications);
        var reassignedPayload = await reassignedNotifications.Content.ReadFromJsonAsync<List<UserNotificationDto>>();
        Assert.NotNull(reassignedPayload);
        Assert.Contains(
            reassignedPayload!,
            notification => notification.Category == "admin-drop"
                && notification.RelatedEntityId == createdDrop.Id);
    }

    private sealed record DropResponseDto(
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

    private sealed record PhotoReferenceDto(Guid Id, string Url);

    private sealed record DropItemResponseDto(
        Guid Id,
        string QrToken,
        string ClaimUrl,
        bool IsClaimed,
        Guid? ClaimedByUserId,
        string? ClaimedByAnonymousNickname,
        DateTimeOffset? ClaimedAtUtc);

    private sealed record ClaimPreviewResponseDto(
        Guid DropId,
        Guid DropItemId,
        Guid ArtPieceId,
        string ArtPieceTitle,
        bool IsClaimed,
        string? ClaimedByDisplayName);

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
