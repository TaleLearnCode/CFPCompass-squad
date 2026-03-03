using Azure;
using Azure.Communication.Email;

namespace CfpCompass.Api.Services;

/// <summary>
/// Sends email via Azure Communication Services using DefaultAzureCredential
/// (Managed Identity in Azure; developer credentials locally).
/// No connection strings — endpoint URI only.
/// </summary>
public sealed class AcsEmailService(
    EmailClient emailClient,
    IConfiguration config,
    ILogger<AcsEmailService> logger) : IEmailService
{
    private readonly string _senderAddress = config["Acs:SenderAddress"]
        ?? throw new InvalidOperationException(
            "Acs:SenderAddress is required. Set it to a verified ACS sender email address.");

    public async Task SendAsync(
        string toAddress,
        string toDisplayName,
        string subject,
        string htmlBody,
        CancellationToken cancellationToken = default)
    {
        var message = new EmailMessage(
            senderAddress: _senderAddress,
            recipients: new EmailRecipients([new EmailAddress(toAddress, toDisplayName)]),
            content: new EmailContent(subject) { Html = htmlBody });

        var operation = await emailClient.SendAsync(WaitUntil.Started, message, cancellationToken);

        logger.LogInformation(
            "Email queued to {Recipient}, ACS operation ID: {OperationId}",
            toAddress,
            operation.Id);
    }
}
