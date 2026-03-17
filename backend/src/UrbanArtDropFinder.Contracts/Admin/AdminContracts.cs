namespace UrbanArtDropFinder.Contracts.Admin;

public sealed record UpdateAppConfigurationRequest(
    string? SmtpHost,
    string? PublicAppBaseUrl,
    int MainMapRadiusKm,
    int MiniMapRadiusKm,
    int UnclaimedDropRadiusKm,
    bool ShowExactPositionWhenFullyClaimed);
