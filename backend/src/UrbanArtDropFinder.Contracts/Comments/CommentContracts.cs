namespace UrbanArtDropFinder.Contracts.Comments;

public sealed record CreateCommentRequest(Guid DropId, Guid? AuthorUserId, string? AnonymousNickname, string Content);

public sealed record ReportCommentRequest(string? Reason);

public sealed record CommentResponse(
    Guid Id,
    Guid DropId,
    Guid? AuthorUserId,
    string? AuthorDisplayName,
    string? AnonymousNickname,
    string Content,
    bool IsReported,
    bool IsHidden,
    string? ReportReason,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset? ReportedAtUtc);
