using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Domain.Users;
using UrbanArtDropFinder.Infrastructure.Authentication;

namespace UrbanArtDropFinder.Infrastructure.Services;

public sealed class JwtMfaChallengeTokenService : IMfaChallengeTokenService
{
    private const string ModeClaimType = "urbanart:mfa:mode";
    private const string SecretClaimType = "urbanart:mfa:secret";
    private const string MfaAudience = "UrbanArtDrops.Mfa";
    private static readonly TimeSpan ChallengeLifetime = TimeSpan.FromMinutes(10);

    private readonly JwtAuthenticationOptions _options;
    private readonly IClock _clock;

    public JwtMfaChallengeTokenService(IOptions<JwtAuthenticationOptions> options, IClock clock)
    {
        _options = options.Value;
        _clock = clock;
    }

    public MfaChallengeTokenEnvelope CreateVerificationChallenge(UserAccount user)
        => CreateToken(user.Id, MfaChallengeMode.Verify, null);

    public MfaChallengeTokenEnvelope CreateSetupChallenge(UserAccount user, string secretKey)
        => CreateToken(user.Id, MfaChallengeMode.Setup, secretKey);

    public MfaChallengePayload? ReadChallenge(string token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            return null;
        }

        var tokenHandler = new JwtSecurityTokenHandler();

        try
        {
            tokenHandler.ValidateToken(
                token,
                new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidateAudience = true,
                    ValidateIssuerSigningKey = true,
                    ValidateLifetime = true,
                    ValidIssuer = _options.Issuer,
                    ValidAudience = MfaAudience,
                    IssuerSigningKey = CreateSigningKey(),
                    ClockSkew = TimeSpan.FromSeconds(30)
                },
                out var validatedToken);

            var jwtToken = validatedToken as JwtSecurityToken;
            var userIdRaw = jwtToken?.Claims.FirstOrDefault(claim => claim.Type == ClaimTypes.NameIdentifier)?.Value;
            var modeRaw = jwtToken?.Claims.FirstOrDefault(claim => claim.Type == ModeClaimType)?.Value;
            if (!Guid.TryParse(userIdRaw, out var userId) ||
                !Enum.TryParse<MfaChallengeMode>(modeRaw, true, out var mode))
            {
                return null;
            }

            var expiresAtUtc = jwtToken?.ValidTo;
            if (expiresAtUtc is null || expiresAtUtc == DateTime.MinValue)
            {
                return null;
            }

            var secret = jwtToken?.Claims.FirstOrDefault(claim => claim.Type == SecretClaimType)?.Value;
            return new MfaChallengePayload(
                userId,
                mode,
                string.IsNullOrWhiteSpace(secret) ? null : secret,
                new DateTimeOffset(expiresAtUtc.Value, TimeSpan.Zero));
        }
        catch
        {
            return null;
        }
    }

    private MfaChallengeTokenEnvelope CreateToken(Guid userId, MfaChallengeMode mode, string? secretKey)
    {
        var issuedAtUtc = _clock.UtcNow;
        var expiresAtUtc = issuedAtUtc.Add(ChallengeLifetime);
        var credentials = new SigningCredentials(CreateSigningKey(), SecurityAlgorithms.HmacSha256);
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new(ClaimTypes.NameIdentifier, userId.ToString()),
            new(ModeClaimType, mode.ToString())
        };

        if (!string.IsNullOrWhiteSpace(secretKey))
        {
            claims.Add(new Claim(SecretClaimType, secretKey));
        }

        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: MfaAudience,
            claims: claims,
            notBefore: issuedAtUtc.UtcDateTime,
            expires: expiresAtUtc.UtcDateTime,
            signingCredentials: credentials);
        var serializedToken = new JwtSecurityTokenHandler().WriteToken(token);
        return new MfaChallengeTokenEnvelope(serializedToken, expiresAtUtc);
    }

    private SymmetricSecurityKey CreateSigningKey()
        => new(Encoding.UTF8.GetBytes(_options.SigningKey!));
}
