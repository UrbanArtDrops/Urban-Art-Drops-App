using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class DropEndpointsTests : IClassFixture<TestWebApplicationFactory>
{
    private const string SamplePngDataUrl =
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/w8AAgMBgJ/gG1cAAAAASUVORK5CYII=";

    private readonly HttpClient _client;

    public DropEndpointsTests(TestWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task UpdateDrop_WhenItemCountChangesMultipleTimes_KeepsEndpointStableAndPreservesExistingTokens()
    {
        var createRequest = new
        {
            artPieceId = Guid.NewGuid(),
            dropMakerId = Guid.NewGuid(),
            isStationary = true,
            portableItemCount = (int?)null,
            latitude = 50.1109,
            longitude = 8.6821,
            locationPhotoUrls = new[] { SamplePngDataUrl },
            itemCount = 2
        };

        var createResponse = await _client.PostAsJsonAsync("/api/drops/", createRequest);
        await EnsureSuccessWithBodyAsync(createResponse);
        var createdDrop = await createResponse.Content.ReadFromJsonAsync<DropResponseDto>();
        Assert.NotNull(createdDrop);
        Assert.Equal(2, createdDrop!.Items.Count);
        var originalTokens = createdDrop.Items.Select(item => item.QrToken).ToHashSet(StringComparer.Ordinal);

        var expandedResponse = await _client.PutAsJsonAsync(
            $"/api/drops/{createdDrop.Id}",
            new
            {
                createRequest.artPieceId,
                createRequest.dropMakerId,
                createRequest.isStationary,
                createRequest.portableItemCount,
                createRequest.latitude,
                createRequest.longitude,
                createRequest.locationPhotoUrls,
                itemCount = 4
            });
        await EnsureSuccessWithBodyAsync(expandedResponse);
        var expandedDrop = await expandedResponse.Content.ReadFromJsonAsync<DropResponseDto>();
        Assert.NotNull(expandedDrop);
        Assert.Equal(4, expandedDrop!.Items.Count);
        Assert.True(originalTokens.IsSubsetOf(expandedDrop.Items.Select(item => item.QrToken).ToHashSet(StringComparer.Ordinal)));

        var reducedResponse = await _client.PutAsJsonAsync(
            $"/api/drops/{createdDrop.Id}",
            new
            {
                createRequest.artPieceId,
                createRequest.dropMakerId,
                createRequest.isStationary,
                createRequest.portableItemCount,
                createRequest.latitude,
                createRequest.longitude,
                createRequest.locationPhotoUrls,
                itemCount = 3
            });
        await EnsureSuccessWithBodyAsync(reducedResponse);
        var reducedDrop = await reducedResponse.Content.ReadFromJsonAsync<DropResponseDto>();
        Assert.NotNull(reducedDrop);
        Assert.Equal(3, reducedDrop!.Items.Count);
        Assert.True(originalTokens.Overlaps(reducedDrop.Items.Select(item => item.QrToken)));
    }

    [Fact]
    public async Task UpdateDrop_WhenRequestedItemCountDropsBelowClaimedItems_ReturnsBadRequest()
    {
        var createResponse = await _client.PostAsJsonAsync(
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
            });
        await EnsureSuccessWithBodyAsync(createResponse);
        var createdDrop = await createResponse.Content.ReadFromJsonAsync<DropResponseDto>();
        Assert.NotNull(createdDrop);

        var claimedItemId = createdDrop!.Items.First().Id;
        var claimResponse = await _client.PostAsJsonAsync(
            $"/api/drops/{createdDrop.Id}/items/{claimedItemId}/claim",
            new { hunterUserId = (Guid?)null, anonymousNickname = "visitor-alpha" });
        await EnsureSuccessWithBodyAsync(claimResponse);

        var invalidUpdateResponse = await _client.PutAsJsonAsync(
            $"/api/drops/{createdDrop.Id}",
            new
            {
                createdDrop.ArtPieceId,
                createdDrop.DropMakerId,
                createdDrop.IsStationary,
                createdDrop.PortableItemCount,
                createdDrop.Latitude,
                createdDrop.Longitude,
                locationPhotoUrls = new[] { SamplePngDataUrl },
                itemCount = 0
            });

        Assert.Equal(HttpStatusCode.BadRequest, invalidUpdateResponse.StatusCode);
    }

    private sealed record DropResponseDto(
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

    private sealed record PhotoReferenceDto(Guid Id, string Url);

    private sealed record DropItemResponseDto(
        Guid Id,
        string QrToken,
        bool IsClaimed,
        Guid? ClaimedByUserId,
        string? ClaimedByAnonymousNickname,
        DateTimeOffset? ClaimedAtUtc);

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
