namespace UrbanArtDropFinder.Domain.Art;

public sealed class ArtPieceAssetFile
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ArtPieceId { get; set; }
    public byte[] BinaryData { get; set; } = [];
    public string ContentType { get; set; } = "application/octet-stream";
    public string FileName { get; set; } = "asset.bin";
}
