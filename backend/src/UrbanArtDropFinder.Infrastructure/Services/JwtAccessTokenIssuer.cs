using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Domain.Users;
using UrbanArtDropFinder.Infrastructure.Authentication;

namespace UrbanArtDropFinder.Infrastructure.Services;

public sealed class JwtAccessTokenIssuer : IAccessTokenIssuer
{
    private readonly JwtAuthenticationOptions _options;
    private readonly IClock _clock;

    public JwtAccessTokenIssuer(IOptions<JwtAuthenticationOptions> options, IClock clock)
    {
        _options = options.Value;
        _clock = clock;
    }

    public AccessTokenEnvelope IssueToken(UserAccount user, bool mfaVerified)
    {
        var issuedAtUtc = _clock.UtcNow;
        var expiresAtUtc = issuedAtUtc.AddMinutes(_options.AccessTokenLifetimeMinutes);
        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.SigningKey!));
        var credentials = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.UserName),
            new Claim(ClaimTypes.Role, user.Role.ToString()),
            new Claim("urbanart:mfa", mfaVerified ? "true" : "false"),
        };

        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            notBefore: issuedAtUtc.UtcDateTime,
            expires: expiresAtUtc.UtcDateTime,
            signingCredentials: credentials);

        var serializedToken = new JwtSecurityTokenHandler().WriteToken(token);
        return new AccessTokenEnvelope(serializedToken, expiresAtUtc);
    }
}
