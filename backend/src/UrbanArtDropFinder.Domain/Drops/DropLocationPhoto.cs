namespace UrbanArtDropFinder.Domain.Drops;

public sealed class DropLocationPhoto
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DropId { get; set; }
    public string Url { get; set; } = string.Empty;
}
