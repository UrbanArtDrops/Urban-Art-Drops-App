using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Contracts.Auth;
using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Application.Auth;

public sealed class AuthApplicationService
{
    private readonly IUserAccountStore _userAccountStore;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IAccessTokenIssuer _accessTokenIssuer;
    private readonly IClock _clock;

    public AuthApplicationService(
        IUserAccountStore userAccountStore,
        IPasswordHasher passwordHasher,
        IAccessTokenIssuer accessTokenIssuer,
        IClock clock)
    {
        _userAccountStore = userAccountStore;
        _passwordHasher = passwordHasher;
        _accessTokenIssuer = accessTokenIssuer;
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

        return CreateSuccessResult(
            "Login successful.",
            user,
            includeAccessToken: true,
            accessTokenIssuer: _accessTokenIssuer);
    }

    private static AuthResult CreateSuccessResult(
        string message,
        UserAccount user,
        bool includeAccessToken = false,
        IAccessTokenIssuer? accessTokenIssuer = null)
    {
        AccessTokenEnvelope? accessToken = null;
        if (includeAccessToken)
        {
            accessToken = accessTokenIssuer?.IssueToken(user)
                ?? throw new InvalidOperationException("Access token issuer is required.");
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
