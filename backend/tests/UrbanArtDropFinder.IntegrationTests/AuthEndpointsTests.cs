using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class AuthEndpointsTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;

    public AuthEndpointsTests(TestWebApplicationFactory factory)
    {
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

        var usersResponse = await _client.GetAsync("/api/admin/users");
        await EnsureSuccessWithBodyAsync(usersResponse);
        var users = await usersResponse.Content.ReadFromJsonAsync<List<ManagedUserDto>>();
        Assert.NotNull(users);

        var createdUser = users!.Single(user => string.Equals(user.Email, email, StringComparison.OrdinalIgnoreCase));
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

    private sealed record AuthResultDto(
        bool Success,
        string Message,
        Guid? UserId,
        UserRole? Role,
        string? UserName,
        string? Email,
        DateTimeOffset? RetryAfterUtc);

    private sealed record ManagedUserDto(
        Guid Id,
        string Email,
        string UserName,
        UserRole Role,
        bool IsApproved,
        bool IsSuspended,
        bool IsEmailVerified,
        bool IsProviderAccount);

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
