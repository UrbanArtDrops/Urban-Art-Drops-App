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
}
