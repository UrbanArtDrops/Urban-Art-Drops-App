using UrbanArtDropFinder.Domain.Shared;
using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Domain.Tests;

public sealed class UserAccountDomainRulesTests
{
    [Fact]
    public void ApplyForRole_FromHunter_SetsPendingApplication()
    {
        var user = UserAccount.CreateLocal(
            "hunter@example.com",
            "hunter",
            UserRole.Hunter,
            "hash",
            approved: true);

        var requestedAtUtc = DateTimeOffset.Parse("2026-03-20T09:00:00+00:00");
        user.ApplyForRole(UserRole.Artist, requestedAtUtc);

        Assert.Equal(UserRole.Hunter, user.Role);
        Assert.Equal(UserRole.Artist, user.PendingRoleApplication);
        Assert.Equal(requestedAtUtc, user.PendingRoleApplicationRequestedAtUtc);
    }

    [Fact]
    public void ApplyForRole_FromNonHunter_Throws()
    {
        var user = UserAccount.CreateLocal(
            "artist@example.com",
            "artist",
            UserRole.Artist,
            "hash",
            approved: true);

        Assert.Throws<DomainValidationException>(
            () => user.ApplyForRole(UserRole.DropMaker, DateTimeOffset.UtcNow));
    }

    [Fact]
    public void ApproveRoleApplication_ChangesRoleAndClearsPendingState()
    {
        var user = UserAccount.CreateLocal(
            "hunter@example.com",
            "hunter",
            UserRole.Hunter,
            "hash",
            approved: true);
        user.ApplyForRole(UserRole.DropMaker, DateTimeOffset.UtcNow);

        user.ApproveRoleApplication();

        Assert.Equal(UserRole.DropMaker, user.Role);
        Assert.Null(user.PendingRoleApplication);
        Assert.Null(user.PendingRoleApplicationRequestedAtUtc);
    }

    [Fact]
    public void RejectRoleApplication_ClearsPendingStateWithoutChangingRole()
    {
        var user = UserAccount.CreateLocal(
            "hunter@example.com",
            "hunter",
            UserRole.Hunter,
            "hash",
            approved: true);
        user.ApplyForRole(UserRole.Artist, DateTimeOffset.UtcNow);

        user.RejectRoleApplication();

        Assert.Equal(UserRole.Hunter, user.Role);
        Assert.Null(user.PendingRoleApplication);
        Assert.Null(user.PendingRoleApplicationRequestedAtUtc);
    }

    [Fact]
    public void BeginEmailVerification_ResetsVerificationStateAndStoresExpiry()
    {
        var user = UserAccount.CreateLocal(
            "hunter@example.com",
            "hunter",
            UserRole.Hunter,
            "hash",
            approved: true);
        user.MarkEmailVerified();
        var expiresAtUtc = DateTimeOffset.Parse("2026-04-08T10:00:00+00:00");

        user.BeginEmailVerification("token-hash", expiresAtUtc);

        Assert.False(user.IsEmailVerified);
        Assert.Equal("token-hash", user.EmailVerificationTokenHash);
        Assert.Equal(expiresAtUtc, user.EmailVerificationTokenExpiresAtUtc);
    }

    [Fact]
    public void CompletePasswordReset_ChangesPasswordAndClearsToken()
    {
        var user = UserAccount.CreateLocal(
            "hunter@example.com",
            "hunter",
            UserRole.Hunter,
            "old-hash",
            approved: true);
        user.BeginPasswordReset("reset-hash", DateTimeOffset.Parse("2026-04-08T10:00:00+00:00"));

        user.CompletePasswordReset("new-hash");

        Assert.Equal("new-hash", user.PasswordHash);
        Assert.Null(user.PasswordResetTokenHash);
        Assert.Null(user.PasswordResetTokenExpiresAtUtc);
        Assert.Equal(0, user.FailedLoginAttempts);
        Assert.Null(user.NextLoginAllowedAtUtc);
    }
}
