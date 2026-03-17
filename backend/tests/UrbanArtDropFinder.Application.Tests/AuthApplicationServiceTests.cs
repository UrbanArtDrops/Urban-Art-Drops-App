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
    public async Task RegisterLocalAsync_WithHunterRole_AutoApprovesAndReturnsStoredIdentity()
    {
        var store = new InMemoryUserAccountStore();
        var service = CreateService(store, new FakePasswordHasher(), new FixedClock());

        var result = await service.RegisterLocalAsync(
            new RegisterLocalRequest("hunter@example.com", "hunter", "Aaaaaaaaaaaaaaa!", UserRole.Hunter),
            CancellationToken.None);

        Assert.True(result.Success);
        Assert.Equal(UserRole.Hunter, result.Role);
        Assert.Equal("hunter", result.UserName);
        Assert.Equal("hunter@example.com", result.Email);

        var createdUser = await store.GetByEmailAsync("hunter@example.com", CancellationToken.None);
        Assert.NotNull(createdUser);
        Assert.True(createdUser!.IsApproved);
    }

    [Fact]
    public async Task RegisterLocalAsync_WithArtistRole_CreatesPendingApprovalAccount()
    {
        var store = new InMemoryUserAccountStore();
        var service = CreateService(store, new FakePasswordHasher(), new FixedClock());

        var result = await service.RegisterLocalAsync(
            new RegisterLocalRequest("artist@example.com", "artist", "Aaaaaaaaaaaaaaa!", UserRole.Artist),
            CancellationToken.None);

        Assert.True(result.Success);
        Assert.Equal(UserRole.Artist, result.Role);

        var createdUser = await store.GetByEmailAsync("artist@example.com", CancellationToken.None);
        Assert.NotNull(createdUser);
        Assert.False(createdUser!.IsApproved);
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

    [Fact]
    public async Task LoginLocalAsync_WithValidCredentials_ReturnsStoredRoleAndIdentity()
    {
        var store = new InMemoryUserAccountStore();
        var hasher = new FakePasswordHasher();
        var service = CreateService(store, hasher, new FixedClock());

        var user = UserAccount.CreateLocal("maker@example.com", "maker", UserRole.DropMaker, hasher.Hash("Aaaaaaaaaaaaaaa!"), approved: true);
        user.MarkEmailVerified();
        await store.AddAsync(user, null, CancellationToken.None);

        var result = await service.LoginLocalAsync(
            new LoginLocalRequest("maker@example.com", "Aaaaaaaaaaaaaaa!"),
            CancellationToken.None);

        Assert.True(result.Success);
        Assert.Equal(user.Id, result.UserId);
        Assert.Equal(UserRole.DropMaker, result.Role);
        Assert.Equal("maker", result.UserName);
        Assert.Equal("maker@example.com", result.Email);
        Assert.Null(result.RetryAfterUtc);
        Assert.Equal("test-access-token", result.AccessToken);
        Assert.Equal(DateTimeOffset.Parse("2026-03-09T18:00:00+00:00"), result.AccessTokenExpiresAtUtc);
        Assert.Equal("Bearer", result.TokenType);
    }

    [Fact]
    public async Task LoginLocalAsync_ForAdmin_RequiresMfaSetup()
    {
        var store = new InMemoryUserAccountStore();
        var hasher = new FakePasswordHasher();
        var service = CreateService(store, hasher, new FixedClock());

        var user = UserAccount.CreateLocal("admin@example.com", "admin", UserRole.Admin, hasher.Hash("Aaaaaaaaaaaaaaa!"), approved: true);
        user.MarkEmailVerified();
        await store.AddAsync(user, null, CancellationToken.None);

        var result = await service.LoginLocalAsync(
            new LoginLocalRequest("admin@example.com", "Aaaaaaaaaaaaaaa!"),
            CancellationToken.None);

        Assert.True(result.Success);
        Assert.True(result.RequiresMfa);
        Assert.True(result.MfaSetupRequired);
        Assert.NotNull(result.MfaChallengeToken);
        Assert.NotNull(result.MfaManualEntryKey);
        Assert.NotNull(result.MfaProvisioningUri);
        Assert.Null(result.AccessToken);
    }

    [Fact]
    public async Task LoginProviderAsync_ForModeratorWithEnabledMfa_ReturnsVerificationChallenge()
    {
        var store = new InMemoryUserAccountStore();
        var hasher = new FakePasswordHasher();
        var service = CreateService(store, hasher, new FixedClock());

        var user = UserAccount.CreateProvider(
            "moderator@example.com",
            "moderator",
            UserRole.Moderator,
            "microsoft",
            approved: true);
        user.EnableMfa("EXISTINGSECRET123");
        await store.AddAsync(user, "provider-subject", CancellationToken.None);

        var result = await service.LoginProviderAsync(
            new LoginProviderRequest("microsoft", "provider-subject", "moderator@example.com"),
            CancellationToken.None);

        Assert.True(result.Success);
        Assert.True(result.RequiresMfa);
        Assert.False(result.MfaSetupRequired);
        Assert.NotNull(result.MfaChallengeToken);
        Assert.Null(result.AccessToken);
    }

    [Fact]
    public async Task CompleteMfaChallengeAsync_ForSetup_EnablesMfaAndReturnsAccessToken()
    {
        var store = new InMemoryUserAccountStore();
        var hasher = new FakePasswordHasher();
        var service = CreateService(store, hasher, new FixedClock());

        var user = UserAccount.CreateLocal(
            "admin@example.com",
            "admin",
            UserRole.Admin,
            hasher.Hash("Aaaaaaaaaaaaaaa!"),
            approved: true);
        user.MarkEmailVerified();
        await store.AddAsync(user, null, CancellationToken.None);

        var loginResult = await service.LoginLocalAsync(
            new LoginLocalRequest("admin@example.com", "Aaaaaaaaaaaaaaa!"),
            CancellationToken.None);

        var mfaResult = await service.CompleteMfaChallengeAsync(
            new CompleteMfaChallengeRequest(loginResult.MfaChallengeToken!, "123456"),
            CancellationToken.None);

        Assert.True(mfaResult.Success);
        Assert.Equal("test-access-token", mfaResult.AccessToken);

        var storedUser = await store.GetByIdAsync(user.Id, CancellationToken.None);
        Assert.NotNull(storedUser);
        Assert.True(storedUser!.IsMfaEnabled);
        Assert.Equal("TESTSECRET123", storedUser.MfaSecretKey);
    }

    private static AuthApplicationService CreateService(IUserAccountStore store, IPasswordHasher hasher, IClock clock)
    {
        return new AuthApplicationService(
            store,
            hasher,
            new FakeAccessTokenIssuer(),
            new FakeTotpService(),
            new FakeMfaChallengeTokenService(),
            clock);
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

        public Task<UserAccount?> GetByIdAsync(Guid userId, CancellationToken cancellationToken)
            => Task.FromResult(_users.FirstOrDefault(x => x.Id == userId));

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

    private sealed class FakeAccessTokenIssuer : IAccessTokenIssuer
    {
        public AccessTokenEnvelope IssueToken(UserAccount user, bool mfaVerified)
            => new("test-access-token", DateTimeOffset.Parse("2026-03-09T18:00:00+00:00"));
    }

    private sealed class FakeTotpService : ITotpService
    {
        public string GenerateSecretKey() => "TESTSECRET123";

        public string BuildProvisioningUri(string accountName, string secretKey)
            => $"otpauth://totp/UrbanArtDrops:{accountName}?secret={secretKey}";

        public bool VerifyCode(string secretKey, string code, DateTimeOffset nowUtc)
            => secretKey == "TESTSECRET123" && code == "123456";
    }

    private sealed class FakeMfaChallengeTokenService : IMfaChallengeTokenService
    {
        public MfaChallengeTokenEnvelope CreateVerificationChallenge(UserAccount user)
            => new($"verify:{user.Id}", DateTimeOffset.Parse("2026-03-09T10:10:00+00:00"));

        public MfaChallengeTokenEnvelope CreateSetupChallenge(UserAccount user, string secretKey)
            => new($"setup:{user.Id}:{secretKey}", DateTimeOffset.Parse("2026-03-09T10:10:00+00:00"));

        public MfaChallengePayload? ReadChallenge(string token)
            => token.StartsWith("setup:", StringComparison.Ordinal)
                ? ParseSetupChallenge(token)
                : token.StartsWith("verify:", StringComparison.Ordinal)
                ? ParseVerificationChallenge(token)
                : null;

        private static MfaChallengePayload? ParseSetupChallenge(string token)
        {
            var parts = token.Split(':', 3, StringSplitOptions.None);
            if (parts.Length != 3 || !Guid.TryParse(parts[1], out var userId))
            {
                return null;
            }

            return new MfaChallengePayload(
                userId,
                MfaChallengeMode.Setup,
                parts[2],
                DateTimeOffset.Parse("2026-03-09T10:10:00+00:00"));
        }

        private static MfaChallengePayload? ParseVerificationChallenge(string token)
        {
            var parts = token.Split(':', 2, StringSplitOptions.None);
            if (parts.Length != 2 || !Guid.TryParse(parts[1], out var userId))
            {
                return null;
            }

            return new MfaChallengePayload(
                userId,
                MfaChallengeMode.Verify,
                null,
                DateTimeOffset.Parse("2026-03-09T10:10:00+00:00"));
        }
    }
}
