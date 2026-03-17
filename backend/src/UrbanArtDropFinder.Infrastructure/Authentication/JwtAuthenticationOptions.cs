namespace UrbanArtDropFinder.Infrastructure.Authentication;

public sealed class JwtAuthenticationOptions
{
    public const string SectionName = "Authentication:Jwt";

    public string Issuer { get; set; } = "UrbanArtDrops";

    public string Audience { get; set; } = "UrbanArtDrops.Client";

    public string? SigningKey { get; set; }

    public int AccessTokenLifetimeMinutes { get; set; } = 480;
}
