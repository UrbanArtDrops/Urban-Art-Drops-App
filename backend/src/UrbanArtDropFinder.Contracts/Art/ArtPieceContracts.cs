using UrbanArtDropFinder.Domain.Art;

namespace UrbanArtDropFinder.Contracts.Art;

public sealed record CreateArtPieceRequest(
    Guid ArtistId,
    string Title,
    string? Subtitle,
    string Description,
    ArtPieceAssetKind AssetKind,
    IReadOnlyCollection<string> PhotoUrls,
    string? AssetSource,
    string? AssetFileName);

public sealed record UpdateArtPieceRequest(
    Guid ArtistId,
    string Title,
    string? Subtitle,
    string Description,
    ArtPieceAssetKind AssetKind,
    IReadOnlyCollection<string> PhotoUrls,
    string? AssetSource,
    string? AssetFileName);

public sealed record ReportArtPieceRequest(string? Reason);
