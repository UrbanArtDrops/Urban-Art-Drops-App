using Microsoft.Extensions.Options;

namespace UrbanArtDropFinder.Infrastructure.Authentication;

public sealed class ExternalProviderStatusService
{
    private static readonly string[] SupportedProviders =
    [
        "google",
        "facebook",
        "instagram",
        "tiktok",
        "microsoft"
    ];

    private readonly ExternalProviderAuthenticationOptions _options;

    public ExternalProviderStatusService(IOptions<ExternalProviderAuthenticationOptions> options)
    {
        _options = options.Value;
    }

    public IReadOnlyList<ExternalProviderStatusSnapshot> GetProviderStatuses()
    {
        return SupportedProviders
            .Select(BuildStatus)
            .ToList();
    }

    private ExternalProviderStatusSnapshot BuildStatus(string provider)
    {
        var defaults = KnownExternalProviderDefaults.Get(provider);
        _options.Providers.TryGetValue(provider, out var configuredProvider);
        var resolvedProvider = defaults?.MergeWith(configuredProvider) ?? configuredProvider?.Clone();

        var enabled = resolvedProvider?.Enabled == true;
        var hasClientId = !string.IsNullOrWhiteSpace(resolvedProvider?.ClientId);
        var hasClientSecret = !string.IsNullOrWhiteSpace(resolvedProvider?.ClientSecret);
        var hasAuthorizationEndpoint = !string.IsNullOrWhiteSpace(resolvedProvider?.AuthorizationEndpoint);
        var hasTokenEndpoint = !string.IsNullOrWhiteSpace(resolvedProvider?.TokenEndpoint);

        return new ExternalProviderStatusSnapshot(
            Provider: provider,
            DisplayName: resolvedProvider?.DisplayName?.Trim() is { Length: > 0 } displayName
                ? displayName
                : provider,
            Enabled: enabled,
            VisibleOnLogin: enabled && hasClientId && hasAuthorizationEndpoint && hasTokenEndpoint,
            HasClientId: hasClientId,
            HasClientSecret: hasClientSecret,
            UsesPkce: resolvedProvider?.UsePkce == true);
    }
}

public sealed record ExternalProviderStatusSnapshot(
    string Provider,
    string DisplayName,
    bool Enabled,
    bool VisibleOnLogin,
    bool HasClientId,
    bool HasClientSecret,
    bool UsesPkce);
