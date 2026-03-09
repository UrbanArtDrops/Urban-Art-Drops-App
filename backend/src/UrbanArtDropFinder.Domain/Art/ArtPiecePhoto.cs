namespace UrbanArtDropFinder.Domain.Art;

public sealed class ArtPiecePhoto
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ArtPieceId { get; set; }
    public byte[] BinaryData { get; set; } = [];
    public string ContentType { get; set; } = "application/octet-stream";
}
