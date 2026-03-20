using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Contracts.Auth;

public sealed record RegisterLocalRequest(string Email, string UserName, string Password);

public sealed record RegisterProviderRequest(string Provider, string ProviderSubject, string Email, string UserName);

public sealed record LoginLocalRequest(string Email, string Password);

public sealed record LoginProviderRequest(string Provider, string ProviderSubject, string Email);

public sealed record BeginExternalProviderLoginRequest(string Provider, string CallbackUrl);

public sealed record BeginExternalProviderRegistrationRequest(
    string Provider,
    string CallbackUrl,
    string Email,
    string UserName);

public sealed record BeginExternalProviderAuthResponse(string AuthorizationUrl, DateTimeOffset ExpiresAtUtc);

public sealed record CompleteExternalProviderAuthRequest(string ProviderSessionId);

public sealed record AvailableExternalAuthProviderResponse(string Provider, string DisplayName);

public sealed record CompleteMfaChallengeRequest(string ChallengeToken, string Code);

public sealed record BootstrapAdminRequest(string Email, string UserName, string Password);

public sealed record BootstrapStatusResponse(
    bool BootstrapRequired,
    bool AdminUserExists,
    bool ModeratorBootstrapAvailable);

public sealed record AuthResult(
    bool Success,
    string Message,
    Guid? UserId = null,
    UserRole? Role = null,
    string? UserName = null,
    string? Email = null,
    DateTimeOffset? RetryAfterUtc = null,
    string? AccessToken = null,
    DateTimeOffset? AccessTokenExpiresAtUtc = null,
    string? TokenType = null,
    bool RequiresMfa = false,
    bool MfaSetupRequired = false,
    string? MfaChallengeToken = null,
    DateTimeOffset? MfaChallengeExpiresAtUtc = null,
    string? MfaManualEntryKey = null,
    string? MfaProvisioningUri = null);
