using UrbanArtDropFinder.Domain.Shared;

namespace UrbanArtDropFinder.Domain.Drops;

public sealed class DropItem
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid DropId { get; set; }
    public string QrToken { get; set; } = string.Empty;
    public bool IsClaimed { get; private set; }
    public Guid? ClaimedByUserId { get; private set; }
    public string? ClaimedByAnonymousNickname { get; private set; }
    public DateTimeOffset? ClaimedAtUtc { get; private set; }

    public void MarkClaimed(Guid? userId, string? anonymousNickname, DateTimeOffset nowUtc)
    {
        if (IsClaimed)
        {
            throw new DomainValidationException("Drop item is already claimed.");
        }

        if (!userId.HasValue && string.IsNullOrWhiteSpace(anonymousNickname))
        {
            throw new DomainValidationException("Claim requires either a user id or anonymous nickname.");
        }

        IsClaimed = true;
        ClaimedByUserId = userId;
        ClaimedByAnonymousNickname = anonymousNickname?.Trim();
        ClaimedAtUtc = nowUtc;
    }
}
