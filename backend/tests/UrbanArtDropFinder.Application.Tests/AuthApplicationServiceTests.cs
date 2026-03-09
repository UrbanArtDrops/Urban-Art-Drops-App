using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Application.Auth;
using UrbanArtDropFinder.Contracts.Auth;
using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Application.Tests;

public sealed class AuthApplicationServiceTests
{
    [Fact]
    public async Task RegisterLocalAsync_WithAdminRole_ReturnsFailure()
    {
        var service = CreateService(new InMemoryUserAccountStore(), new FakePasswordHasher(), new FixedClock());

        var result = await service.RegisterLocalAsync(
            new RegisterLocalRequest("admin@example.com", "admin", "Aaaaaaaaaaaaaaa!", UserRole.Admin),
            CancellationToken.None);

        Assert.False(result.Success);
    }

    [Fact]
    public async Task LoginLocalAsync_AfterFailedAttempt_SetsRetryAfter()
    {
        var store = new InMemoryUserAccountStore();
        var hasher = new FakePasswordHasher();
        var clock = new FixedClock();
        var service = CreateService(store, hasher, clock);

        var user = UserAccount.CreateLocal("hunter@example.com", "hunter", UserRole.Hunter, hasher.Hash("Aaaaaaaaaaaaaaa!"), true);
        user.MarkEmailVerified();
        await store.AddAsync(user, null, CancellationToken.None);

        var result = await service.LoginLocalAsync(new LoginLocalRequest("hunter@example.com", "wrong-password"), CancellationToken.None);

        Assert.False(result.Success);
        Assert.NotNull(result.RetryAfterUtc);
    }

    private static AuthApplicationService CreateService(IUserAccountStore store, IPasswordHasher hasher, IClock clock)
    {
        return new AuthApplicationService(store, hasher, clock);
    }

    private sealed class InMemoryUserAccountStore : IUserAccountStore
    {
        private readonly List<UserAccount> _users = [];
        private readonly List<(string Provider, string Subject, Guid UserId)> _providerLinks = [];

        public Task<bool> UserNameExistsAsync(string userName, CancellationToken cancellationToken)
            => Task.FromResult(_users.Any(x => string.Equals(x.UserName, userName, StringComparison.OrdinalIgnoreCase)));

        public Task<bool> EmailExistsAsync(string email, CancellationToken cancellationToken)
            => Task.FromResult(_users.Any(x => string.Equals(x.Email, email, StringComparison.OrdinalIgnoreCase)));

        public Task<UserAccount?> GetByEmailAsync(string email, CancellationToken cancellationToken)
            => Task.FromResult(_users.FirstOrDefault(x => string.Equals(x.Email, email, StringComparison.OrdinalIgnoreCase)));

        public Task<UserAccount?> GetByProviderSubjectAsync(string provider, string providerSubject, CancellationToken cancellationToken)
        {
            var link = _providerLinks.FirstOrDefault(x =>
                string.Equals(x.Provider, provider, StringComparison.OrdinalIgnoreCase) &&
                string.Equals(x.Subject, providerSubject, StringComparison.Ordinal));

            return Task.FromResult(_users.FirstOrDefault(x => x.Id == link.UserId));
        }

        public Task AddAsync(UserAccount user, string? providerSubject, CancellationToken cancellationToken)
        {
            _users.Add(user);
            if (user.IsProviderAccount && !string.IsNullOrWhiteSpace(user.Provider) && !string.IsNullOrWhiteSpace(providerSubject))
            {
                _providerLinks.Add((user.Provider, providerSubject, user.Id));
            }

            return Task.CompletedTask;
        }

        public Task SaveChangesAsync(CancellationToken cancellationToken) => Task.CompletedTask;

        public Task<ISet<string>> GetRegisteredUserNamesAsync(CancellationToken cancellationToken)
            => Task.FromResult<ISet<string>>(new HashSet<string>(_users.Select(x => x.UserName), StringComparer.OrdinalIgnoreCase));
    }

    private sealed class FakePasswordHasher : IPasswordHasher
    {
        public string Hash(string password) => "HASH:" + password;

        public bool Verify(string hashedPassword, string providedPassword) => hashedPassword == Hash(providedPassword);
    }

    private sealed class FixedClock : IClock
    {
        public DateTimeOffset UtcNow => DateTimeOffset.Parse("2026-03-09T10:00:00+00:00");
    }
}
