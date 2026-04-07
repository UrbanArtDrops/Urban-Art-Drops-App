using Microsoft.Extensions.Configuration;
using UrbanArtDropFinder.Application.Abstractions;

namespace UrbanArtDropFinder.Infrastructure.Services;

/// <summary>Resolves SMTP secret references from the application configuration provider chain.</summary>
public sealed class ConfigurationSmtpSecretResolver(IConfiguration configuration) : ISmtpSecretResolver
{
    public string? ResolveSecret(string? secretName)
    {
        var normalizedSecretName = secretName?.Trim();
        if (string.IsNullOrWhiteSpace(normalizedSecretName))
        {
            return null;
        }

        var secret = configuration[normalizedSecretName];
        return string.IsNullOrWhiteSpace(secret) ? null : secret;
    }
}
