using CfpCompass.Api.Services;

namespace CfpCompass.Api.Extensions;

public static class BlobStorageExtensions
{
    /// <summary>
    /// Registers Azure Blob Storage using .NET Aspire's AddAzureBlobServiceClient.
    /// BlobServiceClient is automatically configured with DefaultAzureCredential —
    /// no connection strings or SAS tokens in application code.
    /// </summary>
    public static IHostApplicationBuilder AddBlobStorage(this IHostApplicationBuilder builder)
    {
        builder.AddAzureBlobServiceClient("blobs"); // "blobs" = Aspire resource name defined in AppHost
        builder.Services.AddSingleton<IBlobStorageService, BlobStorageService>();
        return builder;
    }
}
