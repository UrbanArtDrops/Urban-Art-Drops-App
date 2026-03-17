using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Application.Abstractions;

public interface IAccessTokenIssuer
{
    AccessTokenEnvelope IssueToken(UserAccount user, bool mfaVerified);
}

public sealed record AccessTokenEnvelope(
    string AccessToken,
    DateTimeOffset ExpiresAtUtc,
    string TokenType = "Bearer");
