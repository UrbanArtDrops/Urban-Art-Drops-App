using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using UrbanArtDropFinder.Contracts.Art;
using UrbanArtDropFinder.Contracts.Comments;
using UrbanArtDropFinder.Contracts.Moderation;
using UrbanArtDropFinder.Domain.Art;
using UrbanArtDropFinder.Domain.Configuration;
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
        var artist = await CreateUserAsync(UserRole.Artist, $"artist.flow.{uniqueId}");
        var reporter = await CreateUserAsync(UserRole.Hunter, $"reporter.flow.{uniqueId}");
        await ConfigureSmtpAlertsAsync();
        var createArtResponse = await _client.PostAuthorizedAsJsonAsync(
            "/api/art-pieces/",
            new
            {
                artistId = artist.Id,
                title = $"Reported Piece {uniqueId}",
                description = "This artwork description is intentionally long enough for moderation testing.",
                assetKind = ArtPieceAssetKind.Image,
                photoUrls = new[] { SamplePngDataUrl },
                assetSource = (string?)null,
                assetFileName = (string?)null
            },
            artist.AccessToken);

        await EnsureSuccessWithBodyAsync(createArtResponse);
        var artPiece = await createArtResponse.Content.ReadFromJsonAsync<ArtPieceResponseDto>();
        Assert.NotNull(artPiece);

        var publishArtResponse = await _client.PostAuthorizedAsync($"/api/art-pieces/{artPiece!.Id}/publish", artist.AccessToken);
        await EnsureSuccessWithBodyAsync(publishArtResponse);

        var createDropResponse = await _client.PostAuthorizedAsJsonAsync(
            "/api/drops/",
            new
            {
                artPieceId = artPiece.Id,
                dropMakerId = artist.Id,
                isStationary = true,
                portableItemCount = (int?)null,
                latitude = 52.52,
                longitude = 13.405,
                locationPhotoUrls = new[] { SamplePngDataUrl },
                itemCount = 1
            },
            artist.AccessToken);

        await EnsureSuccessWithBodyAsync(createDropResponse);
        var drop = await createDropResponse.Content.ReadFromJsonAsync<DropResponseDto>();
        Assert.NotNull(drop);

        var createCommentResponse = await _client.PostAuthorizedAsJsonAsync(
            "/api/comments/",
            new CreateCommentRequest(drop!.Id, null, "queue.user", "This comment should appear in the moderation queue."),
            reporter.AccessToken);
        await EnsureSuccessWithBodyAsync(createCommentResponse);
        var comment = await createCommentResponse.Content.ReadFromJsonAsync<CommentResponse>();
        Assert.NotNull(comment);

        var reportCommentResponse = await _client.PostAuthorizedAsJsonAsync(
            $"/api/comments/{comment!.Id}/report",
            new ReportCommentRequest("Comment contains abuse"),
            reporter.AccessToken);
        await EnsureSuccessWithBodyAsync(reportCommentResponse);

        var reportArtResponse = await _client.PostAuthorizedAsJsonAsync(
            $"/api/art-pieces/{artPiece.Id}/report",
            new ReportArtPieceRequest("Artwork needs content review"),
            reporter.AccessToken);
        await EnsureSuccessWithBodyAsync(reportArtResponse);
        Assert.NotNull(_factory.SmtpMailSender.LastRequest);
        Assert.Contains(moderator.Email, _factory.SmtpMailSender.LastRequest!.Value.Message.Recipients);
        Assert.Equal("TestSmtpPassword!123", _factory.SmtpMailSender.LastRequest.Value.DeliveryOptions.Password);

        var queueResponse = await GetModerationQueueAsync(moderator.AccessToken);
        Assert.NotNull(queueResponse);
        Assert.Contains(queueResponse!.Comments, entry => entry.Id == comment.Id && entry.DropId == drop.Id);
        Assert.Contains(queueResponse.ArtPieces, entry => entry.Id == artPiece.Id && entry.IsPublished);

        var hideCommentResponse = await PostModerationAsync(
            $"/api/moderation/comments/{comment.Id}/hide",
            moderator.AccessToken);
        await EnsureSuccessWithBodyAsync(hideCommentResponse);

        var publicComments = await _client.GetFromJsonAsync<List<CommentResponse>>($"/api/comments/drop/{drop.Id}");
        Assert.NotNull(publicComments);
        Assert.DoesNotContain(publicComments!, entry => entry.Id == comment.Id);

        var depublishArtResponse = await PostModerationAsync(
            $"/api/moderation/art-pieces/{artPiece.Id}/depublish",
            moderator.AccessToken);
        await EnsureSuccessWithBodyAsync(depublishArtResponse);

        var reloadedArt = await _client.GetFromJsonAsync<ArtPieceResponseDto>($"/api/art-pieces/{artPiece.Id}");
        Assert.NotNull(reloadedArt);
        Assert.False(reloadedArt!.IsPublished);

        var clearedQueue = await GetModerationQueueAsync(moderator.AccessToken);
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
            artist,
            $"Own Queue Piece {uniqueId}",
            $"own-{uniqueId}",
            "This reported comment belongs to the actor.");
        var foreignDrop = await CreateReportedCommentAsync(
            otherArtist,
            $"Foreign Queue Piece {uniqueId}",
            $"foreign-{uniqueId}",
            "This reported comment belongs to another artist.");

        var queueResponse = await GetModerationQueueAsync(artist.AccessToken);

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
            artist,
            $"Own Action Piece {uniqueId}",
            $"own-action-{uniqueId}",
            "Own reported comment.");
        var foreignDrop = await CreateReportedCommentAsync(
            otherArtist,
            $"Foreign Action Piece {uniqueId}",
            $"foreign-action-{uniqueId}",
            "Foreign reported comment.");

        var hideOwnResponse = await PostModerationAsync(
            $"/api/moderation/comments/{ownDrop.CommentId}/hide",
            artist.AccessToken);
        await EnsureSuccessWithBodyAsync(hideOwnResponse);

        var ownPublicComments = await _client.GetFromJsonAsync<List<CommentResponse>>(
            $"/api/comments/drop/{ownDrop.DropId}");
        Assert.NotNull(ownPublicComments);
        Assert.DoesNotContain(ownPublicComments!, entry => entry.Id == ownDrop.CommentId);

        var hideForeignResponse = await PostModerationAsync(
            $"/api/moderation/comments/{foreignDrop.CommentId}/hide",
            artist.AccessToken);
        Assert.Equal(HttpStatusCode.Forbidden, hideForeignResponse.StatusCode);

        var depublishForeignArtResponse = await PostModerationAsync(
            $"/api/moderation/art-pieces/{foreignDrop.ArtPieceId}/depublish",
            artist.AccessToken);
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
            artist,
            $"Drop-Maker Queue Piece {uniqueId}",
            $"own-dropmaker-{uniqueId}",
            "This reported comment belongs to the drop-maker.",
            dropMaker);
        var foreignDrop = await CreateReportedCommentAsync(
            artist,
            $"Drop-Maker Foreign Piece {uniqueId}",
            $"foreign-dropmaker-{uniqueId}",
            "This reported comment belongs to another drop-maker.",
            otherDropMaker);

        var queueResponse = await GetModerationQueueAsync(dropMaker.AccessToken);

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
            artist,
            $"Own Drop-Maker Piece {uniqueId}",
            $"own-dropmaker-action-{uniqueId}",
            "Own reported comment for drop-maker.",
            dropMaker);
        var foreignDrop = await CreateReportedCommentAsync(
            artist,
            $"Foreign Drop-Maker Piece {uniqueId}",
            $"foreign-dropmaker-action-{uniqueId}",
            "Foreign reported comment for drop-maker.",
            otherDropMaker);

        var hideOwnResponse = await PostModerationAsync(
            $"/api/moderation/comments/{ownDrop.CommentId}/hide",
            dropMaker.AccessToken);
        await EnsureSuccessWithBodyAsync(hideOwnResponse);

        var ownPublicComments = await _client.GetFromJsonAsync<List<CommentResponse>>(
            $"/api/comments/drop/{ownDrop.DropId}");
        Assert.NotNull(ownPublicComments);
        Assert.DoesNotContain(ownPublicComments!, entry => entry.Id == ownDrop.CommentId);

        var hideForeignResponse = await PostModerationAsync(
            $"/api/moderation/comments/{foreignDrop.CommentId}/hide",
            dropMaker.AccessToken);
        Assert.Equal(HttpStatusCode.Forbidden, hideForeignResponse.StatusCode);

        var depublishForeignArtResponse = await PostModerationAsync(
            $"/api/moderation/art-pieces/{foreignDrop.ArtPieceId}/depublish",
            dropMaker.AccessToken);
        Assert.Equal(HttpStatusCode.Forbidden, depublishForeignArtResponse.StatusCode);
    }

    [Fact]
    public async Task ModerationQueue_RejectsAnonymousAndUnprivilegedUsers()
    {
        var anonymousResponse = await _client.GetAsync("/api/moderation/reports");
        Assert.Equal(HttpStatusCode.Unauthorized, anonymousResponse.StatusCode);

        var hunter = await CreateUserAsync(UserRole.Hunter, $"hunter.moderation.{Guid.NewGuid():N}");
        var hunterResponse = await _client.GetAuthorizedAsync("/api/moderation/reports", hunter.AccessToken);
        Assert.Equal(HttpStatusCode.Forbidden, hunterResponse.StatusCode);
    }

    private sealed record ArtPieceResponseDto(Guid Id, bool IsPublished);

    private sealed record DropResponseDto(Guid Id);

    private sealed record ReportedDropContext(Guid ArtPieceId, Guid DropId, Guid CommentId);

    private Task<TestAuthUtilities.AuthenticatedTestUser> CreateUserAsync(UserRole role, string userName)
        => _factory.CreateAuthenticatedUserAsync(role, userName);

    private async Task ConfigureSmtpAlertsAsync()
    {
        using var scope = _factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<UrbanArtDbContext>();
        var configuration = await dbContext.AppConfigurations.SingleAsync();
        configuration.SmtpHost = "smtp.example.test";
        configuration.SmtpPort = 465;
        configuration.SmtpSecurityMode = SmtpSecurityMode.Tls;
        configuration.SmtpUserName = "mailer-user";
        configuration.SmtpUserEmail = "mailer@example.test";
        configuration.SmtpPasswordSecretName = "Smtp:Password";
        await dbContext.SaveChangesAsync();
    }

    private async Task<ReportedDropContext> CreateReportedCommentAsync(
        TestAuthUtilities.AuthenticatedTestUser artist,
        string artTitle,
        string nickname,
        string commentText,
        TestAuthUtilities.AuthenticatedTestUser? dropMaker = null)
    {
        var reporter = await CreateUserAsync(UserRole.Hunter, $"reporter.{Guid.NewGuid():N}");
        var dropActor = dropMaker ?? artist;
        var createArtResponse = await _client.PostAuthorizedAsJsonAsync(
            "/api/art-pieces/",
            new
            {
                artistId = artist.Id,
                title = artTitle,
                description = "This artwork description is intentionally long enough for artist moderation testing.",
                assetKind = ArtPieceAssetKind.Image,
                photoUrls = new[] { SamplePngDataUrl },
                assetSource = (string?)null,
                assetFileName = (string?)null
            },
            artist.AccessToken);
        await EnsureSuccessWithBodyAsync(createArtResponse);
        var artPiece = await createArtResponse.Content.ReadFromJsonAsync<ArtPieceResponseDto>();
        Assert.NotNull(artPiece);

        var publishArtResponse = await _client.PostAuthorizedAsync($"/api/art-pieces/{artPiece!.Id}/publish", artist.AccessToken);
        await EnsureSuccessWithBodyAsync(publishArtResponse);

        var createDropResponse = await _client.PostAuthorizedAsJsonAsync(
            "/api/drops/",
            new
            {
                artPieceId = artPiece.Id,
                dropMakerId = dropActor.Id,
                isStationary = true,
                portableItemCount = (int?)null,
                latitude = 52.52,
                longitude = 13.405,
                locationPhotoUrls = new[] { SamplePngDataUrl },
                itemCount = 1
            },
            dropActor.AccessToken);
        await EnsureSuccessWithBodyAsync(createDropResponse);
        var drop = await createDropResponse.Content.ReadFromJsonAsync<DropResponseDto>();
        Assert.NotNull(drop);

        var createCommentResponse = await _client.PostAuthorizedAsJsonAsync(
            "/api/comments/",
            new CreateCommentRequest(drop!.Id, null, nickname, commentText),
            reporter.AccessToken);
        await EnsureSuccessWithBodyAsync(createCommentResponse);
        var comment = await createCommentResponse.Content.ReadFromJsonAsync<CommentResponse>();
        Assert.NotNull(comment);

        var reportCommentResponse = await _client.PostAuthorizedAsJsonAsync(
            $"/api/comments/{comment!.Id}/report",
            new ReportCommentRequest("Comment contains abuse"),
            reporter.AccessToken);
        await EnsureSuccessWithBodyAsync(reportCommentResponse);

        return new ReportedDropContext(artPiece.Id, drop.Id, comment.Id);
    }

    private async Task<ModerationQueueResponse?> GetModerationQueueAsync(string accessToken)
    {
        using var response = await _client.GetAuthorizedAsync("/api/moderation/reports", accessToken);
        await EnsureSuccessWithBodyAsync(response);
        return await response.Content.ReadFromJsonAsync<ModerationQueueResponse>();
    }

    private Task<HttpResponseMessage> PostModerationAsync(string path, string accessToken)
        => _client.PostAuthorizedAsync(path, accessToken);

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
