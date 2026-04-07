using UrbanArtDropFinder.Application.Abstractions;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class FakeSocialMediaPublisher : ISocialMediaPublisher
{
    public Func<SocialMediaPublishRequest, CancellationToken, Task<SocialMediaPublishResult>> Handler { get; set; } =
        static (request, _) => Task.FromResult(new SocialMediaPublishResult(
            SocialMediaPublishOutcome.Published,
            $"Published {request.Channel}.",
            $"external-{request.Channel.ToLowerInvariant()}"));

    public List<SocialMediaPublishRequest> Requests { get; } = [];

    public Task<SocialMediaPublishResult> PublishDropAsync(
        SocialMediaPublishRequest request,
        CancellationToken cancellationToken)
    {
        Requests.Add(request);
        return Handler(request, cancellationToken);
    }
}
