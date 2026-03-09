namespace UrbanArtDropFinder.Domain.Users;

public static class LoginBackoffPolicy
{
    private static readonly int[] BackoffSeconds = [15, 30, 60, 120];
    private const int MaxSeconds = 600;

    public static TimeSpan GetBackoffForFailedAttempt(int failedAttempts)
    {
        if (failedAttempts <= 0)
        {
            return TimeSpan.Zero;
        }

        var index = Math.Min(failedAttempts - 1, BackoffSeconds.Length - 1);
        var seconds = BackoffSeconds[index];
        return TimeSpan.FromSeconds(Math.Min(seconds, MaxSeconds));
    }
}
