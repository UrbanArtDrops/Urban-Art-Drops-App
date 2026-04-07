using System.Net;
using System.Net.Http.Headers;
using Microsoft.Extensions.Configuration;
using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Infrastructure.Services;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class ConfiguredSocialMediaPublisherTests
{
    [Fact]
    public async Task PublishDropAsync_Facebook_UsesPageFeedPayload()
    {
        var handler = new RecordingHttpMessageHandler();
        handler.EnqueueResponse("""{"id":"page_123_post_456"}""");
        var publisher = CreatePublisher(
            handler,
            new Dictionary<string, string?>
            {
                ["SocialMedia:Providers:Facebook:Enabled"] = "true",
                ["SocialMedia:Providers:Facebook:AccessTokenSecretName"] = "SocialMedia:Facebook:Token",
                ["SocialMedia:Providers:Facebook:PageId"] = "page_123",
                ["SocialMedia:Providers:Facebook:ApiBaseUrl"] = "https://graph.test/v20.0",
                ["SocialMedia:Facebook:Token"] = "facebook-access-token"
            });

        var result = await publisher.PublishDropAsync(CreateRequest("Facebook"), CancellationToken.None);

        Assert.Equal(SocialMediaPublishOutcome.Published, result.Outcome);
        Assert.Equal("page_123_post_456", result.ExternalPostId);
        var request = Assert.Single(handler.Requests);
        Assert.Equal(HttpMethod.Post, request.Method);
        Assert.Equal("https://graph.test/v20.0/page_123/feed", request.RequestUri);
        Assert.Equal("Bearer", request.Authorization?.Scheme);
        Assert.Equal("facebook-access-token", request.Authorization?.Parameter);
        Assert.Contains("message=", request.Body, StringComparison.Ordinal);
        Assert.Contains("link=https%3A%2F%2Fapp.test%2Fhunter%2Fdrops%2F", request.Body, StringComparison.Ordinal);
    }

    [Fact]
    public async Task PublishDropAsync_Instagram_CreatesMediaContainerAndPublishesIt()
    {
        var handler = new RecordingHttpMessageHandler();
        handler.EnqueueResponse("""{"id":"container_123"}""");
        handler.EnqueueResponse("""{"id":"media_456"}""");
        var publisher = CreatePublisher(
            handler,
            new Dictionary<string, string?>
            {
                ["SocialMedia:Providers:Instagram:Enabled"] = "true",
                ["SocialMedia:Providers:Instagram:AccessTokenSecretName"] = "SocialMedia:Instagram:Token",
                ["SocialMedia:Providers:Instagram:BusinessAccountId"] = "ig_123",
                ["SocialMedia:Providers:Instagram:ApiBaseUrl"] = "https://graph.test/v20.0",
                ["SocialMedia:Instagram:Token"] = "instagram-access-token"
            });

        var result = await publisher.PublishDropAsync(CreateRequest("Instagram"), CancellationToken.None);

        Assert.Equal(SocialMediaPublishOutcome.Published, result.Outcome);
        Assert.Equal("media_456", result.ExternalPostId);
        Assert.Equal(2, handler.Requests.Count);
        Assert.Equal("https://graph.test/v20.0/ig_123/media", handler.Requests[0].RequestUri);
        Assert.Contains("image_url=https%3A%2F%2Fapp.test%2Fapi%2Fmedia%2Fdrop-location-photos%2Fphoto-1", handler.Requests[0].Body, StringComparison.Ordinal);
        Assert.Contains("caption=", handler.Requests[0].Body, StringComparison.Ordinal);
        Assert.Equal("https://graph.test/v20.0/ig_123/media_publish", handler.Requests[1].RequestUri);
        Assert.Contains("creation_id=container_123", handler.Requests[1].Body, StringComparison.Ordinal);
    }

    [Fact]
    public async Task PublishDropAsync_TikTok_UsesContentPostingPhotoPayload()
    {
        var handler = new RecordingHttpMessageHandler();
        handler.EnqueueResponse("""{"data":{"publish_id":"p_pub_url~v2.123"},"error":{"code":"ok"}}""");
        var publisher = CreatePublisher(
            handler,
            new Dictionary<string, string?>
            {
                ["SocialMedia:Providers:TikTok:Enabled"] = "true",
                ["SocialMedia:Providers:TikTok:AccessTokenSecretName"] = "SocialMedia:TikTok:Token",
                ["SocialMedia:Providers:TikTok:ApiBaseUrl"] = "https://open.tiktokapis.test",
                ["SocialMedia:Providers:TikTok:PrivacyLevel"] = "PUBLIC_TO_EVERYONE",
                ["SocialMedia:TikTok:Token"] = "tiktok-access-token"
            });

        var result = await publisher.PublishDropAsync(CreateRequest("TikTok"), CancellationToken.None);

        Assert.Equal(SocialMediaPublishOutcome.Published, result.Outcome);
        Assert.Equal("p_pub_url~v2.123", result.ExternalPostId);
        var request = Assert.Single(handler.Requests);
        Assert.Equal("https://open.tiktokapis.test/v2/post/publish/content/init/", request.RequestUri);
        Assert.Equal("application/json", request.ContentType?.MediaType);
        Assert.Contains("\"post_mode\":\"DIRECT_POST\"", request.Body, StringComparison.Ordinal);
        Assert.Contains("\"media_type\":\"PHOTO\"", request.Body, StringComparison.Ordinal);
        Assert.Contains("\"photo_images\":[\"https://app.test/api/media/drop-location-photos/photo-1\"]", request.Body, StringComparison.Ordinal);
    }

    [Fact]
    public async Task PublishDropAsync_TransientFailures_AreRetriedAndOpenCircuit()
    {
        var handler = new RecordingHttpMessageHandler();
        handler.EnqueueResponse("""{"error":"temporary"}""", HttpStatusCode.ServiceUnavailable);
        handler.EnqueueResponse("""{"error":"temporary"}""", HttpStatusCode.ServiceUnavailable);
        handler.EnqueueResponse("""{"error":"temporary"}""", HttpStatusCode.ServiceUnavailable);
        var publisher = CreatePublisher(
            handler,
            new Dictionary<string, string?>
            {
                ["SocialMedia:Retry:MaxAttempts"] = "1",
                ["SocialMedia:CircuitBreaker:FailureThreshold"] = "1",
                ["SocialMedia:CircuitBreaker:BreakDurationSeconds"] = "60",
                ["SocialMedia:Providers:FacebookCircuit:Enabled"] = "true",
                ["SocialMedia:Providers:FacebookCircuit:ProviderKind"] = "Facebook",
                ["SocialMedia:Providers:FacebookCircuit:AccessTokenSecretName"] = "SocialMedia:Facebook:Token",
                ["SocialMedia:Providers:FacebookCircuit:PageId"] = "page_123",
                ["SocialMedia:Providers:FacebookCircuit:ApiBaseUrl"] = "https://graph.test/v20.0",
                ["SocialMedia:Facebook:Token"] = "facebook-access-token"
            });

        var firstResult = await publisher.PublishDropAsync(CreateRequest("FacebookCircuit"), CancellationToken.None);
        var secondResult = await publisher.PublishDropAsync(CreateRequest("FacebookCircuit"), CancellationToken.None);

        Assert.Equal(SocialMediaPublishOutcome.Failed, firstResult.Outcome);
        Assert.Equal(SocialMediaPublishOutcome.Skipped, secondResult.Outcome);
        Assert.Contains("circuit breaker is open", secondResult.Message, StringComparison.OrdinalIgnoreCase);
        Assert.Single(handler.Requests);
    }

    private static ConfiguredSocialMediaPublisher CreatePublisher(
        RecordingHttpMessageHandler handler,
        Dictionary<string, string?> configurationValues)
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(configurationValues)
            .Build();
        var httpClient = new HttpClient(handler);
        return new ConfiguredSocialMediaPublisher(
            configuration,
            new SingleHttpClientFactory(httpClient),
            new ManualClock());
    }

    private static SocialMediaPublishRequest CreateRequest(string channel) => new(
        Guid.Parse("11111111-1111-1111-1111-111111111111"),
        channel,
        "Signal Bloom",
        "Drop Maker",
        "Find the signal in the city.",
        "https://app.test/hunter/drops/11111111-1111-1111-1111-111111111111",
        ["https://app.test/api/media/drop-location-photos/photo-1"]);

    private sealed class RecordingHttpMessageHandler : HttpMessageHandler
    {
        private readonly Queue<(string Body, HttpStatusCode StatusCode)> _responses = new();

        public List<RecordedRequest> Requests { get; } = [];

        public void EnqueueResponse(string body, HttpStatusCode statusCode = HttpStatusCode.OK) =>
            _responses.Enqueue((body, statusCode));

        protected override async Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request,
            CancellationToken cancellationToken)
        {
            var body = request.Content is null
                ? string.Empty
                : await request.Content.ReadAsStringAsync(cancellationToken);
            Requests.Add(new RecordedRequest(
                request.Method,
                request.RequestUri?.ToString() ?? string.Empty,
                request.Headers.Authorization,
                request.Content?.Headers.ContentType,
                body));

            var response = _responses.Count == 0
                ? (Body: "{}", StatusCode: HttpStatusCode.OK)
                : _responses.Dequeue();
            return new HttpResponseMessage(response.StatusCode)
            {
                Content = new StringContent(response.Body)
            };
        }
    }

    private sealed record RecordedRequest(
        HttpMethod Method,
        string RequestUri,
        AuthenticationHeaderValue? Authorization,
        MediaTypeHeaderValue? ContentType,
        string Body);

    private sealed class SingleHttpClientFactory(HttpClient httpClient) : IHttpClientFactory
    {
        public HttpClient CreateClient(string name) => httpClient;
    }

    private sealed class ManualClock : IClock
    {
        public DateTimeOffset UtcNow { get; set; } = new(2026, 4, 7, 12, 0, 0, TimeSpan.Zero);
    }
}
