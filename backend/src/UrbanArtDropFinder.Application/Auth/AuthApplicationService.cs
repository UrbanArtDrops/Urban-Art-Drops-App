using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Contracts.Auth;
using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Application.Auth;

public sealed class AuthApplicationService
{
    private readonly IUserAccountStore _userAccountStore;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IAccessTokenIssuer _accessTokenIssuer;
    private readonly ITotpService _totpService;
    private readonly IMfaChallengeTokenService _mfaChallengeTokenService;
    private readonly IClock _clock;

    public AuthApplicationService(
        IUserAccountStore userAccountStore,
        IPasswordHasher passwordHasher,
        IAccessTokenIssuer accessTokenIssuer,
        ITotpService totpService,
        IMfaChallengeTokenService mfaChallengeTokenService,
        IClock clock)
    {
        _userAccountStore = userAccountStore;
        _passwordHasher = passwordHasher;
        _accessTokenIssuer = accessTokenIssuer;
        _totpService = totpService;
        _mfaChallengeTokenService = mfaChallengeTokenService;
        _clock = clock;
    }

    public async Task<AuthResult> RegisterLocalAsync(RegisterLocalRequest request, CancellationToken cancellationToken)
    {
        var validation = PasswordPolicy.Validate(request.Password);
        if (!validation.IsValid)
        {
            return new AuthResult(false, validation.Error ?? "Invalid password");
        }

        if (request.Role is UserRole.Admin or UserRole.Moderator)
        {
            return new AuthResult(false, "Admins and moderators must be created manually.");
        }

        if (await _userAccountStore.EmailExistsAsync(request.Email, cancellationToken))
        {
            return new AuthResult(false, "Email already exists.");
        }

        if (await _userAccountStore.UserNameExistsAsync(request.UserName, cancellationToken))
        {
            return new AuthResult(false, "User name already exists.");
        }

        var approved = request.Role == UserRole.Hunter;
        var hash = _passwordHasher.Hash(request.Password);
        var user = UserAccount.CreateLocal(request.Email, request.UserName, request.Role, hash, approved);

        await _userAccountStore.AddAsync(user, null, cancellationToken);
        await _userAccountStore.SaveChangesAsync(cancellationToken);

        var message = approved
            ? "Registration successful. Verify your email to continue."
            : "Registration successful. Account requires approval and email verification.";

        return CreateSuccessResult(message, user);
    }

    public async Task<AuthResult> RegisterProviderAsync(RegisterProviderRequest request, CancellationToken cancellationToken)
    {
        if (request.Role is UserRole.Admin or UserRole.Moderator)
        {
            return new AuthResult(false, "Admins and moderators must be created manually.");
        }

        var existing = await _userAccountStore.GetByProviderSubjectAsync(request.Provider, request.ProviderSubject, cancellationToken);
        if (existing is not null)
        {
            return CreateSuccessResult("Already registered.", existing);
        }

        if (await _userAccountStore.UserNameExistsAsync(request.UserName, cancellationToken))
        {
            return new AuthResult(false, "User name already exists.");
        }

        var approved = request.Role == UserRole.Hunter;
        var user = UserAccount.CreateProvider(request.Email, request.UserName, request.Role, request.Provider, approved);

        await _userAccountStore.AddAsync(user, request.ProviderSubject, cancellationToken);
        await _userAccountStore.SaveChangesAsync(cancellationToken);

        return CreateSuccessResult("Provider registration successful.", user);
    }

    public async Task<AuthResult> LoginLocalAsync(LoginLocalRequest request, CancellationToken cancellationToken)
    {
        var user = await _userAccountStore.GetByEmailAsync(request.Email, cancellationToken);
        if (user is null || user.PasswordHash is null)
        {
            return new AuthResult(false, "Invalid credentials.");
        }

        if (!user.CanAttemptLogin(_clock.UtcNow))
        {
            return new AuthResult(
                false,
                "Login is temporarily delayed due to failed attempts.",
                RetryAfterUtc: user.NextLoginAllowedAtUtc);
        }

        if (!_passwordHasher.Verify(user.PasswordHash, request.Password))
        {
            user.RegisterFailedLogin(_clock.UtcNow);
            await _userAccountStore.SaveChangesAsync(cancellationToken);
            return new AuthResult(
                false,
                "Invalid credentials.",
                RetryAfterUtc: user.NextLoginAllowedAtUtc);
        }

        if (!user.IsApproved)
        {
            return new AuthResult(false, "Account approval is pending.");
        }

        if (user.IsSuspended)
        {
            return new AuthResult(false, "Account is suspended.");
        }

        if (!user.IsEmailVerified)
        {
            return new AuthResult(false, "Email verification is required.");
        }

        user.RegisterSuccessfulLogin();
        await _userAccountStore.SaveChangesAsync(cancellationToken);

        return CreateLoginResult("Login successful.", user);
    }

