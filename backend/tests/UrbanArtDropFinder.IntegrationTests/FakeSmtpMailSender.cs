using UrbanArtDropFinder.Application.Abstractions;

namespace UrbanArtDropFinder.IntegrationTests;

public sealed class FakeSmtpMailSender : ISmtpMailSender
{
    public Func<SmtpMailMessage, SmtpDeliveryOptions, CancellationToken, Task<SmtpMailSendResult>> Handler { get; set; } =
        static (_, _, _) => Task.FromResult(new SmtpMailSendResult(true, "SMTP message sent."));

    public (SmtpMailMessage Message, SmtpDeliveryOptions DeliveryOptions)? LastRequest { get; private set; }

    public Task<SmtpMailSendResult> SendAsync(
        SmtpMailMessage message,
        SmtpDeliveryOptions deliveryOptions,
        CancellationToken cancellationToken)
    {
        LastRequest = (message, deliveryOptions);
        return Handler(message, deliveryOptions, cancellationToken);
    }
}
