using UrbanArtDropFinder.Domain.Art;

namespace UrbanArtDropFinder.Contracts.Art;

public sealed record CreateArtPieceRequest(
    Guid ArtistId,
    string Title,
    string Description,
    ArtPieceAssetKind AssetKind,
    IReadOnlyCollection<string> PhotoUrls);

public sealed record UpdateArtPieceRequest(string Title, string Description, IReadOnlyCollection<string> PhotoUrls);