    public async Task<AuthResult> LoginProviderAsync(LoginProviderRequest request, CancellationToken cancellationToken)
    {
        var user = await _userAccountStore.GetByProviderSubjectAsync(request.Provider, request.ProviderSubject, cancellationToken);
        if (user is null || !user.IsProviderAccount)
        {
            return new AuthResult(false, "Invalid provider credentials.");
        }

        if (!string.IsNullOrWhiteSpace(request.Email) &&
            !string.Equals(user.Email, request.Email.Trim(), StringComparison.OrdinalIgnoreCase))
        {
            return new AuthResult(false, "Invalid provider credentials.");
        }

        if (!user.IsApproved)
        {
            return new AuthResult(false, "Account approval is pending.");
        }

        if (user.IsSuspended)
        {
            return new AuthResult(false, "Account is suspended.");
        }

        user.RegisterSuccessfulLogin();
        await _userAccountStore.SaveChangesAsync(cancellationToken);

        return CreateLoginResult("Login successful.", user);
    }

    public async Task<AuthResult> CompleteMfaChallengeAsync(CompleteMfaChallengeRequest request, CancellationToken cancellationToken)
    {
        var challenge = _mfaChallengeTokenService.ReadChallenge(request.ChallengeToken);
        if (challenge is null || challenge.ExpiresAtUtc <= _clock.UtcNow)
        {
            return new AuthResult(false, "MFA challenge is invalid or expired.");
        }

        var user = await _userAccountStore.GetByIdAsync(challenge.UserId, cancellationToken);
        if (user is null)
        {
            return new AuthResult(false, "User account does not exist.");
        }

        if (!IsMfaRequired(user))
        {
            return CreateSuccessResult("MFA is not required for this account.", user, mfaVerified: false);
        }

        var secretKey = challenge.Mode == MfaChallengeMode.Setup
            ? challenge.SecretKey
            : user.MfaSecretKey;
        if (string.IsNullOrWhiteSpace(secretKey))
        {
            return new AuthResult(false, "MFA secret is unavailable.");
        }

        if (!_totpService.VerifyCode(secretKey, request.Code, _clock.UtcNow))
        {
            return new AuthResult(false, "The MFA code is invalid.");
        }

        if (challenge.Mode == MfaChallengeMode.Setup)
        {
            user.EnableMfa(secretKey);
            await _userAccountStore.SaveChangesAsync(cancellationToken);
        }

        return CreateSuccessResult("MFA verification successful.", user, includeAccessToken: true, mfaVerified: true);
    }

    private AuthResult CreateLoginResult(string message, UserAccount user)
    {
        if (!IsMfaRequired(user))
        {
            return CreateSuccessResult(message, user, includeAccessToken: true, mfaVerified: false);
        }

        if (user.IsMfaEnabled && !string.IsNullOrWhiteSpace(user.MfaSecretKey))
        {
            var challenge = _mfaChallengeTokenService.CreateVerificationChallenge(user);
            return new AuthResult(
                true,
                "MFA verification is required.",
                user.Id,
                user.Role,
                user.UserName,
                user.Email,
                RequiresMfa: true,
                MfaChallengeToken: challenge.Token,
                MfaChallengeExpiresAtUtc: challenge.ExpiresAtUtc);
        }

        var secretKey = _totpService.GenerateSecretKey();
        var setupChallenge = _mfaChallengeTokenService.CreateSetupChallenge(user, secretKey);
        return new AuthResult(
            true,
            "MFA setup is required before access is granted.",
            user.Id,
            user.Role,
            user.UserName,
            user.Email,
            RequiresMfa: true,
            MfaSetupRequired: true,
            MfaChallengeToken: setupChallenge.Token,
            MfaChallengeExpiresAtUtc: setupChallenge.ExpiresAtUtc,
            MfaManualEntryKey: secretKey,
            MfaProvisioningUri: _totpService.BuildProvisioningUri(user.Email, secretKey));
    }

    private static bool IsMfaRequired(UserAccount user)
        => user.Role is UserRole.Admin or UserRole.Moderator;

    private AuthResult CreateSuccessResult(
        string message,
        UserAccount user,
        bool includeAccessToken = false,
        bool mfaVerified = false)
    {
        AccessTokenEnvelope? accessToken = null;
        if (includeAccessToken)
        {
            accessToken = _accessTokenIssuer.IssueToken(user, mfaVerified);
        }

        return new AuthResult(
            true,
            message,
            user.Id,
            user.Role,
            user.UserName,
            user.Email,
            AccessToken: accessToken?.AccessToken,
            AccessTokenExpiresAtUtc: accessToken?.ExpiresAtUtc,
            TokenType: accessToken?.TokenType);
    }
}
