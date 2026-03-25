using UrbanArtDropFinder.Application.Abstractions;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class FakeSmtpConnectionTester : ISmtpConnectionTester
{
    public Func<string, int, string?, string?, CancellationToken, Task<SmtpConnectionTestResult>> Handler { get; set; } =
        static (_, _, _, _, _) => Task.FromResult(new SmtpConnectionTestResult(true, "SMTP connection successful."));

    public (string Host, int Port, string? UserName, string? Password)? LastRequest { get; private set; }

    public Task<SmtpConnectionTestResult> TestAsync(
        string host,
        int port,
        string? userName,
        string? password,
        CancellationToken cancellationToken)
    {
        LastRequest = (host, port, userName, password);
        return Handler(host, port, userName, password, cancellationToken);
    }
}
