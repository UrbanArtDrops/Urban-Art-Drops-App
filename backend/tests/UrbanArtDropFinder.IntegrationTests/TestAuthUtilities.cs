using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.Extensions.DependencyInjection;
using UrbanArtDropFinder.Domain.Users;
using UrbanArtDropFinder.Persistence.Db;

namespace UrbanArtDropFinder.IntegrationTests;

internal static class TestAuthUtilities
{
    internal sealed record AuthenticatedTestUser(
        Guid Id,
        string Email,
        string UserName,
        UserRole Role,
        string AccessToken);

    public static async Task<AuthenticatedTestUser> CreateAuthenticatedUserAsync(
        this TestWebApplicationFactory factory,
        UserRole role,
        string userName,
        bool approved = true,
        bool emailVerified = true,
        bool suspended = false)
    {
        const string password = "Aaaaaaaaaaaaaaa!";

        using var scope = factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<UrbanArtDbContext>();
        var passwordHasher = scope.ServiceProvider.GetRequiredService<UrbanArtDropFinder.Application.Abstractions.IPasswordHasher>();
        var email = $"{userName}@example.com";
        var user = UserAccount.CreateLocal(email, userName, role, passwordHasher.Hash(password), approved);
        if (emailVerified)
        {
            user.MarkEmailVerified();
        }

        user.SetSuspended(suspended);
        await dbContext.UserAccounts.AddAsync(user);
        await dbContext.SaveChangesAsync();

        if (!approved || !emailVerified || suspended)
        {
            throw new InvalidOperationException(
                "Authenticated test users must be approved, email-verified and not suspended.");
        }

        using var client = factory.CreateClient();
        using var loginResponse = await client.PostAsJsonAsync(
            "/api/auth/login-local",
            new
            {
                email,
                password
            });
        loginResponse.EnsureSuccessStatusCode();

        var loginPayload = await loginResponse.Content.ReadFromJsonAsync<LoginResultDto>();
        if (loginPayload is null || string.IsNullOrWhiteSpace(loginPayload.AccessToken))
        {
            throw new InvalidOperationException("Login did not return a bearer token for the authenticated test user.");
        }

        var accessToken = loginPayload.AccessToken;
        return new AuthenticatedTestUser(user.Id, email, user.UserName, role, accessToken);
    }

    public static Task<HttpResponseMessage> GetAuthorizedAsync(this HttpClient client, string path, string accessToken)
        => client.SendAuthorizedAsync(new HttpRequestMessage(HttpMethod.Get, path), accessToken);

    public static Task<HttpResponseMessage> DeleteAuthorizedAsync(this HttpClient client, string path, string accessToken)
        => client.SendAuthorizedAsync(new HttpRequestMessage(HttpMethod.Delete, path), accessToken);

    public static Task<HttpResponseMessage> PostAuthorizedAsync(this HttpClient client, string path, string accessToken)
        => client.SendAuthorizedAsync(new HttpRequestMessage(HttpMethod.Post, path), accessToken);

    public static Task<HttpResponseMessage> PostAuthorizedAsJsonAsync<T>(
        this HttpClient client,
        string path,
        T payload,
        string accessToken)
    {
        var request = new HttpRequestMessage(HttpMethod.Post, path)
        {
            Content = JsonContent.Create(payload)
        };
        return client.SendAuthorizedAsync(request, accessToken);
    }

    public static Task<HttpResponseMessage> PutAuthorizedAsJsonAsync<T>(
        this HttpClient client,
        string path,
        T payload,
        string accessToken)
    {
        var request = new HttpRequestMessage(HttpMethod.Put, path)
        {
            Content = JsonContent.Create(payload)
        };
        return client.SendAuthorizedAsync(request, accessToken);
    }

    private static Task<HttpResponseMessage> SendAuthorizedAsync(
        this HttpClient client,
        HttpRequestMessage request,
        string accessToken)
    {
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        return client.SendAsync(request);
    }

    private sealed record LoginResultDto(string? AccessToken);
}
