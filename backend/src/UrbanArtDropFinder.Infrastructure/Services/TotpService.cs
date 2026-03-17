using System.Globalization;
using System.Security.Cryptography;
using System.Text;
using UrbanArtDropFinder.Application.Abstractions;

namespace UrbanArtDropFinder.Infrastructure.Services;

public sealed class TotpService : ITotpService
{
    private const string ApplicationName = "Urban Art Drops";
    private const string Base32Alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
    private const int SecretLengthBytes = 20;
    private const int TimeStepSeconds = 30;
    private const int Digits = 6;
    private const int AllowedDriftSteps = 1;

    public string GenerateSecretKey()
    {
        var bytes = RandomNumberGenerator.GetBytes(SecretLengthBytes);
        return ToBase32(bytes);
    }

    public string BuildProvisioningUri(string accountName, string secretKey)
    {
        var normalizedAccountName = string.IsNullOrWhiteSpace(accountName)
            ? "account"
            : accountName.Trim();
        return
            $"otpauth://totp/{Uri.EscapeDataString($"{ApplicationName}:{normalizedAccountName}")}?secret={Uri.EscapeDataString(secretKey)}&issuer={Uri.EscapeDataString(ApplicationName)}&digits={Digits}&period={TimeStepSeconds}";
    }

    public bool VerifyCode(string secretKey, string code, DateTimeOffset nowUtc)
    {
        if (string.IsNullOrWhiteSpace(secretKey) || string.IsNullOrWhiteSpace(code))
        {
            return false;
        }

        var normalizedCode = new string(code.Where(char.IsDigit).ToArray());
        if (normalizedCode.Length != Digits)
        {
            return false;
        }

        var secret = FromBase32(secretKey);
        var unixTime = nowUtc.ToUnixTimeSeconds();
        var counter = unixTime / TimeStepSeconds;

        for (var drift = -AllowedDriftSteps; drift <= AllowedDriftSteps; drift += 1)
        {
            var expectedCode = ComputeCode(secret, counter + drift);
            if (CryptographicOperations.FixedTimeEquals(
                    Encoding.ASCII.GetBytes(expectedCode),
                    Encoding.ASCII.GetBytes(normalizedCode)))
            {
                return true;
            }
        }

        return false;
    }

    private static string ComputeCode(byte[] secret, long counter)
    {
        Span<byte> counterBytes = stackalloc byte[8];
        for (var index = 7; index >= 0; index -= 1)
        {
            counterBytes[index] = (byte)(counter & 0xFF);
            counter >>= 8;
        }

        using var hmac = new HMACSHA1(secret);
        var hash = hmac.ComputeHash(counterBytes.ToArray());
        var offset = hash[^1] & 0x0F;
        var binaryCode =
            ((hash[offset] & 0x7F) << 24) |
            ((hash[offset + 1] & 0xFF) << 16) |
            ((hash[offset + 2] & 0xFF) << 8) |
            (hash[offset + 3] & 0xFF);
        var truncatedCode = binaryCode % (int)Math.Pow(10, Digits);
        return truncatedCode.ToString(CultureInfo.InvariantCulture).PadLeft(Digits, '0');
    }

    private static string ToBase32(byte[] bytes)
    {
        if (bytes.Length == 0)
        {
            return string.Empty;
        }

        var output = new StringBuilder((bytes.Length + 4) / 5 * 8);
        var buffer = (int)bytes[0];
        var next = 1;
        var bitsLeft = 8;
        while (bitsLeft > 0 || next < bytes.Length)
        {
            if (bitsLeft < 5)
            {
                if (next < bytes.Length)
                {
                    buffer <<= 8;
                    buffer |= bytes[next++] & 0xFF;
                    bitsLeft += 8;
                }
                else
                {
                    var pad = 5 - bitsLeft;
                    buffer <<= pad;
                    bitsLeft += pad;
                }
            }

            var index = 0x1F & (buffer >> (bitsLeft - 5));
            bitsLeft -= 5;
            output.Append(Base32Alphabet[index]);
        }

        return output.ToString();
    }

    private static byte[] FromBase32(string value)
    {
        var normalized = value.Trim().TrimEnd('=').ToUpperInvariant();
        if (normalized.Length == 0)
        {
            return [];
        }

        var output = new List<byte>(normalized.Length * 5 / 8);
        var buffer = 0;
        var bitsLeft = 0;

        foreach (var character in normalized)
        {
            var index = Base32Alphabet.IndexOf(character);
            if (index < 0)
            {
                throw new FormatException("Invalid Base32 secret key.");
            }

            buffer <<= 5;
            buffer |= index & 0x1F;
            bitsLeft += 5;

            if (bitsLeft >= 8)
            {
                output.Add((byte)(buffer >> (bitsLeft - 8)));
                bitsLeft -= 8;
            }
        }

        return [.. output];
    }
}
