using System.Security.Cryptography;
using UrbanArtDropFinder.Application.Abstractions;

namespace UrbanArtDropFinder.Infrastructure.Services;

public sealed class SecureTokenGenerator : ITokenGenerator
{
    public string GenerateSecureToken(int bytesLength = 32)
    {
        var bytes = RandomNumberGenerator.GetBytes(bytesLength);
        return Convert.ToBase64String(bytes)
            .Replace('+', '-')
            .Replace('/', '_')
            .TrimEnd('=');
    }
}
