using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using UrbanArtDropFinder.Contracts.Art;
using UrbanArtDropFinder.Contracts.Comments;
using UrbanArtDropFinder.Contracts.Moderation;
using UrbanArtDropFinder.Domain.Art;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class ModerationEndpointsTests : IClassFixture<TestWebApplicationFactory>
{
    private const string SamplePngDataUrl =
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/w8AAgMBgJ/gG1cAAAAASUVORK5CYII=";

    private readonly HttpClient _client;

    public ModerationEndpointsTests(TestWebApplicationFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task ModerationFlow_ReportsQueuesAndResolvesCommentsAndArtPieces()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var artistId = Guid.NewGuid();
        var createArtResponse = await _client.PostAsJsonAsync(
            "/api/art-pieces/",
            new
            {
                artistId,
                title = $"Reported Piece {uniqueId}",
                description = "This artwork description is intentionally long enough for moderation testing.",
                assetKind = ArtPieceAssetKind.Image,
                photoUrls = new[] { SamplePngDataUrl },
                assetSource = (string?)null,
                assetFileName = (string?)null
            });

        await EnsureSuccessWithBodyAsync(createArtResponse);
        var artPiece = await createArtResponse.Content.ReadFromJsonAsync<ArtPieceResponseDto>();
        Assert.NotNull(artPiece);

        var publishArtResponse = await _client.PostAsync($"/api/art-pieces/{artPiece!.Id}/publish", null);
        await EnsureSuccessWithBodyAsync(publishArtResponse);

        var createDropResponse = await _client.PostAsJsonAsync(
            "/api/drops/",
            new
            {
                artPieceId = artPiece.Id,
                dropMakerId = Guid.NewGuid(),
                isStationary = true,
                portableItemCount = (int?)null,
                latitude = 52.52,
                longitude = 13.405,
                locationPhotoUrls = new[] { SamplePngDataUrl },
                itemCount = 1
            });

        await EnsureSuccessWithBodyAsync(createDropResponse);
        var drop = await createDropResponse.Content.ReadFromJsonAsync<DropResponseDto>();
        Assert.NotNull(drop);

        var createCommentResponse = await _client.PostAsJsonAsync(
            "/api/comments/",
            new CreateCommentRequest(drop!.Id, null, "queue.user", "This comment should appear in the moderation queue."));
        await EnsureSuccessWithBodyAsync(createCommentResponse);
        var comment = await createCommentResponse.Content.ReadFromJsonAsync<CommentResponse>();
        Assert.NotNull(comment);

        var reportCommentResponse = await _client.PostAsJsonAsync(
            $"/api/comments/{comment!.Id}/report",
            new ReportCommentRequest("Comment contains abuse"));
        await EnsureSuccessWithBodyAsync(reportCommentResponse);

        var reportArtResponse = await _client.PostAsJsonAsync(
            $"/api/art-pieces/{artPiece.Id}/report",
            new ReportArtPieceRequest("Artwork needs content review"));
        await EnsureSuccessWithBodyAsync(reportArtResponse);

        var queueResponse = await _client.GetFromJsonAsync<ModerationQueueResponse>("/api/moderation/reports");
        Assert.NotNull(queueResponse);
        Assert.Contains(queueResponse!.Comments, entry => entry.Id == comment.Id && entry.DropId == drop.Id);
        Assert.Contains(queueResponse.ArtPieces, entry => entry.Id == artPiece.Id && entry.IsPublished);

        var hideCommentResponse = await _client.PostAsync($"/api/moderation/comments/{comment.Id}/hide", null);
        await EnsureSuccessWithBodyAsync(hideCommentResponse);

        var publicComments = await _client.GetFromJsonAsync<List<CommentResponse>>($"/api/comments/drop/{drop.Id}");
        Assert.NotNull(publicComments);
        Assert.DoesNotContain(publicComments!, entry => entry.Id == comment.Id);

        var depublishArtResponse = await _client.PostAsync($"/api/moderation/art-pieces/{artPiece.Id}/depublish", null);
        await EnsureSuccessWithBodyAsync(depublishArtResponse);

        var reloadedArt = await _client.GetFromJsonAsync<ArtPieceResponseDto>($"/api/art-pieces/{artPiece.Id}");
        Assert.NotNull(reloadedArt);
        Assert.False(reloadedArt!.IsPublished);

        var clearedQueue = await _client.GetFromJsonAsync<ModerationQueueResponse>("/api/moderation/reports");
        Assert.NotNull(clearedQueue);
        Assert.DoesNotContain(clearedQueue!.Comments, entry => entry.Id == comment.Id);
        Assert.DoesNotContain(clearedQueue.ArtPieces, entry => entry.Id == artPiece.Id);
    }

    private sealed record ArtPieceResponseDto(Guid Id, bool IsPublished);

    private sealed record DropResponseDto(Guid Id);

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
