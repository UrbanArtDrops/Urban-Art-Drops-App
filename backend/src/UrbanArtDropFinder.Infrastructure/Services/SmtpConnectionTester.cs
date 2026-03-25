using MailKit.Net.Smtp;
using MailKit.Security;
using UrbanArtDropFinder.Application.Abstractions;

namespace UrbanArtDropFinder.Infrastructure.Services;

public sealed class SmtpConnectionTester : ISmtpConnectionTester
{
    public async Task<SmtpConnectionTestResult> TestAsync(
        string host,
        int port,
        string? userName,
        string? password,
        CancellationToken cancellationToken)
    {
        try
        {
            using var client = new SmtpClient
            {
                Timeout = 10000
            };

            await client.ConnectAsync(host, port, SecureSocketOptions.Auto, cancellationToken);

            if (!string.IsNullOrWhiteSpace(userName) || !string.IsNullOrWhiteSpace(password))
            {
                if (string.IsNullOrWhiteSpace(userName) || string.IsNullOrWhiteSpace(password))
                {
                    return new SmtpConnectionTestResult(
                        false,
                        "SMTP username and password must both be provided for authenticated connection tests.");
                }

                await client.AuthenticateAsync(userName, password, cancellationToken);
            }

            await client.DisconnectAsync(true, cancellationToken);
            return new SmtpConnectionTestResult(true, "SMTP connection successful.");
        }
        catch (Exception exception)
        {
            return new SmtpConnectionTestResult(false, exception.Message);
        }
    }
}
