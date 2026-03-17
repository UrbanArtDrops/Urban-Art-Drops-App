using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Application.Abstractions;

public interface IMfaChallengeTokenService
{
    MfaChallengeTokenEnvelope CreateVerificationChallenge(UserAccount user);

    MfaChallengeTokenEnvelope CreateSetupChallenge(UserAccount user, string secretKey);

    MfaChallengePayload? ReadChallenge(string token);
}

public sealed record MfaChallengeTokenEnvelope(
    string Token,
    DateTimeOffset ExpiresAtUtc);

public sealed record MfaChallengePayload(
    Guid UserId,
    MfaChallengeMode Mode,
    string? SecretKey,
    DateTimeOffset ExpiresAtUtc);

public enum MfaChallengeMode
{
    Verify = 0,
    Setup = 1
}
