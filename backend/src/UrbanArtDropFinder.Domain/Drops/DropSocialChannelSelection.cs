using UrbanArtDropFinder.Domain.Shared;

namespace UrbanArtDropFinder.Domain.Drops;

public sealed class DropSocialChannelSelection
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DropId { get; set; }
    public string Channel { get; set; } = string.Empty;

    public static string NormalizeChannel(string? channel)
    {
        var normalized = channel?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(normalized))
        {
            throw new DomainValidationException("Social channel is required.");
        }

        if (normalized.Length > 64)
        {
            throw new DomainValidationException("Social channel must not exceed 64 characters.");
        }

        return normalized;
    }
}
