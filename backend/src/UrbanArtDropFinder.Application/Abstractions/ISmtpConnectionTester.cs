using UrbanArtDropFinder.Domain.Configuration;

namespace UrbanArtDropFinder.Application.Abstractions;

public interface ISmtpConnectionTester
{
    Task<SmtpConnectionTestResult> TestAsync(
        string host,
        int port,
        SmtpSecurityMode securityMode,
        string? userName,
        string? password,
        CancellationToken cancellationToken);
}

public sealed record SmtpConnectionTestResult(bool Success, string Message);
