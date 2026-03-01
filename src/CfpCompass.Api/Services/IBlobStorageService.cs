namespace CfpCompass.Api.Services;

public interface IBlobStorageService
{
    Task<Uri> UploadAsync(string containerName, string blobName, Stream content, string contentType, CancellationToken cancellationToken = default);
    Task<Stream> DownloadAsync(string containerName, string blobName, CancellationToken cancellationToken = default);
    Task DeleteAsync(string containerName, string blobName, CancellationToken cancellationToken = default);
    Task<bool> ExistsAsync(string containerName, string blobName, CancellationToken cancellationToken = default);
}
