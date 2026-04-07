namespace UrbanArtDropFinder.Application.Abstractions;

/// <summary>Publishes drop announcements to configured social media providers.</summary>
public interface ISocialMediaPublisher
{
    /// <summary>Attempts to publish a drop announcement for a single social media channel.</summary>
    Task<SocialMediaPublishResult> PublishDropAsync(
        SocialMediaPublishRequest request,
        CancellationToken cancellationToken);
}

/// <summary>Contains the drop metadata required for a social media publish attempt.</summary>
public sealed record SocialMediaPublishRequest(
    Guid DropId,
    string Channel,
    string ArtPieceTitle,
    string DropMakerDisplayName,
    string? DropMakerComment,
    string? PublicDropUrl,
    IReadOnlyCollection<string> ImageUrls);

/// <summary>Represents the provider result of a social media publish attempt.</summary>
public sealed record SocialMediaPublishResult(
    SocialMediaPublishOutcome Outcome,
    string Message,
    string? ExternalPostId);

/// <summary>Describes the outcome category of a social media publish attempt.</summary>
public enum SocialMediaPublishOutcome
{
    Published = 0,
    Skipped = 1,
    Failed = 2
}
