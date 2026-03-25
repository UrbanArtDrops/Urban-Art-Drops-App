using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Domain.Configuration;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class FakeSmtpConnectionTester : ISmtpConnectionTester
{
    public Func<string, int, SmtpSecurityMode, string?, string?, CancellationToken, Task<SmtpConnectionTestResult>> Handler { get; set; } =
        static (_, _, _, _, _, _) => Task.FromResult(new SmtpConnectionTestResult(true, "SMTP connection successful."));

    public (string Host, int Port, SmtpSecurityMode SecurityMode, string? UserName, string? Password)? LastRequest { get; private set; }

    public Task<SmtpConnectionTestResult> TestAsync(
        string host,
        int port,
        SmtpSecurityMode securityMode,
        string? userName,
        string? password,
        CancellationToken cancellationToken)
    {
        LastRequest = (host, port, securityMode, userName, password);
        return Handler(host, port, securityMode, userName, password, cancellationToken);
    }
}
