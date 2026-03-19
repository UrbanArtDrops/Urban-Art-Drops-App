using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.DependencyInjection;
using UrbanArtDropFinder.Domain.Users;
using UrbanArtDropFinder.Persistence.Db;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class AuthEndpointsTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebApplicationFactory _factory;

    public AuthEndpointsTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetConfiguredExternalProviders_ReturnsOnlyProvidersVisibleOnLogin()
    {
        var response = await _client.GetAsync("/api/auth/providers");
        await EnsureSuccessWithBodyAsync(response);

        var payload = await response.Content.ReadFromJsonAsync<List<AvailableExternalProviderDto>>();
        Assert.NotNull(payload);
        Assert.Equal(2, payload!.Count);
        Assert.Contains(payload, provider => provider.Provider == "google" && provider.DisplayName == "Google");
        Assert.Contains(payload, provider => provider.Provider == "microsoft" && provider.DisplayName == "Microsoft");
        Assert.DoesNotContain(payload, provider => provider.Provider == "facebook");
    }

    [Fact]
    public async Task BeginAndCompleteExternalProviderLogin_ReturnsBearerToken()
    {
        using (var scope = _factory.Services.CreateScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<UrbanArtDbContext>();
            var user = UserAccount.CreateProvider(
                "provider.hunter.login@example.com",
                $"provider-hunter-{Guid.NewGuid():N}",
                UserRole.Hunter,
                "google",
                approved: true);
            dbContext.UserAccounts.Add(user);
            dbContext.UserProviderLinks.Add(new UserProviderLink
            {
                UserAccountId = user.Id,
                Provider = "google",
                ProviderSubject = "provider-subject-hunter-login"
            });
            await dbContext.SaveChangesAsync();
        }

        var beginResponse = await _client.PostAsJsonAsync(
            "/api/auth/provider-login/begin",
            new
            {
                provider = "google",
                callbackUrl = "urbanartdrops-auth://oauth/callback"
            });
        await EnsureSuccessWithBodyAsync(beginResponse);

        var beginPayload = await beginResponse.Content.ReadFromJsonAsync<BeginExternalProviderAuthDto>();
        Assert.NotNull(beginPayload);
        var authorizationUri = new Uri(beginPayload!.AuthorizationUrl);
        var state = ParseQueryParameter(authorizationUri, "state");
        Assert.False(string.IsNullOrWhiteSpace(state));

        using var redirectClient = _factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            AllowAutoRedirect = false
        });
        var callbackResponse = await redirectClient.GetAsync(
            $"/api/auth/provider/callback?state={Uri.EscapeDataString(state!)}&code=hunter-login");
        Assert.Equal(HttpStatusCode.Redirect, callbackResponse.StatusCode);
        Assert.NotNull(callbackResponse.Headers.Location);
        var providerSessionId = ParseQueryParameter(callbackResponse.Headers.Location!, "provider_session");
        Assert.False(string.IsNullOrWhiteSpace(providerSessionId));

        var completeResponse = await _client.PostAsJsonAsync(
            "/api/auth/provider/complete",
            new { providerSessionId });
        await EnsureSuccessWithBodyAsync(completeResponse);

        var completePayload = await completeResponse.Content.ReadFromJsonAsync<AuthResultDto>();
        Assert.NotNull(completePayload);
        Assert.True(completePayload!.Success);
        Assert.False(completePayload.RequiresMfa);
        Assert.False(string.IsNullOrWhiteSpace(completePayload.AccessToken));
        Assert.Equal("Bearer", completePayload.TokenType);
    }

    [Fact]
    public async Task BeginAndCompleteExternalProviderRegistration_CreatesProviderAccount()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var requestedEmail = $"provider.registration.{uniqueId}@example.com";
        var requestedUserName = $"provider-registration-{uniqueId}";

        var beginResponse = await _client.PostAsJsonAsync(
            "/api/auth/provider-register/begin",
            new
            {
                provider = "google",
                callbackUrl = "urbanartdrops-auth://oauth/callback",
                email = requestedEmail,
                userName = requestedUserName,
                role = UserRole.Hunter
            });
        await EnsureSuccessWithBodyAsync(beginResponse);

        var beginPayload = await beginResponse.Content.ReadFromJsonAsync<BeginExternalProviderAuthDto>();
        Assert.NotNull(beginPayload);
        var authorizationUri = new Uri(beginPayload!.AuthorizationUrl);
        var state = ParseQueryParameter(authorizationUri, "state");
        Assert.False(string.IsNullOrWhiteSpace(state));

        using var redirectClient = _factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            AllowAutoRedirect = false
        });
        var callbackResponse = await redirectClient.GetAsync(
            $"/api/auth/provider/callback?state={Uri.EscapeDataString(state!)}&code=hunter-register");
        Assert.Equal(HttpStatusCode.Redirect, callbackResponse.StatusCode);
        Assert.NotNull(callbackResponse.Headers.Location);
        var providerSessionId = ParseQueryParameter(callbackResponse.Headers.Location!, "provider_session");
        Assert.False(string.IsNullOrWhiteSpace(providerSessionId));

        var completeResponse = await _client.PostAsJsonAsync(
            "/api/auth/provider/complete",
            new { providerSessionId });
        await EnsureSuccessWithBodyAsync(completeResponse);

        var completePayload = await completeResponse.Content.ReadFromJsonAsync<AuthResultDto>();
        Assert.NotNull(completePayload);
        Assert.True(completePayload!.Success);
        Assert.Equal(UserRole.Hunter, completePayload.Role);

        using var scope = _factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<UrbanArtDbContext>();
        var createdUser = dbContext.UserAccounts.Single(user =>
            string.Equals(user.UserName, requestedUserName, StringComparison.OrdinalIgnoreCase));
        Assert.True(createdUser.IsProviderAccount);
        Assert.Equal("google", createdUser.Provider);
    }

    [Fact]
    public async Task RegisterLocal_ForHunter_PersistsHunterRoleAndAllowsVerifiedLogin()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var email = $"hunter.{uniqueId}@example.com";
        var userName = $"hunter.{uniqueId}";

        var registerResponse = await _client.PostAsJsonAsync(
            "/api/auth/register-local",
            new
            {
                email,
                userName,
                password = "Aaaaaaaaaaaaaaa!",
                role = UserRole.Hunter
            });
        await EnsureSuccessWithBodyAsync(registerResponse);

        var registerResult = await registerResponse.Content.ReadFromJsonAsync<AuthResultDto>();
        Assert.NotNull(registerResult);
        Assert.Equal(UserRole.Hunter, registerResult!.Role);
        Assert.Equal(userName, registerResult.UserName);
        Assert.Equal(email, registerResult.Email);

        var verifyResponse = await _client.PostAsync($"/api/auth/verify-email/{registerResult.UserId}", null);
        await EnsureSuccessWithBodyAsync(verifyResponse);

        var loginResponse = await _client.PostAsJsonAsync(
            "/api/auth/login-local",
            new
            {
                email,
                password = "Aaaaaaaaaaaaaaa!"
            });
        await EnsureSuccessWithBodyAsync(loginResponse);

        var loginResult = await loginResponse.Content.ReadFromJsonAsync<AuthResultDto>();
        Assert.NotNull(loginResult);
        Assert.Equal(registerResult.UserId, loginResult!.UserId);
        Assert.Equal(UserRole.Hunter, loginResult.Role);
        Assert.False(string.IsNullOrWhiteSpace(loginResult.AccessToken));
        Assert.NotNull(loginResult.AccessTokenExpiresAtUtc);
        Assert.Equal("Bearer", loginResult.TokenType);
    }

    [Fact]
    public async Task RegisterLocal_ForArtist_CreatesPendingApprovalAccount()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var email = $"artist.{uniqueId}@example.com";
        var userName = $"artist.{uniqueId}";

        var registerResponse = await _client.PostAsJsonAsync(
            "/api/auth/register-local",
            new
            {
                email,
                userName,
                password = "Aaaaaaaaaaaaaaa!",
                role = UserRole.Artist
            });
        await EnsureSuccessWithBodyAsync(registerResponse);

        using var scope = _factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<UrbanArtDbContext>();
        var createdUser = dbContext.UserAccounts.Single(user => string.Equals(user.Email, email, StringComparison.OrdinalIgnoreCase));
        Assert.Equal(UserRole.Artist, createdUser.Role);
        Assert.False(createdUser.IsApproved);

        var verifyResponse = await _client.PostAsync($"/api/auth/verify-email/{createdUser.Id}", null);
        await EnsureSuccessWithBodyAsync(verifyResponse);

        var loginResponse = await _client.PostAsJsonAsync(
            "/api/auth/login-local",
            new
            {
                email,
                password = "Aaaaaaaaaaaaaaa!"
            });

        Assert.Equal(HttpStatusCode.BadRequest, loginResponse.StatusCode);
        var loginBody = await loginResponse.Content.ReadAsStringAsync();
        Assert.Contains("pending", loginBody, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task BootstrapAdmin_WhenNoAdminExists_CreatesFirstAdminAndDisablesFurtherBootstrap()
    {
        var statusResponse = await _client.GetAsync("/api/bootstrap/status");
        await EnsureSuccessWithBodyAsync(statusResponse);
        var statusBefore = await statusResponse.Content.ReadFromJsonAsync<BootstrapStatusDto>();
        Assert.NotNull(statusBefore);
        Assert.True(statusBefore!.BootstrapRequired);

        var uniqueId = Guid.NewGuid().ToString("N");
        var bootstrapResponse = await _client.PostAsJsonAsync(
            "/api/bootstrap/admin",
            new
            {
                email = $"bootstrap.admin.{uniqueId}@example.com",
                userName = $"bootstrap-admin-{uniqueId}",
                password = "Aaaaaaaaaaaaaaa!"
            });
        await EnsureSuccessWithBodyAsync(bootstrapResponse);

        var created = await bootstrapResponse.Content.ReadFromJsonAsync<ManagedUserDto>();
        Assert.NotNull(created);
        Assert.Equal(UserRole.Admin, created!.Role);
        Assert.True(created.IsApproved);
        Assert.True(created.IsEmailVerified);

        var statusAfterResponse = await _client.GetAsync("/api/bootstrap/status");
        await EnsureSuccessWithBodyAsync(statusAfterResponse);
        var statusAfter = await statusAfterResponse.Content.ReadFromJsonAsync<BootstrapStatusDto>();
        Assert.NotNull(statusAfter);
        Assert.False(statusAfter!.BootstrapRequired);

        var secondBootstrapResponse = await _client.PostAsJsonAsync(
            "/api/bootstrap/admin",
            new
            {
                email = $"second.admin.{uniqueId}@example.com",
                userName = $"second-admin-{uniqueId}",
                password = "Aaaaaaaaaaaaaaa!"
            });
        Assert.Equal(HttpStatusCode.Conflict, secondBootstrapResponse.StatusCode);
    }

    [Fact]
    public async Task AdminEndpoints_RequireAuthenticatedAdminToken()
    {
        var anonymousResponse = await _client.GetAsync("/api/admin/users");
        Assert.Equal(HttpStatusCode.Unauthorized, anonymousResponse.StatusCode);

        var hunter = await _factory.CreateAuthenticatedUserAsync(
            UserRole.Hunter,
            $"hunter.authz.{Guid.NewGuid():N}");
        var hunterResponse = await _client.GetAuthorizedAsync("/api/admin/users", hunter.AccessToken);
        Assert.Equal(HttpStatusCode.Forbidden, hunterResponse.StatusCode);

        var admin = await _factory.CreateAuthenticatedUserAsync(
            UserRole.Admin,
            $"admin.authz.{Guid.NewGuid():N}");
        var adminResponse = await _client.GetAuthorizedAsync("/api/admin/users", admin.AccessToken);
        await EnsureSuccessWithBodyAsync(adminResponse);
    }

    [Fact]
    public async Task RegisterProviderAndLoginProvider_ForHunter_ReturnsBearerToken()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var email = $"provider.hunter.{uniqueId}@example.com";
        var userName = $"provider-hunter-{uniqueId}";
        var providerSubject = $"provider-subject-{uniqueId}";

        var registerResponse = await _client.PostAsJsonAsync(
            "/api/auth/register-provider",
            new
            {
                provider = "google",
                providerSubject,
                email,
                userName,
                role = UserRole.Hunter
            });
        await EnsureSuccessWithBodyAsync(registerResponse);

        var loginResponse = await _client.PostAsJsonAsync(
            "/api/auth/login-provider",
            new
            {
                provider = "google",
                providerSubject,
                email
            });
        await EnsureSuccessWithBodyAsync(loginResponse);

        var loginResult = await loginResponse.Content.ReadFromJsonAsync<AuthResultDto>();
        Assert.NotNull(loginResult);
        Assert.False(loginResult!.RequiresMfa);
        Assert.False(string.IsNullOrWhiteSpace(loginResult.AccessToken));
        Assert.Equal("Bearer", loginResult.TokenType);
    }

    [Fact]
    public async Task AdminUserProfilePatch_UpdatesEmailAndUserName()
    {
        var admin = await _factory.CreateAuthenticatedUserAsync(
            UserRole.Admin,
            $"admin.profile.{Guid.NewGuid():N}");
        var managedUser = await _factory.CreateAuthenticatedUserAsync(
            UserRole.Hunter,
            $"hunter.profile.{Guid.NewGuid():N}");
        var updatedEmail = $"updated.{Guid.NewGuid():N}@example.com";

        var patchResponse = await _client.PatchAuthorizedAsJsonAsync(
            $"/api/admin/users/{managedUser.Id}/profile",
            new
            {
                userName = "updated-hunter-profile",
                email = updatedEmail
            },
            admin.AccessToken);
        await EnsureSuccessWithBodyAsync(patchResponse);

        var oldLoginResponse = await _client.PostAsJsonAsync(
            "/api/auth/login-local",
            new
            {
                email = managedUser.Email,
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
        var loginPayload = await newLoginResponse.Content.ReadFromJsonAsync<AuthResultDto>();
        Assert.NotNull(loginPayload);
        Assert.Equal("updated-hunter-profile", loginPayload!.UserName);
        Assert.Equal(updatedEmail, loginPayload.Email);
    }

    [Fact]
    public async Task LoginProvider_ForModeratorProviderAccount_RequiresMfaAndReturnsBearerTokenAfterChallenge()
    {
        var uniqueId = Guid.NewGuid().ToString("N");
        var email = $"provider.moderator.{uniqueId}@example.com";
        var providerSubject = $"provider-moderator-subject-{uniqueId}";

        using (var scope = _factory.Services.CreateScope())
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<UrbanArtDbContext>();
            var user = UserAccount.CreateProvider(
                email,
                $"provider-moderator-{uniqueId}",
                UserRole.Moderator,
                "microsoft",
                approved: true);
            user.EnableMfa("JBSWY3DPEHPK3PXP");
            dbContext.UserAccounts.Add(user);
            dbContext.UserProviderLinks.Add(new UserProviderLink
            {
                UserAccountId = user.Id,
                Provider = "microsoft",
                ProviderSubject = providerSubject
            });
            await dbContext.SaveChangesAsync();
        }

        var loginResponse = await _client.PostAsJsonAsync(
            "/api/auth/login-provider",
            new
            {
                provider = "microsoft",
                providerSubject,
                email
            });
        await EnsureSuccessWithBodyAsync(loginResponse);

        var loginResult = await loginResponse.Content.ReadFromJsonAsync<AuthResultDto>();
        Assert.NotNull(loginResult);
        Assert.True(loginResult!.RequiresMfa);
        Assert.NotNull(loginResult.MfaChallengeToken);
        Assert.Null(loginResult.AccessToken);

        var mfaResponse = await _client.PostAsJsonAsync(
            "/api/auth/mfa/complete",
            new
            {
                challengeToken = loginResult.MfaChallengeToken,
                code = TestAuthUtilities.CreateCurrentTotpCode("JBSWY3DPEHPK3PXP")
            });
        await EnsureSuccessWithBodyAsync(mfaResponse);

        var mfaResult = await mfaResponse.Content.ReadFromJsonAsync<AuthResultDto>();
        Assert.NotNull(mfaResult);
        Assert.False(mfaResult!.RequiresMfa);
        Assert.False(string.IsNullOrWhiteSpace(mfaResult.AccessToken));
        Assert.Equal("Bearer", mfaResult.TokenType);
    }

    private sealed record AuthResultDto(
        bool Success,
        string Message,
        Guid? UserId,
        UserRole? Role,
        string? UserName,
        string? Email,
        DateTimeOffset? RetryAfterUtc,
        string? AccessToken,
        DateTimeOffset? AccessTokenExpiresAtUtc,
        string? TokenType,
        bool RequiresMfa,
        bool MfaSetupRequired,
        string? MfaChallengeToken,
        DateTimeOffset? MfaChallengeExpiresAtUtc);

    private sealed record BeginExternalProviderAuthDto(string AuthorizationUrl, DateTimeOffset ExpiresAtUtc);

    private sealed record BootstrapStatusDto(bool BootstrapRequired, bool AdminUserExists, bool ModeratorBootstrapAvailable);

    private sealed record ManagedUserDto(
        Guid Id,
        string Email,
        string UserName,
        UserRole Role,
        bool IsApproved,
        bool IsSuspended,
        bool IsEmailVerified,
        bool IsProviderAccount);

    private sealed record AvailableExternalProviderDto(string Provider, string DisplayName);

    private static async Task EnsureSuccessWithBodyAsync(HttpResponseMessage response)
    {
        if (response.IsSuccessStatusCode)
        {
            return;
        }

        var body = await response.Content.ReadAsStringAsync();
        throw new Xunit.Sdk.XunitException($"Unexpected status {(int)response.StatusCode}: {body}");
    }

    private static string? ParseQueryParameter(Uri uri, string name)
    {
        var query = uri.Query.TrimStart('?');
        if (string.IsNullOrWhiteSpace(query))
        {
            return null;
        }

        foreach (var segment in query.Split('&', StringSplitOptions.RemoveEmptyEntries))
        {
            var parts = segment.Split('=', 2);
            var key = Uri.UnescapeDataString(parts[0]);
            if (!string.Equals(key, name, StringComparison.Ordinal))
            {
                continue;
            }

            return parts.Length == 2 ? Uri.UnescapeDataString(parts[1]) : string.Empty;
        }

        return null;
    }
}
