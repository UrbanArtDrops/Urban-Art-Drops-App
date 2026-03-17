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

    [Fact]
    public void Publish_WhenModelArtPieceHasNoAssetFile_ThrowsValidationException()
    {
        var artPiece = ArtPiece.Create(
            Guid.NewGuid(),
            "Crystal Owl",
            "This description is definitely long enough.",
            ArtPieceAssetKind.Model3d);
        artPiece.AddPhoto([1, 2, 3], "image/png");

        Assert.Throws<DomainValidationException>(() => artPiece.Publish());
    }

    [Fact]
    public void SetAssetFile_WhenAssetKindIsModel3d_AllowsPublishing()
    {
        var artPiece = ArtPiece.Create(
            Guid.NewGuid(),
            "Crystal Owl",
            "This description is definitely long enough.",
            ArtPieceAssetKind.Model3d);
        artPiece.AddPhoto([1, 2, 3], "image/png");
        artPiece.SetAssetFile([7, 8, 9], "model/gltf-binary", "crystal-owl.glb");

        artPiece.Publish();

        Assert.True(artPiece.IsPublished);
        Assert.NotNull(artPiece.AssetFile);
        Assert.Equal("crystal-owl.glb", artPiece.AssetFile!.FileName);
    }

    [Fact]
    public void ReportAndDismissReport_UpdateModerationFlags()
    {
        var artPiece = ArtPiece.Create(
            Guid.NewGuid(),
            "Crystal Owl",
            "This description is definitely long enough.",
            ArtPieceAssetKind.Image);

        artPiece.Report("Needs review", DateTimeOffset.UtcNow);
        Assert.True(artPiece.IsReported);
        Assert.Equal("Needs review", artPiece.ReportReason);
        Assert.NotNull(artPiece.ReportedAtUtc);

        artPiece.DismissReport();
        Assert.False(artPiece.IsReported);
        Assert.Null(artPiece.ReportReason);
        Assert.Null(artPiece.ReportedAtUtc);
    }
}
