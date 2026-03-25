namespace UrbanArtDropFinder.Application.Abstractions;

public interface ISmtpConnectionTester
{
    Task<SmtpConnectionTestResult> TestAsync(
        string host,
        int port,
        string? userName,
        string? password,
        CancellationToken cancellationToken);
}

public sealed record SmtpConnectionTestResult(bool Success, string Message);
