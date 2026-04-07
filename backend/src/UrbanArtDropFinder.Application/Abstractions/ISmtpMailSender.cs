using UrbanArtDropFinder.Domain.Configuration;

namespace UrbanArtDropFinder.Application.Abstractions;

/// <summary>Sends application emails through the configured SMTP transport.</summary>
public interface ISmtpMailSender
{
    /// <summary>Sends a mail message with the supplied delivery options.</summary>
    Task<SmtpMailSendResult> SendAsync(
        SmtpMailMessage message,
        SmtpDeliveryOptions deliveryOptions,
        CancellationToken cancellationToken);
}

/// <summary>Represents a plaintext SMTP mail payload.</summary>
public sealed record SmtpMailMessage(
    string SenderEmail,
    IReadOnlyCollection<string> Recipients,
    string Subject,
    string TextBody);

/// <summary>Contains SMTP delivery settings resolved from app configuration and secret storage.</summary>
public sealed record SmtpDeliveryOptions(
    string Host,
    int Port,
    SmtpSecurityMode SecurityMode,
    string? UserName,
    string? Password);

/// <summary>Represents the result of an SMTP send attempt.</summary>
public sealed record SmtpMailSendResult(bool Success, string Message);
