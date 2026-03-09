namespace UrbanArtDropFinder.Domain.Configuration;

public sealed class AppConfiguration
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string? SmtpHost { get; set; }
    public int MainMapRadiusKm { get; set; } = 30;
    public int MiniMapRadiusKm { get; set; } = 5;
    public int UnclaimedDropRadiusKm { get; set; } = 3;
    public bool ShowExactPositionWhenFullyClaimed { get; set; } = true;
}
