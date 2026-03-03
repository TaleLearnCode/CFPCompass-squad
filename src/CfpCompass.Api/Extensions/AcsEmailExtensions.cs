using Azure.Identity;
using Azure.Communication.Email;
using CfpCompass.Api.Services;

namespace CfpCompass.Api.Extensions;

public static class AcsEmailExtensions
{
    /// <summary>
    /// Registers Azure Communication Services email using DefaultAzureCredential.
    /// Reads the ACS endpoint from ConnectionStrings:acs (populated by Aspire's WithReference
    /// in dev, or set via environment variable / Key Vault in deployed environments).
    /// No connection string is used — authentication is credential-only.
    /// </summary>
    public static IHostApplicationBuilder AddAcsEmail(this IHostApplicationBuilder builder)
    {
        var endpoint = new Uri(
            builder.Configuration.GetConnectionString("acs")
                ?? throw new InvalidOperationException(
                    "ACS endpoint connection string 'acs' is required. " +
                    "In development, ensure AppHost wires the ACS resource with WithReference(acs). " +
                    "In production, set ConnectionStrings__acs to the ACS endpoint URI."));

        // EmailClient is registered as a singleton. DefaultAzureCredential resolves to:
        //   - Managed Identity when running in Azure Container Apps
        //   - Developer credentials (az login / VS credential) locally
        builder.Services.AddSingleton(new EmailClient(endpoint, new DefaultAzureCredential()));
        builder.Services.AddSingleton<IEmailService, AcsEmailService>();

        return builder;
    }
}
