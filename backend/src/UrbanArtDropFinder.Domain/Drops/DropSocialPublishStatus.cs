namespace UrbanArtDropFinder.Domain.Drops;

/// <summary>Stores the latest publication attempt for one drop and one social media channel.</summary>
public sealed class DropSocialPublishStatus
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DropId { get; set; }
    public string Channel { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? ExternalPostId { get; set; }
    public DateTimeOffset LastAttemptAtUtc { get; set; }
    public DateTimeOffset? PublishedAtUtc { get; set; }
}
