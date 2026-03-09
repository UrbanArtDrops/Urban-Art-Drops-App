using System.Text.RegularExpressions;

namespace UrbanArtDropFinder.Domain.Users;

public static class PasswordPolicy
{
    private static readonly Regex SpecialCharacterRegex =
        new("[^a-zA-Z0-9]", RegexOptions.Compiled, TimeSpan.FromMilliseconds(50));

    public const int MinimumLength = 16;

    public static PasswordValidationResult Validate(string password)
    {
        if (string.IsNullOrWhiteSpace(password))
        {
            return PasswordValidationResult.Invalid("Password must not be empty.");
        }

        if (password.Length < MinimumLength)
        {
            return PasswordValidationResult.Invalid($"Password must have at least {MinimumLength} characters.");
        }

        if (!SpecialCharacterRegex.IsMatch(password))
        {
            return PasswordValidationResult.Invalid("Password must contain at least one special character.");
        }

        return PasswordValidationResult.Valid();
    }
}

public sealed record PasswordValidationResult(bool IsValid, string? Error)
{
    public static PasswordValidationResult Valid() => new(true, null);

    public static PasswordValidationResult Invalid(string error) => new(false, error);
}
