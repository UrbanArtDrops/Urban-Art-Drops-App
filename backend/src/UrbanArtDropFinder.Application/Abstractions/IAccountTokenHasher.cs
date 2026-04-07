namespace UrbanArtDropFinder.Application.Abstractions;

public interface IAccountTokenHasher
{
    string HashToken(string token);

    bool VerifyToken(string? tokenHash, string token);
}
