namespace UrbanArtDropFinder.Application.Abstractions;

public interface ITokenGenerator
{
    string GenerateSecureToken(int bytesLength = 32);
}
