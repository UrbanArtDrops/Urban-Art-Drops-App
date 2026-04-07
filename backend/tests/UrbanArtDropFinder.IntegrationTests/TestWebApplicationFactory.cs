using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Persistence.Db;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class TestWebApplicationFactory : WebApplicationFactory<Program>
{
    public FakeSmtpConnectionTester SmtpConnectionTester { get; } = new();
    public FakeSmtpMailSender SmtpMailSender { get; } = new();
    public FakeSocialMediaPublisher SocialMediaPublisher { get; } = new();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        var databaseName = $"urban-art-drops-tests-{Guid.NewGuid():N}";

        builder.ConfigureAppConfiguration((_, configurationBuilder) =>
        {
            configurationBuilder.AddInMemoryCollection(
                new Dictionary<string, string?>
                {
                    ["Persistence:Provider"] = "InMemory",
                    ["Persistence:InMemoryDatabaseName"] = databaseName,
                    ["Authentication:Jwt:Issuer"] = "UrbanArtDrops.Tests",
                    ["Authentication:Jwt:Audience"] = "UrbanArtDrops.Tests.Client",
                    ["Authentication:Jwt:SigningKey"] = "UrbanArtDrops_IntegrationTests_Only_Signing_Key_1234567890",
                    ["Authentication:ExternalProviders:Providers:google:Enabled"] = "true",
                    ["Authentication:ExternalProviders:Providers:google:ClientId"] = "tests-google-client-id",
                    ["Authentication:ExternalProviders:Providers:google:ClientSecret"] = "tests-google-client-secret",
                    ["Authentication:ExternalProviders:Providers:google:AuthorizationEndpoint"] = "https://provider.test/oauth/authorize",
                    ["Authentication:ExternalProviders:Providers:google:TokenEndpoint"] = "https://provider.test/oauth/token",
                    ["Authentication:ExternalProviders:Providers:google:UserInfoEndpoint"] = "https://provider.test/oauth/userinfo",
                    ["Authentication:ExternalProviders:Providers:microsoft:Enabled"] = "true",
                    ["Authentication:ExternalProviders:Providers:microsoft:ClientId"] = "tests-microsoft-client-id",
                    ["Authentication:ExternalProviders:Providers:microsoft:ClientSecret"] = "tests-microsoft-client-secret",
                    ["Authentication:ExternalProviders:Providers:microsoft:AuthorizationEndpoint"] = "https://provider.test/oauth/authorize",
                    ["Authentication:ExternalProviders:Providers:microsoft:TokenEndpoint"] = "https://provider.test/oauth/token",
                    ["Authentication:ExternalProviders:Providers:microsoft:UserInfoEndpoint"] = "https://provider.test/oauth/userinfo",
                    ["Smtp:Password"] = "TestSmtpPassword!123",
                    ["ConnectionStrings:SqlServer"] =
                        "Server=(localdb)\\MSSQLLocalDB;Database=UrbanArtDropFinder.Tests.Placeholder;Trusted_Connection=True;TrustServerCertificate=True"
                });
        });

        builder.ConfigureServices(services =>
        {
            for (var index = services.Count - 1; index >= 0; index--)
            {
                var serviceType = services[index].ServiceType;
                if (serviceType == typeof(UrbanArtDbContext)
                    || serviceType == typeof(DbContextOptions)
                    || serviceType == typeof(DbContextOptions<UrbanArtDbContext>)
                    || (serviceType.IsGenericType
                        && serviceType.GenericTypeArguments.Length == 1
                        && serviceType.GenericTypeArguments[0] == typeof(UrbanArtDbContext)))
                {
                    services.RemoveAt(index);
                }
            }

            services.AddDbContext<UrbanArtDbContext>(options =>
                options.UseInMemoryDatabase(databaseName));
            services.AddHttpClient("external-auth")
                .ConfigurePrimaryHttpMessageHandler(() => new FakeExternalProviderHttpMessageHandler());
            services.RemoveAll<ISmtpConnectionTester>();
            services.AddSingleton<ISmtpConnectionTester>(SmtpConnectionTester);
            services.RemoveAll<ISmtpMailSender>();
            services.AddSingleton<ISmtpMailSender>(SmtpMailSender);
            services.RemoveAll<ISocialMediaPublisher>();
            services.AddSingleton<ISocialMediaPublisher>(SocialMediaPublisher);
        });
    }
}
