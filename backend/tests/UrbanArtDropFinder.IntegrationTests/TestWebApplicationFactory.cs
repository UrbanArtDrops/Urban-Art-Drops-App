using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using UrbanArtDropFinder.Persistence.Db;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class TestWebApplicationFactory : WebApplicationFactory<Program>
{
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
        });
    }
}
