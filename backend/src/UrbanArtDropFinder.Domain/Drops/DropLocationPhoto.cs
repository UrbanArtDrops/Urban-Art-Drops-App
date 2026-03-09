namespace UrbanArtDropFinder.Domain.Drops;

public sealed class DropLocationPhoto
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DropId { get; set; }
    public byte[] BinaryData { get; set; } = [];
    public string ContentType { get; set; } = "application/octet-stream";
}
