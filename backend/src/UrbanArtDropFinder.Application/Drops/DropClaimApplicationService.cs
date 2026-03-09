using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Domain.Drops;
using UrbanArtDropFinder.Domain.Shared;

namespace UrbanArtDropFinder.Application.Drops;

public sealed class DropClaimApplicationService
{
    private readonly IUserAccountStore _userAccountStore;
    private readonly IClock _clock;

    public DropClaimApplicationService(IUserAccountStore userAccountStore, IClock clock)
    {
        _userAccountStore = userAccountStore;
        _clock = clock;
    }

    public async Task ClaimAsync(
        Drop drop,
        DropItem dropItem,
        Guid? hunterUserId,
        string? anonymousNickname,
        CancellationToken cancellationToken)
    {
        var registeredUserNames = await _userAccountStore.GetRegisteredUserNamesAsync(cancellationToken);

        DropClaimPolicy.ValidateClaim(
            drop,
            dropItem,
            hunterUserId,
            anonymousNickname,
            registeredUserNames);

        dropItem.MarkClaimed(hunterUserId, anonymousNickname, _clock.UtcNow);
    }
}
