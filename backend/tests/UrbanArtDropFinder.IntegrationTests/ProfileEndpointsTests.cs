using System.Net;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using UrbanArtDropFinder.Domain.Users;
using UrbanArtDropFinder.Persistence.Db;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class ProfileEndpointsTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebApplicationFactory _factory;

    public ProfileEndpointsTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetCurrentProfile_ReturnsStoredIdentityAndPolicyState()
    {
        var authenticatedUser = await _factory.CreateAuthenticatedUserAsync(
            UserRole.Admin,
            $"profile.admin.{Guid.NewGuid():N}");

        var response = await _client.GetAuthorizedAsync("/api/profile", authenticatedUser.AccessToken);
        await EnsureSuccessWithBodyAsync(response);

        var payload = await response.Content.ReadFromJsonAsync<CurrentUserProfileDto>();
        Assert.NotNull(payload);
        Assert.Equal(authenticatedUser.Id, payload!.UserId);
        Assert.Equal(authenticatedUser.Email, payload.Email);
        Assert.Equal(authenticatedUser.UserName, payload.UserName);
        Assert.Equal(UserRole.Admin, payload.Role);
        Assert.Null(payload.PendingRoleApplication);
        Assert.Null(payload.PendingRoleApplicationRequestedAtUtc);
        Assert.True(payload.IsMfaEnabled);
        Assert.True(payload.IsMfaRequiredByPolicy);
        Assert.Null(payload.ProfileImage);
    }

    [Fact]
    public async Task UpdateCurrentProfile_UpdatesEmailUserNameAndProfileImage()
    {
        var authenticatedUser = await _factory.CreateAuthenticatedUserAsync(
            UserRole.Hunter,
            $"profile.hunter.{Guid.NewGuid():N}");
        var updatedEmail = $"updated.{Guid.NewGuid():N}@example.com";

        var response = await _client.PutAuthorizedAsJsonAsync(
            "/api/profile",
            new
            {
                email = updatedEmail,
                userName = "updated-profile-user",
                profileImageSource = "data:image/png;base64,aGVsbG8="
            },
            authenticatedUser.AccessToken);
        await EnsureSuccessWithBodyAsync(response);

        var payload = await response.Content.ReadFromJsonAsync<CurrentUserProfileDto>();
        Assert.NotNull(payload);
        Assert.Equal(updatedEmail, payload!.Email);
        Assert.Equal("updated-profile-user", payload.UserName);
        Assert.NotNull(payload.ProfileImage);
        Assert.Contains("/api/media/user-profile-images/", payload.ProfileImage!.Url, StringComparison.OrdinalIgnoreCase);

        var mediaResponse = await _client.GetAsync(payload.ProfileImage.Url);
        await EnsureSuccessWithBodyAsync(mediaResponse);
        Assert.Equal("image/png", mediaResponse.Content.Headers.ContentType?.MediaType);
        Assert.Equal("hello", await mediaResponse.Content.ReadAsStringAsync());

        var oldLoginResponse = await _client.PostAsJsonAsync(
            "/api/auth/login-local",
            new
            {
                email = authenticatedUser.Email,
                password = "Aaaaaaaaaaaaaaa!"
            });
        Assert.Equal(HttpStatusCode.BadRequest, oldLoginResponse.StatusCode);

        var newLoginResponse = await _client.PostAsJsonAsync(
            "/api/auth/login-local",
            new
            {
                email = updatedEmail,
                password = "Aaaaaaaaaaaaaaa!"
            });
        await EnsureSuccessWithBodyAsync(newLoginResponse);
    }

    [Fact]
    public async Task UpdateCurrentProfile_RejectsDuplicateEmail()
    {
        var firstUser = await _factory.CreateAuthenticatedUserAsync(
            UserRole.Hunter,
            $"profile.first.{Guid.NewGuid():N}");
        var secondUser = await _factory.CreateAuthenticatedUserAsync(
            UserRole.Hunter,
            $"profile.second.{Guid.NewGuid():N}");

        var response = await _client.PutAuthorizedAsJsonAsync(
            "/api/profile",
            new
            {
                email = secondUser.Email,
                userName = "duplicate-email-user",
                profileImageSource = (string?)null
            },
            firstUser.AccessToken);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("Email already exists", body, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task ProfileMfaSetupAndDisable_UpdatesCurrentUserProfile()
    {
        var authenticatedUser = await _factory.CreateAuthenticatedUserAsync(
            UserRole.Hunter,
            $"profile.mfa.{Guid.NewGuid():N}");

        var setupResponse = await _client.PostAuthorizedAsync(
            "/api/profile/mfa/setup",
            authenticatedUser.AccessToken);
        await EnsureSuccessWithBodyAsync(setupResponse);

        var setupPayload = await setupResponse.Content.ReadFromJsonAsync<AuthResultDto>();
        Assert.NotNull(setupPayload);
        Assert.True(setupPayload!.RequiresMfa);
        Assert.True(setupPayload.MfaSetupRequired);
        Assert.False(string.IsNullOrWhiteSpace(setupPayload.MfaChallengeToken));
        Assert.False(string.IsNullOrWhiteSpace(setupPayload.MfaManualEntryKey));

        var completeResponse = await _client.PostAsJsonAsync(
            "/api/auth/mfa/complete",
            new
            {
                challengeToken = setupPayload.MfaChallengeToken,
                code = TestAuthUtilities.CreateCurrentTotpCode(setupPayload.MfaManualEntryKey!)
            });
        await EnsureSuccessWithBodyAsync(completeResponse);

        var profileAfterSetup = await _client.GetAuthorizedAsync("/api/profile", authenticatedUser.AccessToken);
        await EnsureSuccessWithBodyAsync(profileAfterSetup);
        var profileAfterSetupPayload = await profileAfterSetup.Content.ReadFromJsonAsync<CurrentUserProfileDto>();
        Assert.NotNull(profileAfterSetupPayload);
        Assert.True(profileAfterSetupPayload!.IsMfaEnabled);
        Assert.False(profileAfterSetupPayload.IsMfaRequiredByPolicy);

        var disableResponse = await _client.PostAuthorizedAsJsonAsync(
            "/api/profile/mfa/disable",
            new
            {
                code = TestAuthUtilities.CreateCurrentTotpCode(setupPayload.MfaManualEntryKey!)
            },
            authenticatedUser.AccessToken);
        await EnsureSuccessWithBodyAsync(disableResponse);

        var disabledProfile = await disableResponse.Content.ReadFromJsonAsync<CurrentUserProfileDto>();
        Assert.NotNull(disabledProfile);
        Assert.False(disabledProfile!.IsMfaEnabled);

        using var scope = _factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<UrbanArtDbContext>();
        var storedUser = await dbContext.UserAccounts.FirstAsync(user => user.Id == authenticatedUser.Id);
        Assert.False(storedUser.IsMfaEnabled);
        Assert.Null(storedUser.MfaSecretKey);
    }

    [Fact]
    public async Task HunterCanApplyForArtistRole_FromProfile()
    {
        var authenticatedUser = await _factory.CreateAuthenticatedUserAsync(
            UserRole.Hunter,
            $"profile.apply.artist.{Guid.NewGuid():N}");

        var response = await _client.PostAuthorizedAsJsonAsync(
            "/api/profile/role-application",
            new
            {
                role = UserRole.Artist
            },
            authenticatedUser.AccessToken);
        await EnsureSuccessWithBodyAsync(response);

        var payload = await response.Content.ReadFromJsonAsync<CurrentUserProfileDto>();
        Assert.NotNull(payload);
        Assert.Equal(UserRole.Hunter, payload!.Role);
        Assert.Equal(UserRole.Artist, payload.PendingRoleApplication);
        Assert.NotNull(payload.PendingRoleApplicationRequestedAtUtc);

        using var scope = _factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<UrbanArtDbContext>();
        var storedUser = await dbContext.UserAccounts.FirstAsync(user => user.Id == authenticatedUser.Id);
        Assert.Equal(UserRole.Artist, storedUser.PendingRoleApplication);
    }

    [Fact]
    public async Task NonHunterCannotApplyForRole_FromProfile()
    {
        var authenticatedUser = await _factory.CreateAuthenticatedUserAsync(
            UserRole.Artist,
            $"profile.apply.reject.{Guid.NewGuid():N}");

        var response = await _client.PostAuthorizedAsJsonAsync(
            "/api/profile/role-application",
            new
            {
                role = UserRole.DropMaker
            },
            authenticatedUser.AccessToken);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        var body = await response.Content.ReadAsStringAsync();
        Assert.Contains("Only hunters", body, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task ProfileNotifications_CanBeListedAndMarkedRead()
    {
        var authenticatedUser = await _factory.CreateAuthenticatedUserAsync(
            UserRole.Artist,
            $"profile.notifications.{Guid.NewGuid():N}");

        using (var scope = _factory.Services.CreateScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<UrbanArtDbContext>();
            await dbContext.UserNotifications.AddRangeAsync(
            [
                UserNotification.Create(
                    authenticatedUser.Id,
                    "Admin bearbeitet Kunstwerk",
                    "Ein Administrator hat ein Kunstwerk aktualisiert.",
                    "admin-art-piece",
                    Guid.NewGuid(),
                    "ArtPiece"),
                UserNotification.Create(
                    authenticatedUser.Id,
                    "Admin bearbeitet Drop",
                    "Ein Administrator hat einen Drop aktualisiert.",
                    "admin-drop",
                    Guid.NewGuid(),
                    "Drop")
            ]);
            await dbContext.SaveChangesAsync();
        }

        var listResponse = await _client.GetAuthorizedAsync(
            "/api/profile/notifications",
            authenticatedUser.AccessToken);
        await EnsureSuccessWithBodyAsync(listResponse);

        var notifications = await listResponse.Content.ReadFromJsonAsync<List<UserNotificationDto>>();
        Assert.NotNull(notifications);
        Assert.Equal(2, notifications!.Count);
        Assert.All(notifications, notification => Assert.False(notification.IsRead));

        var notificationToMarkRead = notifications[0];
        var markReadResponse = await _client.PostAuthorizedAsync(
            $"/api/profile/notifications/{notificationToMarkRead.Id}/mark-read",
            authenticatedUser.AccessToken);
        await EnsureSuccessWithBodyAsync(markReadResponse);
        var markedNotification = await markReadResponse.Content.ReadFromJsonAsync<UserNotificationDto>();
        Assert.NotNull(markedNotification);
        Assert.True(markedNotification!.IsRead);

        using var verificationScope = _factory.Services.CreateScope();
        var verificationDbContext = verificationScope.ServiceProvider.GetRequiredService<UrbanArtDbContext>();
        var storedNotification = await verificationDbContext.UserNotifications.FirstAsync(
            notification => notification.Id == notificationToMarkRead.Id);
        Assert.True(storedNotification.IsRead);
    }

    private sealed record CurrentUserProfileDto(
        Guid UserId,
        string Email,
        string UserName,
        UserRole Role,
        UserRole? PendingRoleApplication,
        DateTimeOffset? PendingRoleApplicationRequestedAtUtc,
        bool IsProviderAccount,
        bool IsMfaEnabled,
        bool IsMfaRequiredByPolicy,
        ProfileImageDto? ProfileImage);

    private sealed record ProfileImageDto(Guid Id, string Url);

    private sealed record AuthResultDto(
        bool Success,
        string Message,
        string? AccessToken,
        bool RequiresMfa,
        bool MfaSetupRequired,
        string? MfaChallengeToken,
        string? MfaManualEntryKey);

    private sealed record UserNotificationDto(
        Guid Id,
        string Title,
        string Message,
        string Category,
        bool IsRead,
        DateTimeOffset CreatedAtUtc,
        Guid? RelatedEntityId,
        string? RelatedEntityType);

    private static async Task EnsureSuccessWithBodyAsync(HttpResponseMessage response)
    {
        if (response.IsSuccessStatusCode)
        {
            return;
        }

        var body = await response.Content.ReadAsStringAsync();
        throw new Xunit.Sdk.XunitException($"Unexpected status {(int)response.StatusCode}: {body}");
    }
}
