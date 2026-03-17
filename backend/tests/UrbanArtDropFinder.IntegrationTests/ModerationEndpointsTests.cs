using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using UrbanArtDropFinder.Contracts.Art;
using UrbanArtDropFinder.Contracts.Comments;
using UrbanArtDropFinder.Contracts.Moderation;
using UrbanArtDropFinder.Domain.Art;
using UrbanArtDropFinder.Domain.Users;
using UrbanArtDropFinder.Persistence.Db;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class ModerationEndpointsTests : IClassFixture<TestWebApplicationFactory>
{
    private const string SamplePngDataUrl =
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/w8AAgMBgJ/gG1cAAAAASUVORK5CYII=";

    private readonly HttpClient _client;
    private readonly TestWebApplicationFactory _factory;

    public ModerationEndpointsTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task ModerationFlow_ReportsQueuesAndResolvesCommentsAndArtPieces()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var moderator = await CreateUserAsync(UserRole.Moderator, $"moderator.{uniqueId}");
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

        var queueResponse = await GetModerationQueueAsync(moderator.Id);
        Assert.NotNull(queueResponse);
        Assert.Contains(queueResponse!.Comments, entry => entry.Id == comment.Id && entry.DropId == drop.Id);
        Assert.Contains(queueResponse.ArtPieces, entry => entry.Id == artPiece.Id && entry.IsPublished);

        var hideCommentResponse = await PostModerationAsync(
            $"/api/moderation/comments/{comment.Id}/hide",
            moderator.Id);
        await EnsureSuccessWithBodyAsync(hideCommentResponse);

        var publicComments = await _client.GetFromJsonAsync<List<CommentResponse>>($"/api/comments/drop/{drop.Id}");
        Assert.NotNull(publicComments);
        Assert.DoesNotContain(publicComments!, entry => entry.Id == comment.Id);

        var depublishArtResponse = await PostModerationAsync(
            $"/api/moderation/art-pieces/{artPiece.Id}/depublish",
            moderator.Id);
        await EnsureSuccessWithBodyAsync(depublishArtResponse);

        var reloadedArt = await _client.GetFromJsonAsync<ArtPieceResponseDto>($"/api/art-pieces/{artPiece.Id}");
        Assert.NotNull(reloadedArt);
        Assert.False(reloadedArt!.IsPublished);

        var clearedQueue = await GetModerationQueueAsync(moderator.Id);
        Assert.NotNull(clearedQueue);
        Assert.DoesNotContain(clearedQueue!.Comments, entry => entry.Id == comment.Id);
        Assert.DoesNotContain(clearedQueue.ArtPieces, entry => entry.Id == artPiece.Id);
    }

    [Fact]
    public async Task ArtistModerationQueue_ContainsOnlyReportedCommentsForOwnArtPieces()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var artist = await CreateUserAsync(UserRole.Artist, $"artist.owner.{uniqueId}");
        var otherArtist = await CreateUserAsync(UserRole.Artist, $"artist.other.{uniqueId}");

        var ownDrop = await CreateReportedCommentAsync(
            artist.Id,
            $"Own Queue Piece {uniqueId}",
            $"own-{uniqueId}",
            "This reported comment belongs to the actor.");
        var foreignDrop = await CreateReportedCommentAsync(
            otherArtist.Id,
            $"Foreign Queue Piece {uniqueId}",
            $"foreign-{uniqueId}",
            "This reported comment belongs to another artist.");

        var queueResponse = await GetModerationQueueAsync(artist.Id);

        Assert.NotNull(queueResponse);
        Assert.Contains(queueResponse!.Comments, entry => entry.DropId == ownDrop.DropId);
        Assert.DoesNotContain(queueResponse.Comments, entry => entry.DropId == foreignDrop.DropId);
        Assert.Empty(queueResponse.ArtPieces);
    }

    [Fact]
    public async Task ArtistModerationActions_CanHideOwnCommentButCannotModerateForeignCommentOrArtPiece()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var artist = await CreateUserAsync(UserRole.Artist, $"artist.owner.{uniqueId}");
        var otherArtist = await CreateUserAsync(UserRole.Artist, $"artist.other.{uniqueId}");

        var ownDrop = await CreateReportedCommentAsync(
            artist.Id,
            $"Own Action Piece {uniqueId}",
            $"own-action-{uniqueId}",
            "Own reported comment.");
        var foreignDrop = await CreateReportedCommentAsync(
            otherArtist.Id,
            $"Foreign Action Piece {uniqueId}",
            $"foreign-action-{uniqueId}",
            "Foreign reported comment.");

        var hideOwnResponse = await PostModerationAsync(
            $"/api/moderation/comments/{ownDrop.CommentId}/hide",
            artist.Id);
        await EnsureSuccessWithBodyAsync(hideOwnResponse);

        var ownPublicComments = await _client.GetFromJsonAsync<List<CommentResponse>>(
            $"/api/comments/drop/{ownDrop.DropId}");
        Assert.NotNull(ownPublicComments);
        Assert.DoesNotContain(ownPublicComments!, entry => entry.Id == ownDrop.CommentId);

        var hideForeignResponse = await PostModerationAsync(
            $"/api/moderation/comments/{foreignDrop.CommentId}/hide",
            artist.Id);
        Assert.Equal(HttpStatusCode.Forbidden, hideForeignResponse.StatusCode);

        var depublishForeignArtResponse = await PostModerationAsync(
            $"/api/moderation/art-pieces/{foreignDrop.ArtPieceId}/depublish",
            artist.Id);
        Assert.Equal(HttpStatusCode.Forbidden, depublishForeignArtResponse.StatusCode);
    }

    [Fact]
    public async Task DropMakerModerationQueue_ContainsOnlyReportedCommentsForOwnDrops()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var artist = await CreateUserAsync(UserRole.Artist, $"artist.queue.{uniqueId}");
        var dropMaker = await CreateUserAsync(UserRole.DropMaker, $"dropmaker.owner.{uniqueId}");
        var otherDropMaker = await CreateUserAsync(UserRole.DropMaker, $"dropmaker.other.{uniqueId}");

        var ownDrop = await CreateReportedCommentAsync(
            artist.Id,
            $"Drop-Maker Queue Piece {uniqueId}",
            $"own-dropmaker-{uniqueId}",
            "This reported comment belongs to the drop-maker.",
            dropMaker.Id);
        var foreignDrop = await CreateReportedCommentAsync(
            artist.Id,
            $"Drop-Maker Foreign Piece {uniqueId}",
            $"foreign-dropmaker-{uniqueId}",
            "This reported comment belongs to another drop-maker.",
            otherDropMaker.Id);

        var queueResponse = await GetModerationQueueAsync(dropMaker.Id);

        Assert.NotNull(queueResponse);
        Assert.Contains(queueResponse!.Comments, entry => entry.DropId == ownDrop.DropId);
        Assert.DoesNotContain(queueResponse.Comments, entry => entry.DropId == foreignDrop.DropId);
        Assert.Empty(queueResponse.ArtPieces);
    }

    [Fact]
    public async Task DropMakerModerationActions_CanHideOwnCommentButCannotModerateForeignCommentOrArtPiece()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var artist = await CreateUserAsync(UserRole.Artist, $"artist.dropmaker.{uniqueId}");
        var dropMaker = await CreateUserAsync(UserRole.DropMaker, $"dropmaker.owner.{uniqueId}");
        var otherDropMaker = await CreateUserAsync(UserRole.DropMaker, $"dropmaker.other.{uniqueId}");

        var ownDrop = await CreateReportedCommentAsync(
            artist.Id,
            $"Own Drop-Maker Piece {uniqueId}",
            $"own-dropmaker-action-{uniqueId}",
            "Own reported comment for drop-maker.",
            dropMaker.Id);
        var foreignDrop = await CreateReportedCommentAsync(
            artist.Id,
            $"Foreign Drop-Maker Piece {uniqueId}",
            $"foreign-dropmaker-action-{uniqueId}",
            "Foreign reported comment for drop-maker.",
            otherDropMaker.Id);

        var hideOwnResponse = await PostModerationAsync(
            $"/api/moderation/comments/{ownDrop.CommentId}/hide",
            dropMaker.Id);
        await EnsureSuccessWithBodyAsync(hideOwnResponse);

        var ownPublicComments = await _client.GetFromJsonAsync<List<CommentResponse>>(
            $"/api/comments/drop/{ownDrop.DropId}");
        Assert.NotNull(ownPublicComments);
        Assert.DoesNotContain(ownPublicComments!, entry => entry.Id == ownDrop.CommentId);

        var hideForeignResponse = await PostModerationAsync(
            $"/api/moderation/comments/{foreignDrop.CommentId}/hide",
            dropMaker.Id);
        Assert.Equal(HttpStatusCode.Forbidden, hideForeignResponse.StatusCode);

        var depublishForeignArtResponse = await PostModerationAsync(
            $"/api/moderation/art-pieces/{foreignDrop.ArtPieceId}/depublish",
            dropMaker.Id);
        Assert.Equal(HttpStatusCode.Forbidden, depublishForeignArtResponse.StatusCode);
    }

    private sealed record ArtPieceResponseDto(Guid Id, bool IsPublished);

    private sealed record DropResponseDto(Guid Id);

    private sealed record ReportedDropContext(Guid ArtPieceId, Guid DropId, Guid CommentId);

    private async Task<UserAccount> CreateUserAsync(UserRole role, string userName)
    {
        using var scope = _factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<UrbanArtDbContext>();
        var email = $"{userName}@example.com";
        var user = UserAccount.CreateLocal(
            email,
            userName,
            role,
            "hashed-password",
            approved: true);
        user.MarkEmailVerified();
        await dbContext.UserAccounts.AddAsync(user);
        await dbContext.SaveChangesAsync();
        return user;
    }

    private async Task<ReportedDropContext> CreateReportedCommentAsync(
        Guid artistId,
        string artTitle,
        string nickname,
        string commentText,
        Guid? dropMakerId = null)
    {
        var createArtResponse = await _client.PostAsJsonAsync(
            "/api/art-pieces/",
            new
            {
                artistId,
                title = artTitle,
                description = "This artwork description is intentionally long enough for artist moderation testing.",
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
                dropMakerId = dropMakerId ?? Guid.NewGuid(),
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
            new CreateCommentRequest(drop!.Id, null, nickname, commentText));
        await EnsureSuccessWithBodyAsync(createCommentResponse);
        var comment = await createCommentResponse.Content.ReadFromJsonAsync<CommentResponse>();
        Assert.NotNull(comment);

        var reportCommentResponse = await _client.PostAsJsonAsync(
            $"/api/comments/{comment!.Id}/report",
            new ReportCommentRequest("Comment contains abuse"));
        await EnsureSuccessWithBodyAsync(reportCommentResponse);

        return new ReportedDropContext(artPiece.Id, drop.Id, comment.Id);
    }

    private async Task<ModerationQueueResponse?> GetModerationQueueAsync(Guid actorUserId)
    {
        var request = new HttpRequestMessage(HttpMethod.Get, "/api/moderation/reports");
        request.Headers.Add("X-Actor-User-Id", actorUserId.ToString());

        using var response = await _client.SendAsync(request);
        await EnsureSuccessWithBodyAsync(response);
        return await response.Content.ReadFromJsonAsync<ModerationQueueResponse>();
    }

    private Task<HttpResponseMessage> PostModerationAsync(string path, Guid actorUserId)
    {
        var request = new HttpRequestMessage(HttpMethod.Post, path);
        request.Headers.Add("X-Actor-User-Id", actorUserId.ToString());
        return _client.SendAsync(request);
    }

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
