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
