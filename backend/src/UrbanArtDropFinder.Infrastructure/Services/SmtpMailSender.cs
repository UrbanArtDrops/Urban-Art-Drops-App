using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Domain.Configuration;

namespace UrbanArtDropFinder.Infrastructure.Services;

/// <summary>Sends mail through MailKit using explicit TLS or StartTLS configuration.</summary>
public sealed class SmtpMailSender : ISmtpMailSender
{
    public async Task<SmtpMailSendResult> SendAsync(
        SmtpMailMessage message,
        SmtpDeliveryOptions deliveryOptions,
        CancellationToken cancellationToken)
    {
        try
        {
            if (message.Recipients.Count == 0)
            {
                return new SmtpMailSendResult(false, "No SMTP recipients configured.");
            }

            using var smtpClient = new SmtpClient
            {
                Timeout = 10000
            };

            var mimeMessage = new MimeMessage();
            mimeMessage.From.Add(MailboxAddress.Parse(message.SenderEmail));
            foreach (var recipient in message.Recipients)
            {
                mimeMessage.To.Add(MailboxAddress.Parse(recipient));
            }

            mimeMessage.Subject = message.Subject;
            mimeMessage.Body = new TextPart("plain")
            {
                Text = message.TextBody
            };

            await smtpClient.ConnectAsync(
                deliveryOptions.Host,
                deliveryOptions.Port,
                ToSecureSocketOptions(deliveryOptions.SecurityMode),
                cancellationToken);

            if (!string.IsNullOrWhiteSpace(deliveryOptions.UserName)
                || !string.IsNullOrWhiteSpace(deliveryOptions.Password))
            {
                if (string.IsNullOrWhiteSpace(deliveryOptions.UserName)
                    || string.IsNullOrWhiteSpace(deliveryOptions.Password))
                {
                    return new SmtpMailSendResult(false, "SMTP username and password secret must both be configured.");
                }

                await smtpClient.AuthenticateAsync(
                    deliveryOptions.UserName,
                    deliveryOptions.Password,
                    cancellationToken);
            }

            await smtpClient.SendAsync(mimeMessage, cancellationToken);
            await smtpClient.DisconnectAsync(true, cancellationToken);
            return new SmtpMailSendResult(true, "SMTP message sent.");
        }
        catch (Exception exception)
        {
            return new SmtpMailSendResult(false, exception.Message);
        }
    }

    private static SecureSocketOptions ToSecureSocketOptions(SmtpSecurityMode securityMode) =>
        securityMode switch
        {
            SmtpSecurityMode.StartTls => SecureSocketOptions.StartTls,
            SmtpSecurityMode.Tls => SecureSocketOptions.SslOnConnect,
            _ => throw new ArgumentOutOfRangeException(nameof(securityMode), securityMode, "Unsupported SMTP security mode.")
        };
}
