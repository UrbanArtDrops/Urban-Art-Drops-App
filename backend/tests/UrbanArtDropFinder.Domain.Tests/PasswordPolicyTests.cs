using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Domain.Tests;

public sealed class PasswordPolicyTests
{
    [Fact]
    public void Validate_WhenPasswordHasMinimumLengthAndSpecialCharacter_ReturnsValid()
    {
        var result = PasswordPolicy.Validate("Aaaaaaaaaaaaaaa!");

        Assert.True(result.IsValid);
    }

    [Fact]
    public void Validate_WhenPasswordIsTooShort_ReturnsInvalid()
    {
        var result = PasswordPolicy.Validate("short!");

        Assert.False(result.IsValid);
    }

    [Fact]
    public void Validate_WhenPasswordHasNoSpecialCharacter_ReturnsInvalid()
    {
        var result = PasswordPolicy.Validate("Aaaaaaaaaaaaaaaa");

        Assert.False(result.IsValid);
    }
}
