using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
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

        if (role is UserRole.Admin or UserRole.Moderator)
        {
            user.EnableMfa("JBSWY3DPEHPK3PXP");
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
        if (loginPayload is null)
        {
            throw new InvalidOperationException("Login did not return a payload for the authenticated test user.");
        }

        if (loginPayload.RequiresMfa)
        {
            if (string.IsNullOrWhiteSpace(loginPayload.MfaChallengeToken))
            {
                throw new InvalidOperationException("MFA login did not return a challenge token.");
            }

            var code = CreateCurrentTotpCode("JBSWY3DPEHPK3PXP");
            using var mfaResponse = await client.PostAsJsonAsync(
                "/api/auth/mfa/complete",
                new
                {
                    challengeToken = loginPayload.MfaChallengeToken,
                    code
                });
            mfaResponse.EnsureSuccessStatusCode();
            loginPayload = await mfaResponse.Content.ReadFromJsonAsync<LoginResultDto>();
        }

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

    public static Task<HttpResponseMessage> PatchAuthorizedAsJsonAsync<T>(
        this HttpClient client,
        string path,
        T payload,
        string accessToken)
    {
        var request = new HttpRequestMessage(HttpMethod.Patch, path)
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

    internal static string CreateCurrentTotpCode(string secretKey, DateTimeOffset? nowUtc = null)
    {
        var secret = DecodeBase32(secretKey);
        var unixTime = (nowUtc ?? DateTimeOffset.UtcNow).ToUnixTimeSeconds();
        var counter = unixTime / 30;
        Span<byte> counterBytes = stackalloc byte[8];
        for (var index = 7; index >= 0; index -= 1)
        {
            counterBytes[index] = (byte)(counter & 0xFF);
            counter >>= 8;
        }

        using var hmac = new HMACSHA1(secret);
        var hash = hmac.ComputeHash(counterBytes.ToArray());
        var offset = hash[^1] & 0x0F;
        var binaryCode =
            ((hash[offset] & 0x7F) << 24) |
            (hash[offset + 1] << 16) |
            (hash[offset + 2] << 8) |
            hash[offset + 3];
        return (binaryCode % 1_000_000).ToString("D6");
    }

    private sealed record LoginResultDto(
        string? AccessToken,
        bool RequiresMfa,
        string? MfaChallengeToken);

    private static byte[] DecodeBase32(string input)
    {
        var normalized = input.Trim().TrimEnd('=').ToUpperInvariant();
        if (normalized.Length == 0)
        {
            return [];
        }

        var output = new List<byte>((normalized.Length * 5) / 8);
        var buffer = 0;
        var bitsInBuffer = 0;
        foreach (var character in normalized)
        {
            var value = character switch
            {
                >= 'A' and <= 'Z' => character - 'A',
                >= '2' and <= '7' => character - '2' + 26,
                _ => throw new InvalidOperationException("Invalid base32 character.")
            };
            buffer = (buffer << 5) | value;
            bitsInBuffer += 5;
            while (bitsInBuffer >= 8)
            {
                bitsInBuffer -= 8;
                output.Add((byte)((buffer >> bitsInBuffer) & 0xFF));
            }
        }

        return output.ToArray();
    }
}
