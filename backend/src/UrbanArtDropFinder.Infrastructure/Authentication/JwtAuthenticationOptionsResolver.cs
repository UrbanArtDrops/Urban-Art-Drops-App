using System.Security.Cryptography;
using Microsoft.Extensions.Configuration;

namespace UrbanArtDropFinder.Infrastructure.Authentication;

public static class JwtAuthenticationOptionsResolver
{
    public static JwtAuthenticationOptions Resolve(IConfiguration configuration, string environmentName)
    {
        var options = new JwtAuthenticationOptions
        {
            Issuer = configuration[$"{JwtAuthenticationOptions.SectionName}:Issuer"] ?? "UrbanArtDrops",
            Audience = configuration[$"{JwtAuthenticationOptions.SectionName}:Audience"] ?? "UrbanArtDrops.Client",
            SigningKey = configuration[$"{JwtAuthenticationOptions.SectionName}:SigningKey"],
            AccessTokenLifetimeMinutes =
                int.TryParse(configuration[$"{JwtAuthenticationOptions.SectionName}:AccessTokenLifetimeMinutes"], out var lifetimeMinutes)
                    ? lifetimeMinutes
                    : 480
        };

        if (string.IsNullOrWhiteSpace(options.SigningKey) && CanUseEphemeralDevelopmentKey(environmentName))
        {
            options.SigningKey = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
        }

        if (string.IsNullOrWhiteSpace(options.Issuer) ||
            string.IsNullOrWhiteSpace(options.Audience) ||
            string.IsNullOrWhiteSpace(options.SigningKey) ||
            options.AccessTokenLifetimeMinutes <= 0)
        {
            throw new InvalidOperationException(
                "JWT authentication settings are invalid. Configure Authentication:Jwt:Issuer, Audience and SigningKey. " +
                "For local development, prefer dotnet user-secrets or environment variables.");
        }

        return options;
    }

    private static bool CanUseEphemeralDevelopmentKey(string environmentName)
        => string.Equals(environmentName, "Development", StringComparison.OrdinalIgnoreCase)
           || string.Equals(environmentName, "Testing", StringComparison.OrdinalIgnoreCase);
}
