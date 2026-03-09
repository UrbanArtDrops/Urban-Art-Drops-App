using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Domain.Tests;

public sealed class LoginBackoffPolicyTests
{
    [Theory]
    [InlineData(1, 15)]
    [InlineData(2, 30)]
    [InlineData(3, 60)]
    [InlineData(4, 120)]
    [InlineData(10, 120)]
    public void GetBackoffForFailedAttempt_ReturnsExpectedValue(int attempts, int expectedSeconds)
    {
        var result = LoginBackoffPolicy.GetBackoffForFailedAttempt(attempts);

        Assert.Equal(TimeSpan.FromSeconds(expectedSeconds), result);
    }
}
