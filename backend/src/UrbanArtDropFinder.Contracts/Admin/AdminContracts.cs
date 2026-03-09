namespace UrbanArtDropFinder.Contracts.Admin;

public sealed record UpdateAppConfigurationRequest(
    string? SmtpHost,
    int MainMapRadiusKm,
    int MiniMapRadiusKm,
    int UnclaimedDropRadiusKm,
    bool ShowExactPositionWhenFullyClaimed);
