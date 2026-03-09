namespace UrbanArtDropFinder.Domain.Art;

public sealed class ArtPiecePhoto
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid ArtPieceId { get; set; }
    public string Url { get; set; } = string.Empty;
}
