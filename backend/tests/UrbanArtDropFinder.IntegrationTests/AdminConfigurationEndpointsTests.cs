using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class AdminConfigurationEndpointsTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly TestWebApplicationFactory _factory;

    public AdminConfigurationEndpointsTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task ConfigurationEndpoints_PersistUpdatedValues_ForAdmin()
    {
        var admin = await _factory.CreateAuthenticatedUserAsync(
            UserRole.Admin,
            $"admin.config.{Guid.NewGuid():N}");

        var updateResponse = await _client.PutAuthorizedAsJsonAsync(
            "/api/admin/configuration",
            new
            {
                smtpHost = "smtp.example.test",
                publicAppBaseUrl = "https://app.example.test",
                mainMapRadiusKm = 42,
                miniMapRadiusKm = 7,
                unclaimedDropRadiusKm = 4,
                showExactPositionWhenFullyClaimed = false
            },
            admin.AccessToken);
        await EnsureSuccessWithBodyAsync(updateResponse);

        var getResponse = await _client.GetAuthorizedAsync(
            "/api/admin/configuration",
            admin.AccessToken);
        await EnsureSuccessWithBodyAsync(getResponse);

        var payload = await getResponse.Content.ReadFromJsonAsync<AppConfigurationDto>();
        Assert.NotNull(payload);
        Assert.Equal("smtp.example.test", payload!.SmtpHost);
        Assert.Equal("https://app.example.test", payload.PublicAppBaseUrl);
        Assert.Equal(42, payload.MainMapRadiusKm);
        Assert.Equal(7, payload.MiniMapRadiusKm);
        Assert.Equal(4, payload.UnclaimedDropRadiusKm);
        Assert.False(payload.ShowExactPositionWhenFullyClaimed);
    }

    [Fact]
    public async Task ConfigurationEndpoints_RejectNonAdmins()
    {
        var hunter = await _factory.CreateAuthenticatedUserAsync(
            UserRole.Hunter,
            $"hunter.config.{Guid.NewGuid():N}");

        var response = await _client.GetAuthorizedAsync(
            "/api/admin/configuration",
            hunter.AccessToken);

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    private sealed record AppConfigurationDto(
        string SmtpHost,
        string PublicAppBaseUrl,
        int MainMapRadiusKm,
        int MiniMapRadiusKm,
        int UnclaimedDropRadiusKm,
        bool ShowExactPositionWhenFullyClaimed);

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
