using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Application.Drops;
using UrbanArtDropFinder.Domain.Drops;
using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Application.Tests;

public sealed class DropClaimApplicationServiceTests
{
    private static readonly byte[] SamplePhotoBytes = [1, 2, 3];

    [Fact]
    public async Task ClaimAsync_WithAnonymousNickname_ClaimsItem()
    {
        var store = new InMemoryStore();
        var service = new DropClaimApplicationService(store, new FixedClock());

        var drop = Drop.Create(Guid.NewGuid(), Guid.NewGuid(), true, null);
        drop.SetLocation(50, 8);
        drop.AddLocationPhoto(SamplePhotoBytes, "image/jpeg");
        drop.AddItem(Guid.NewGuid().ToString("N"));
        var item = drop.Items.First();

        await service.ClaimAsync(drop, item, null, "visitor-one", CancellationToken.None);

        Assert.True(item.IsClaimed);
    }

    private sealed class InMemoryStore : IUserAccountStore
    {
        public Task<bool> UserNameExistsAsync(string userName, CancellationToken cancellationToken) => Task.FromResult(false);

        public Task<bool> EmailExistsAsync(string email, CancellationToken cancellationToken) => Task.FromResult(false);

        public Task<UserAccount?> GetByEmailAsync(string email, CancellationToken cancellationToken) => Task.FromResult<UserAccount?>(null);

        public Task<UserAccount?> GetByIdAsync(Guid userId, CancellationToken cancellationToken) => Task.FromResult<UserAccount?>(null);

        public Task<UserAccount?> GetByProviderSubjectAsync(string provider, string providerSubject, CancellationToken cancellationToken) => Task.FromResult<UserAccount?>(null);

        public Task AddAsync(UserAccount user, string? providerSubject, CancellationToken cancellationToken) => Task.CompletedTask;

        public Task SaveChangesAsync(CancellationToken cancellationToken) => Task.CompletedTask;

        public Task<ISet<string>> GetRegisteredUserNamesAsync(CancellationToken cancellationToken)
            => Task.FromResult<ISet<string>>(new HashSet<string>(StringComparer.OrdinalIgnoreCase));
    }

    private sealed class FixedClock : IClock
    {
        public DateTimeOffset UtcNow => DateTimeOffset.Parse("2026-03-09T10:00:00+00:00");
    }
}
