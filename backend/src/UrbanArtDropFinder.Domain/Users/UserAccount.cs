using UrbanArtDropFinder.Domain.Shared;

namespace UrbanArtDropFinder.Domain.Users;

public sealed class UserAccount
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string Email { get; private set; }
    public string UserName { get; private set; }
    public UserRole Role { get; private set; }
    public UserRole? PendingRoleApplication { get; private set; }
    public DateTimeOffset? PendingRoleApplicationRequestedAtUtc { get; private set; }
    public bool IsApproved { get; private set; }
    public bool IsSuspended { get; private set; }
    public bool IsEmailVerified { get; private set; }
    public bool IsProviderAccount { get; private set; }
    public string? Provider { get; private set; }
    public string? PasswordHash { get; private set; }
    public bool IsMfaEnabled { get; private set; }
    public string? MfaSecretKey { get; private set; }
    public int FailedLoginAttempts { get; private set; }
    public DateTimeOffset? NextLoginAllowedAtUtc { get; private set; }
    public DateTimeOffset CreatedAtUtc { get; private set; } = DateTimeOffset.UtcNow;

    private UserAccount()
    {
        Email = string.Empty;
        UserName = string.Empty;
    }

    public static UserAccount CreateLocal(string email, string userName, UserRole role, string passwordHash, bool approved)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            throw new DomainValidationException("Email is required.");
        }

        if (string.IsNullOrWhiteSpace(userName))
        {
            throw new DomainValidationException("User name is required.");
        }

        if (string.IsNullOrWhiteSpace(passwordHash))
        {
            throw new DomainValidationException("Password hash is required.");
        }

        return new UserAccount
        {
            Email = email.Trim().ToLowerInvariant(),
            UserName = userName.Trim(),
            Role = role,
            PasswordHash = passwordHash,
            IsProviderAccount = false,
            Provider = null,
            IsApproved = approved,
            IsEmailVerified = false
        };
    }

    public static UserAccount CreateProvider(
        string email,
        string userName,
        UserRole role,
        string provider,
        bool approved)
    {
        if (string.IsNullOrWhiteSpace(provider))
        {
            throw new DomainValidationException("Provider is required.");
        }

        var account = CreateLocal(email, userName, role, "provider-account", approved);
        account.PasswordHash = null;
        account.IsProviderAccount = true;
        account.Provider = provider.Trim();
        account.IsEmailVerified = true;
        return account;
    }

    public void MarkEmailVerified() => IsEmailVerified = true;

    public void SetApproval(bool approved) => IsApproved = approved;

    public void SetSuspended(bool suspended) => IsSuspended = suspended;

    public void ChangeRole(UserRole role)
    {
        Role = role;
        ClearPendingRoleApplication();
    }

    public void ApplyForRole(UserRole requestedRole, DateTimeOffset requestedAtUtc)
    {
        if (Role != UserRole.Hunter)
        {
            throw new DomainValidationException("Only hunters can apply for artist or drop-maker access.");
        }

        if (requestedRole is not (UserRole.Artist or UserRole.DropMaker))
        {
            throw new DomainValidationException("Hunters can only apply for artist or drop-maker access.");
        }

        if (PendingRoleApplication.HasValue)
        {
            throw new DomainValidationException("A role application is already pending.");
        }

        PendingRoleApplication = requestedRole;
        PendingRoleApplicationRequestedAtUtc = requestedAtUtc;
    }

    public void ApproveRoleApplication()
    {
        if (!PendingRoleApplication.HasValue)
        {
            throw new DomainValidationException("No role application is pending.");
        }

        Role = PendingRoleApplication.Value;
        IsApproved = true;
        ClearPendingRoleApplication();
    }

    public void RejectRoleApplication()
    {
        if (!PendingRoleApplication.HasValue)
        {
            throw new DomainValidationException("No role application is pending.");
        }

        ClearPendingRoleApplication();
    }

    public void ChangeUserName(string userName)
    {
        if (string.IsNullOrWhiteSpace(userName))
        {
            throw new DomainValidationException("User name is required.");
        }

        UserName = userName.Trim();
    }

    public void ChangeEmail(string email)
    {
        if (string.IsNullOrWhiteSpace(email))
        {
            throw new DomainValidationException("Email is required.");
        }

        Email = email.Trim().ToLowerInvariant();
    }

    public void EnableMfa(string secretKey)
    {
        if (string.IsNullOrWhiteSpace(secretKey))
        {
            throw new DomainValidationException("MFA secret key is required.");
        }

        MfaSecretKey = secretKey.Trim();
        IsMfaEnabled = true;
    }

    public void DisableMfa()
    {
        IsMfaEnabled = false;
        MfaSecretKey = null;
    }

    public bool CanAttemptLogin(DateTimeOffset nowUtc) =>
        !NextLoginAllowedAtUtc.HasValue || NextLoginAllowedAtUtc.Value <= nowUtc;

    public void RegisterFailedLogin(DateTimeOffset nowUtc)
    {
        FailedLoginAttempts += 1;
        var backoff = LoginBackoffPolicy.GetBackoffForFailedAttempt(FailedLoginAttempts);
        NextLoginAllowedAtUtc = nowUtc.Add(backoff);
    }

    public void RegisterSuccessfulLogin()
    {
        FailedLoginAttempts = 0;
        NextLoginAllowedAtUtc = null;
    }

    private void ClearPendingRoleApplication()
    {
        PendingRoleApplication = null;
        PendingRoleApplicationRequestedAtUtc = null;
    }
}
