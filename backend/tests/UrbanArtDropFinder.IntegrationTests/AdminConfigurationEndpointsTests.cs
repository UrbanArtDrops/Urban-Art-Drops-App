using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using UrbanArtDropFinder.Application.Abstractions;
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
                smtpPort = 2525,
                smtpUserName = "mailer-user",
                smtpUserEmail = "mailer@example.test",
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
        Assert.Equal(2525, payload.SmtpPort);
        Assert.Equal("mailer-user", payload.SmtpUserName);
        Assert.Equal("mailer@example.test", payload.SmtpUserEmail);
        Assert.Equal("https://app.example.test", payload.PublicAppBaseUrl);
        Assert.Equal(42, payload.MainMapRadiusKm);
        Assert.Equal(7, payload.MiniMapRadiusKm);
        Assert.Equal(4, payload.UnclaimedDropRadiusKm);
        Assert.False(payload.ShowExactPositionWhenFullyClaimed);
        Assert.NotEmpty(payload.AuthProviders);
        Assert.Contains(
            payload.AuthProviders,
            provider => provider.Provider == "google"
                && provider.Enabled
                && provider.VisibleOnLogin
                && provider.HasClientId
                && provider.HasClientSecret);
        Assert.Contains(
            payload.AuthProviders,
            provider => provider.Provider == "facebook"
                && !provider.Enabled
                && !provider.VisibleOnLogin
                && !provider.HasClientId
                && !provider.HasClientSecret);
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

    [Fact]
    public async Task SmtpConnectionTestEndpoint_UsesSuppliedSecret_WithoutPersistingIt()
    {
        var admin = await _factory.CreateAuthenticatedUserAsync(
            UserRole.Admin,
            $"admin.smtp.{Guid.NewGuid():N}");

        _factory.SmtpConnectionTester.Handler = static (_, _, _, _, _) =>
            Task.FromResult(new SmtpConnectionTestResult(true, "SMTP connection successful."));

        var response = await _client.PostAuthorizedAsJsonAsync(
            "/api/admin/configuration/smtp/test",
            new
            {
                smtpHost = "smtp.example.test",
                smtpPort = 587,
                smtpUserName = "mailer-user",
                smtpPassword = "TopSecretPassword!123"
            },
            admin.AccessToken);
        await EnsureSuccessWithBodyAsync(response);

        var payload = await response.Content.ReadFromJsonAsync<SmtpConnectionTestDto>();
        Assert.NotNull(payload);
        Assert.True(payload!.Success);
        Assert.Equal("SMTP connection successful.", payload.Message);
        Assert.Equal("smtp.example.test", _factory.SmtpConnectionTester.LastRequest?.Host);
        Assert.Equal(587, _factory.SmtpConnectionTester.LastRequest?.Port);
        Assert.Equal("mailer-user", _factory.SmtpConnectionTester.LastRequest?.UserName);
        Assert.Equal("TopSecretPassword!123", _factory.SmtpConnectionTester.LastRequest?.Password);

        var configurationResponse = await _client.GetAuthorizedAsync(
            "/api/admin/configuration",
            admin.AccessToken);
        await EnsureSuccessWithBodyAsync(configurationResponse);
        var configuration = await configurationResponse.Content.ReadFromJsonAsync<AppConfigurationDto>();
        Assert.NotNull(configuration);
        Assert.Null(configuration!.SmtpPassword);
    }

    private sealed record AppConfigurationDto(
        string SmtpHost,
        int SmtpPort,
        string? SmtpUserName,
        string? SmtpUserEmail,
        string? SmtpPassword,
        string PublicAppBaseUrl,
        int MainMapRadiusKm,
        int MiniMapRadiusKm,
        int UnclaimedDropRadiusKm,
        bool ShowExactPositionWhenFullyClaimed,
        IReadOnlyCollection<AuthProviderStatusDto> AuthProviders);

    private sealed record SmtpConnectionTestDto(
        bool Success,
        string Message);

    private sealed record AuthProviderStatusDto(
        string Provider,
        string DisplayName,
        bool Enabled,
        bool VisibleOnLogin,
        bool HasClientId,
        bool HasClientSecret,
        bool UsesPkce);

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
