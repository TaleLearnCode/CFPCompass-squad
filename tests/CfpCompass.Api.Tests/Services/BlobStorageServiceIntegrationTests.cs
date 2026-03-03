using System.Text;
using Azure.Storage.Blobs;
using CfpCompass.Api.Services;
using Microsoft.Extensions.Logging;
using Xunit;

namespace CfpCompass.Api.Tests.Services;

/// <summary>
/// Integration tests for BlobStorageService against Azurite emulator.
/// These tests verify upload, download, delete operations and ensure NO SAS tokens are present.
/// </summary>
/// <remarks>
/// Test project scaffold required: tests/CfpCompass.Api.Tests/CfpCompass.Api.Tests.csproj
/// Required packages: xUnit, Azure.Storage.Blobs, Microsoft.Extensions.Logging
/// Azurite must be running (via Aspire AppHost or standalone container)
/// </remarks>
public sealed class BlobStorageServiceIntegrationTests : IAsyncLifetime
{
    private const string AzuriteConnectionString = "UseDevelopmentStorage=true";
    private const string TestContainerName = "test-container";
    
    private BlobServiceClient _blobServiceClient = null!;
    private BlobStorageService _sut = null!;
    private ILogger<BlobStorageService> _logger = null!;

    public async Task InitializeAsync()
    {
        _blobServiceClient = new BlobServiceClient(AzuriteConnectionString);
        _logger = new LoggerFactory().CreateLogger<BlobStorageService>();
        _sut = new BlobStorageService(_blobServiceClient, _logger);

        // Ensure clean state — delete test container if exists
        var containerClient = _blobServiceClient.GetBlobContainerClient(TestContainerName);
        await containerClient.DeleteIfExistsAsync();
    }

    public async Task DisposeAsync()
    {
        // Cleanup test container after each test
        var containerClient = _blobServiceClient.GetBlobContainerClient(TestContainerName);
        await containerClient.DeleteIfExistsAsync();
    }

    [Fact]
    public async Task UploadAsync_ReturnsPlainUri_WithoutSasParameters()
    {
        // Arrange
        var blobName = $"test-upload-{Guid.NewGuid()}.txt";
        var content = "Integration test content for upload operation";
        var contentStream = new MemoryStream(Encoding.UTF8.GetBytes(content));
        var contentType = "text/plain";

        // Act
        var resultUri = await _sut.UploadAsync(
            TestContainerName,
            blobName,
            contentStream,
            contentType);

        // Assert — Verify returned URI is plain (no SAS query params)
        Assert.NotNull(resultUri);
        Assert.DoesNotContain("?sv=", resultUri.ToString());   // No SAS version param
        Assert.DoesNotContain("?sig=", resultUri.ToString());  // No SAS signature param
        Assert.DoesNotContain("&sv=", resultUri.ToString());
        Assert.DoesNotContain("&sig=", resultUri.ToString());
        Assert.Contains(blobName, resultUri.ToString());

        // Verify blob actually exists
        var exists = await _sut.ExistsAsync(TestContainerName, blobName);
        Assert.True(exists);
    }

    [Fact]
    public async Task DownloadAsync_RetrievesUploadedContent_WithIntegrity()
    {
        // Arrange
        var blobName = $"test-download-{Guid.NewGuid()}.txt";
        var originalContent = "Integration test content for download operation";
        var contentStream = new MemoryStream(Encoding.UTF8.GetBytes(originalContent));
        var contentType = "text/plain";

        await _sut.UploadAsync(TestContainerName, blobName, contentStream, contentType);

        // Act
        var downloadedStream = await _sut.DownloadAsync(TestContainerName, blobName);

        // Assert — Verify downloaded content matches uploaded content
        using var reader = new StreamReader(downloadedStream);
        var downloadedContent = await reader.ReadToEndAsync();
        Assert.Equal(originalContent, downloadedContent);
    }

    [Fact]
    public async Task DeleteAsync_RemovesBlob_VerifiedByExists()
    {
        // Arrange
        var blobName = $"test-delete-{Guid.NewGuid()}.txt";
        var content = "Integration test content for delete operation";
        var contentStream = new MemoryStream(Encoding.UTF8.GetBytes(content));
        var contentType = "text/plain";

        await _sut.UploadAsync(TestContainerName, blobName, contentStream, contentType);

        // Verify blob exists before deletion
        var existsBeforeDelete = await _sut.ExistsAsync(TestContainerName, blobName);
        Assert.True(existsBeforeDelete);

        // Act
        await _sut.DeleteAsync(TestContainerName, blobName);

        // Assert — Verify blob no longer exists after deletion
        var existsAfterDelete = await _sut.ExistsAsync(TestContainerName, blobName);
        Assert.False(existsAfterDelete);
    }

    [Fact]
    public async Task ExistsAsync_ReturnsFalse_WhenBlobDoesNotExist()
    {
        // Arrange
        var nonExistentBlobName = $"non-existent-{Guid.NewGuid()}.txt";

        // Act
        var exists = await _sut.ExistsAsync(TestContainerName, nonExistentBlobName);

        // Assert
        Assert.False(exists);
    }

    [Fact]
    public async Task UploadAsync_OverwritesExistingBlob_WithNewContent()
    {
        // Arrange
        var blobName = $"test-overwrite-{Guid.NewGuid()}.txt";
        var originalContent = "Original content";
        var newContent = "Updated content";

        var originalStream = new MemoryStream(Encoding.UTF8.GetBytes(originalContent));
        await _sut.UploadAsync(TestContainerName, blobName, originalStream, "text/plain");

        // Act — Upload again with new content
        var newStream = new MemoryStream(Encoding.UTF8.GetBytes(newContent));
        await _sut.UploadAsync(TestContainerName, blobName, newStream, "text/plain");

        // Assert — Verify new content replaced original
        var downloadedStream = await _sut.DownloadAsync(TestContainerName, blobName);
        using var reader = new StreamReader(downloadedStream);
        var downloadedContent = await reader.ReadToEndAsync();
        Assert.Equal(newContent, downloadedContent);
    }

    [Fact]
    public async Task UploadAsync_HandlesLargeBinaryContent()
    {
        // Arrange — Create 1MB binary content
        var blobName = $"test-large-{Guid.NewGuid()}.bin";
        var largeContent = new byte[1024 * 1024]; // 1 MB
        new Random().NextBytes(largeContent);
        var contentStream = new MemoryStream(largeContent);

        // Act
        var resultUri = await _sut.UploadAsync(
            TestContainerName,
            blobName,
            contentStream,
            "application/octet-stream");

        // Assert — Verify upload succeeded and content integrity
        var downloadedStream = await _sut.DownloadAsync(TestContainerName, blobName);
        var downloadedContent = new byte[largeContent.Length];
        await downloadedStream.ReadAsync(downloadedContent.AsMemory(0, downloadedContent.Length));
        
        Assert.Equal(largeContent, downloadedContent);
    }
}
