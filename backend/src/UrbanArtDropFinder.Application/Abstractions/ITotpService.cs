namespace UrbanArtDropFinder.Application.Abstractions;

public interface ITotpService
{
    string GenerateSecretKey();

    string BuildProvisioningUri(string accountName, string secretKey);

    bool VerifyCode(string secretKey, string code, DateTimeOffset nowUtc);
}
