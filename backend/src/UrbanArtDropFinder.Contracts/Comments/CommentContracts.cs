namespace UrbanArtDropFinder.Contracts.Comments;

public sealed record CreateCommentRequest(Guid DropId, Guid? AuthorUserId, string? AnonymousNickname, string Content);

public sealed record ReportCommentRequest(string? Reason);
