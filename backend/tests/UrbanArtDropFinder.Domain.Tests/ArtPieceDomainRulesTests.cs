using UrbanArtDropFinder.Domain.Art;
using UrbanArtDropFinder.Domain.Shared;

namespace UrbanArtDropFinder.Domain.Tests;

public sealed class ArtPieceDomainRulesTests
{
    [Fact]
    public void UpdateDetails_WhenValuesAreValid_UpdatesArtistAndAssetKind()
    {
        var artPiece = ArtPiece.Create(
            Guid.NewGuid(),
            "Crystal Owl",
            "This description is definitely long enough.",
            ArtPieceAssetKind.Image);

        var updatedArtistId = Guid.NewGuid();

        artPiece.UpdateDetails(
            updatedArtistId,
            "Steel Fox",
            "This updated description is also long enough.",
            ArtPieceAssetKind.Model3d);

        Assert.Equal(updatedArtistId, artPiece.ArtistId);
        Assert.Equal("Steel Fox", artPiece.Title);
        Assert.Equal("This updated description is also long enough.", artPiece.Description);
        Assert.Equal(ArtPieceAssetKind.Model3d, artPiece.AssetKind);
    }

    [Fact]
    public void UpdateDetails_WhenArtistIsMissing_ThrowsValidationException()
    {
        var artPiece = ArtPiece.Create(
            Guid.NewGuid(),
            "Crystal Owl",
            "This description is definitely long enough.",
            ArtPieceAssetKind.Image);

        Assert.Throws<DomainValidationException>(() =>
            artPiece.UpdateDetails(
                Guid.Empty,
                "Steel Fox",
                "This updated description is also long enough.",
                ArtPieceAssetKind.Model3d));
    }
}
