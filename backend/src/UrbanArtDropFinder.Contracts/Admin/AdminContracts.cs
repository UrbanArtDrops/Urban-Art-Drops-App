namespace UrbanArtDropFinder.Contracts.Admin;

public sealed record UpdateAppConfigurationRequest(
    string? SmtpHost,
    int SmtpPort,
    string? SmtpUserName,
    string? SmtpUserEmail,
    string? PublicAppBaseUrl,
    int MainMapRadiusKm,
    int MiniMapRadiusKm,
    int UnclaimedDropRadiusKm,
    bool ShowExactPositionWhenFullyClaimed);

public sealed record TestSmtpConnectionRequest(
    string? SmtpHost,
    int SmtpPort,
    string? SmtpUserName,
    string? SmtpPassword);

public sealed record TestSmtpConnectionResponse(
    bool Success,
    string Message);

public sealed record ExternalProviderConfigurationStatusResponse(
    string Provider,
    string DisplayName,
    bool Enabled,
    bool VisibleOnLogin,
    bool HasClientId,
    bool HasClientSecret,
    bool UsesPkce);

public sealed record AppConfigurationResponse(
    string? SmtpHost,
    int SmtpPort,
    string? SmtpUserName,
    string? SmtpUserEmail,
    string? PublicAppBaseUrl,
    int MainMapRadiusKm,
    int MiniMapRadiusKm,
    int UnclaimedDropRadiusKm,
    bool ShowExactPositionWhenFullyClaimed,
    IReadOnlyCollection<ExternalProviderConfigurationStatusResponse> AuthProviders);
