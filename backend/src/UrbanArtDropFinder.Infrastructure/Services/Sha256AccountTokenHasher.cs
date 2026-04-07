using System.Security.Cryptography;
using System.Text;
using UrbanArtDropFinder.Application.Abstractions;

namespace UrbanArtDropFinder.Infrastructure.Services;

public sealed class Sha256AccountTokenHasher : IAccountTokenHasher
{
    public string HashToken(string token)
    {
        if (string.IsNullOrWhiteSpace(token))
        {
            throw new ArgumentException("Token is required.", nameof(token));
        }

        var tokenBytes = Encoding.UTF8.GetBytes(token.Trim());
        var hashBytes = SHA256.HashData(tokenBytes);
        return Convert.ToBase64String(hashBytes);
    }

    public bool VerifyToken(string? tokenHash, string token)
    {
        if (string.IsNullOrWhiteSpace(tokenHash) || string.IsNullOrWhiteSpace(token))
        {
            return false;
        }

        byte[] expectedHash;
        try
        {
            expectedHash = Convert.FromBase64String(tokenHash);
        }
        catch (FormatException)
        {
            return false;
        }

        var providedHash = SHA256.HashData(Encoding.UTF8.GetBytes(token.Trim()));
        return expectedHash.Length == providedHash.Length &&
            CryptographicOperations.FixedTimeEquals(expectedHash, providedHash);
    }
}
