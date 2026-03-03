namespace CfpCompass.Api.Services;

public interface IEmailService
{
    /// <summary>
    /// Sends a transactional HTML email via Azure Communication Services.
    /// </summary>
    Task SendAsync(
        string toAddress,
        string toDisplayName,
        string subject,
        string htmlBody,
        CancellationToken cancellationToken = default);
}
