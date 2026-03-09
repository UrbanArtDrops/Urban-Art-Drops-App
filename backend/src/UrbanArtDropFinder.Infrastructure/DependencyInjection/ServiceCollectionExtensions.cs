using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Application.Auth;
using UrbanArtDropFinder.Application.Drops;
using UrbanArtDropFinder.Infrastructure.Services;
using UrbanArtDropFinder.Infrastructure.Stores;
using UrbanArtDropFinder.Persistence.Db;

namespace UrbanArtDropFinder.Infrastructure.DependencyInjection;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddUrbanArtInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var sqlServerConnectionString = configuration.GetConnectionString("SqlServer");
        if (string.IsNullOrWhiteSpace(sqlServerConnectionString))
        {
            services.AddDbContext<UrbanArtDbContext>(options =>
                options.UseInMemoryDatabase("urban-art-drops-dev"));
        }
        else
        {
            services.AddDbContext<UrbanArtDbContext>(options =>
                options.UseSqlServer(sqlServerConnectionString));
        }

        services.AddScoped<IUserAccountStore, UserAccountStore>();
        services.AddSingleton<IPasswordHasher, Pbkdf2PasswordHasher>();
        services.AddSingleton<ITokenGenerator, SecureTokenGenerator>();
        services.AddSingleton<IClock, SystemClock>();
        services.AddScoped<AuthApplicationService>();
        services.AddScoped<DropClaimApplicationService>();

        return services;
    }
}
