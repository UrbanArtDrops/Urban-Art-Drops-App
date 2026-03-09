namespace UrbanArtDropFinder.Domain.Comments;

public sealed class DropComment
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DropId { get; set; }
    public Guid? AuthorUserId { get; set; }
    public string? AnonymousNickname { get; set; }
    public string Content { get; set; } = string.Empty;
    public bool IsReported { get; private set; }
    public bool IsHidden { get; private set; }
    public DateTimeOffset CreatedAtUtc { get; set; } = DateTimeOffset.UtcNow;

    public void Report() => IsReported = true;

    public void Hide() => IsHidden = true;
}
