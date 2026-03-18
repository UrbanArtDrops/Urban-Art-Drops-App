namespace UrbanArtDropFinder.Domain.Users;

public sealed class UserProfileImage
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid UserAccountId { get; set; }
    public byte[] BinaryData { get; set; } = [];
    public string ContentType { get; set; } = "application/octet-stream";
}
