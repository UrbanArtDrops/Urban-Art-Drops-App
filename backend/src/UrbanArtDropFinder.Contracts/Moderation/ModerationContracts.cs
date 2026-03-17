namespace UrbanArtDropFinder.Contracts.Moderation;

public sealed record ModerationQueueResponse(
    IReadOnlyCollection<ReportedCommentResponse> Comments,
    IReadOnlyCollection<ReportedArtPieceResponse> ArtPieces);

public sealed record ReportedCommentResponse(
    Guid Id,
    Guid DropId,
    string DropTitle,
    Guid? AuthorUserId,
    string AuthorDisplayName,
    string Content,
    string? ReportReason,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset? ReportedAtUtc);

public sealed record ReportedArtPieceResponse(
    Guid Id,
    Guid ArtistId,
    string Title,
    string ArtistDisplayName,
    bool IsPublished,
    string? ReportReason,
    DateTimeOffset? ReportedAtUtc,
    string? PreviewImageUrl);
