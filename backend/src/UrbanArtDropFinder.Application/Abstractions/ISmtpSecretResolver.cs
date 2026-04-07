namespace UrbanArtDropFinder.Application.Abstractions;

/// <summary>Resolves named SMTP secrets from the runtime configuration boundary.</summary>
public interface ISmtpSecretResolver
{
    /// <summary>Returns the configured secret value for the supplied name, or <c>null</c> when it is not configured.</summary>
    string? ResolveSecret(string? secretName);
}
