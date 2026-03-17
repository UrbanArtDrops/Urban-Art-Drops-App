using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Application.Auth;
using UrbanArtDropFinder.Infrastructure.Authentication;
using UrbanArtDropFinder.Application.Drops;
using UrbanArtDropFinder.Infrastructure.Services;
using UrbanArtDropFinder.Infrastructure.Stores;
using UrbanArtDropFinder.Persistence.Db;

namespace UrbanArtDropFinder.Infrastructure.DependencyInjection;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddUrbanArtInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration,
        JwtAuthenticationOptions jwtOptions)
    {
        services
            .AddSingleton<IOptions<JwtAuthenticationOptions>>(_ => Options.Create(jwtOptions));

        var persistenceProvider = configuration["Persistence:Provider"];
        if (string.Equals(persistenceProvider, "InMemory", StringComparison.OrdinalIgnoreCase))
        {
            var databaseName = configuration["Persistence:InMemoryDatabaseName"];
            if (string.IsNullOrWhiteSpace(databaseName))
            {
                throw new InvalidOperationException(
                    "Configuration 'Persistence:InMemoryDatabaseName' is required when using the in-memory persistence provider.");
            }

            services.AddDbContext<UrbanArtDbContext>(options =>
                options.UseInMemoryDatabase(databaseName));

            RegisterApplicationServices(services);
            return services;
        }

        if (!string.IsNullOrWhiteSpace(persistenceProvider)
            && !string.Equals(persistenceProvider, "SqlServer", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException(
                $"Unsupported persistence provider '{persistenceProvider}'. Supported values are 'SqlServer' and 'InMemory'.");
        }

        var sqlServerConnectionString = configuration.GetConnectionString("SqlServer");
        if (string.IsNullOrWhiteSpace(sqlServerConnectionString))
        {
            throw new InvalidOperationException(
                "Connection string 'SqlServer' is required. Configure a SQL Server or LocalDB database before starting the API.");
        }

        services.AddDbContext<UrbanArtDbContext>(options =>
            options.UseSqlServer(sqlServerConnectionString));

        RegisterApplicationServices(services);
        return services;
    }

    private static void RegisterApplicationServices(IServiceCollection services)
    {
        services.AddScoped<IUserAccountStore, UserAccountStore>();
        services.AddSingleton<IPasswordHasher, Pbkdf2PasswordHasher>();
        services.AddSingleton<ITokenGenerator, SecureTokenGenerator>();
        services.AddSingleton<IAccessTokenIssuer, JwtAccessTokenIssuer>();
        services.AddSingleton<IClock, SystemClock>();
        services.AddScoped<AuthApplicationService>();
        services.AddScoped<DropClaimApplicationService>();
    }
}
