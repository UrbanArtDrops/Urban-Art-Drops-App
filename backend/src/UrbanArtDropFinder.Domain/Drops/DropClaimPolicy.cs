using UrbanArtDropFinder.Domain.Shared;

namespace UrbanArtDropFinder.Domain.Drops;

public static class DropClaimPolicy
{
    public static void ValidateClaim(
        Drop drop,
        DropItem targetItem,
        Guid? hunterUserId,
        string? anonymousNickname,
        ISet<string> registeredUserNames)
    {
        if (targetItem.IsClaimed)
        {
            throw new DomainValidationException("This item has already been claimed.");
        }

        if (hunterUserId.HasValue)
        {
            var alreadyClaimed = drop.Items.Any(x => x.ClaimedByUserId == hunterUserId);
            if (alreadyClaimed)
            {
                throw new DomainValidationException("Hunter can only claim one item per drop.");
            }

            return;
        }

        var normalizedNickname = anonymousNickname?.Trim();
        if (string.IsNullOrWhiteSpace(normalizedNickname))
        {
            throw new DomainValidationException("Anonymous claims require a nickname.");
        }

        if (registeredUserNames.Contains(normalizedNickname, StringComparer.OrdinalIgnoreCase))
        {
            throw new DomainValidationException("Anonymous nickname conflicts with a registered user name.");
        }

        var alreadyClaimedByNickname = drop.Items.Any(x =>
            x.ClaimedByAnonymousNickname != null &&
            string.Equals(x.ClaimedByAnonymousNickname, normalizedNickname, StringComparison.OrdinalIgnoreCase));

        if (alreadyClaimedByNickname)
        {
            throw new DomainValidationException("Anonymous nickname can only claim one item per drop.");
        }
    }
}
