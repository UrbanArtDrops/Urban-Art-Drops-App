namespace UrbanArtDropFinder.Domain.Configuration;

public sealed class AppConfiguration
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public string? SmtpHost { get; set; }
    public int SmtpPort { get; set; } = 465;
    public SmtpSecurityMode SmtpSecurityMode { get; set; } = SmtpSecurityMode.Tls;
    public string? SmtpUserName { get; set; }
    public string? SmtpUserEmail { get; set; }
    public string? SmtpPasswordSecretName { get; set; }
    public string? PublicAppBaseUrl { get; set; }
    public int MainMapRadiusKm { get; set; } = 30;
    public int MiniMapRadiusKm { get; set; } = 5;
    public int UnclaimedDropRadiusKm { get; set; } = 3;
    public bool ShowExactPositionWhenFullyClaimed { get; set; } = true;
}
