using System.Text;
using Azure;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using CfpCompass.Api.Services;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;

namespace CfpCompass.Api.Tests.Services;

/// <summary>
/// Unit tests for BlobStorageService using mocked Azure SDK clients.
/// Tests verify correct SDK method calls, error handling, and logging without live Azure/Azurite.
/// </summary>
/// <remarks>
/// Test project scaffold required: tests/CfpCompass.Api.Tests/CfpCompass.Api.Tests.csproj
/// Required packages: xUnit, Moq, Azure.Storage.Blobs, Microsoft.Extensions.Logging
/// </remarks>
public sealed class BlobStorageServiceUnitTests
{
    private readonly Mock<BlobServiceClient> _mockBlobServiceClient = new();
    private readonly Mock<ILogger<BlobStorageService>> _mockLogger = new();

    [Fact]
    public async Task UploadAsync_CallsUploadAsyncOnBlobClient_ReturnsPlainUri()
    {
        // Arrange
        var containerName = "test-container";
        var blobName = "test-blob.txt";
        var content = new MemoryStream(Encoding.UTF8.GetBytes("test content"));
        var contentType = "text/plain";

        var mockContainerClient = new Mock<BlobContainerClient>();
        var mockBlobClient = new Mock<BlobClient>();

        var expectedUri = new Uri($"https://testaccount.blob.core.windows.net/{containerName}/{blobName}");
        mockBlobClient.Setup(x => x.Uri).Returns(expectedUri);

        mockBlobClient
            .Setup(x => x.UploadAsync(
                It.IsAny<Stream>(),
                It.IsAny<BlobUploadOptions>(),
                It.IsAny<CancellationToken>()))
            .ReturnsAsync(Mock.Of<Response<BlobContentInfo>>());

        mockContainerClient
            .Setup(x => x.CreateIfNotExistsAsync(It.IsAny<PublicAccessType>(), null, null, It.IsAny<CancellationToken>()))
            .ReturnsAsync(Mock.Of<Response<BlobContainerInfo>>());

        mockContainerClient.Setup(x => x.GetBlobClient(blobName)).Returns(mockBlobClient.Object);
        _mockBlobServiceClient.Setup(x => x.GetBlobContainerClient(containerName)).Returns(mockContainerClient.Object);

        var sut = new BlobStorageService(_mockBlobServiceClient.Object, _mockLogger.Object);

        // Act
        var result = await sut.UploadAsync(containerName, blobName, content, contentType);

        // Assert
        Assert.Equal(expectedUri, result);
        Assert.DoesNotContain("?sv=", result.ToString());
        Assert.DoesNotContain("?sig=", result.ToString());
        
        mockBlobClient.Verify(
            x => x.UploadAsync(
                It.IsAny<Stream>(),
                It.Is<BlobUploadOptions>(o => o.HttpHeaders.ContentType == contentType),
                It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task DownloadAsync_CallsDownloadStreamingAsync_ReturnsStream()
    {
        // Arrange
        var containerName = "test-container";
        var blobName = "test-blob.txt";
        var expectedContent = "downloaded content";
        var contentStream = new MemoryStream(Encoding.UTF8.GetBytes(expectedContent));

        var mockContainerClient = new Mock<BlobContainerClient>();
        var mockBlobClient = new Mock<BlobClient>();

        var mockDownloadResult = BlobsModelFactory.BlobDownloadStreamingResult(contentStream);
        var mockResponse = Response.FromValue(mockDownloadResult, Mock.Of<Response>());

        mockBlobClient
            .Setup(x => x.DownloadStreamingAsync(null, It.IsAny<CancellationToken>()))
            .ReturnsAsync(mockResponse);

        mockContainerClient.Setup(x => x.GetBlobClient(blobName)).Returns(mockBlobClient.Object);
        _mockBlobServiceClient.Setup(x => x.GetBlobContainerClient(containerName)).Returns(mockContainerClient.Object);

        var sut = new BlobStorageService(_mockBlobServiceClient.Object, _mockLogger.Object);

        // Act
        var result = await sut.DownloadAsync(containerName, blobName);

        // Assert
        using var reader = new StreamReader(result);
        var downloadedText = await reader.ReadToEndAsync();
        Assert.Equal(expectedContent, downloadedText);

        mockBlobClient.Verify(
            x => x.DownloadStreamingAsync(null, It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task DeleteAsync_CallsDeleteIfExistsAsync()
    {
        // Arrange
        var containerName = "test-container";
        var blobName = "test-blob.txt";

        var mockContainerClient = new Mock<BlobContainerClient>();
        var mockBlobClient = new Mock<BlobClient>();

        mockBlobClient
            .Setup(x => x.DeleteIfExistsAsync(It.IsAny<DeleteSnapshotsOption>(), null, It.IsAny<CancellationToken>()))
            .ReturnsAsync(Mock.Of<Response<bool>>());

        mockContainerClient.Setup(x => x.GetBlobClient(blobName)).Returns(mockBlobClient.Object);
        _mockBlobServiceClient.Setup(x => x.GetBlobContainerClient(containerName)).Returns(mockContainerClient.Object);

        var sut = new BlobStorageService(_mockBlobServiceClient.Object, _mockLogger.Object);

        // Act
        await sut.DeleteAsync(containerName, blobName);

        // Assert
        mockBlobClient.Verify(
            x => x.DeleteIfExistsAsync(It.IsAny<DeleteSnapshotsOption>(), null, It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task ExistsAsync_CallsExistsAsync_ReturnsTrue()
    {
        // Arrange
        var containerName = "test-container";
        var blobName = "test-blob.txt";

        var mockContainerClient = new Mock<BlobContainerClient>();
        var mockBlobClient = new Mock<BlobClient>();

        var mockResponse = Response.FromValue(true, Mock.Of<Response>());
        mockBlobClient
            .Setup(x => x.ExistsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(mockResponse);

        mockContainerClient.Setup(x => x.GetBlobClient(blobName)).Returns(mockBlobClient.Object);
        _mockBlobServiceClient.Setup(x => x.GetBlobContainerClient(containerName)).Returns(mockContainerClient.Object);

        var sut = new BlobStorageService(_mockBlobServiceClient.Object, _mockLogger.Object);

        // Act
        var result = await sut.ExistsAsync(containerName, blobName);

        // Assert
        Assert.True(result);
        mockBlobClient.Verify(
            x => x.ExistsAsync(It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task ExistsAsync_CallsExistsAsync_ReturnsFalse()
    {
        // Arrange
        var containerName = "test-container";
        var blobName = "non-existent.txt";

        var mockContainerClient = new Mock<BlobContainerClient>();
        var mockBlobClient = new Mock<BlobClient>();

        var mockResponse = Response.FromValue(false, Mock.Of<Response>());
        mockBlobClient
            .Setup(x => x.ExistsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(mockResponse);

        mockContainerClient.Setup(x => x.GetBlobClient(blobName)).Returns(mockBlobClient.Object);
        _mockBlobServiceClient.Setup(x => x.GetBlobContainerClient(containerName)).Returns(mockContainerClient.Object);

        var sut = new BlobStorageService(_mockBlobServiceClient.Object, _mockLogger.Object);

        // Act
        var result = await sut.ExistsAsync(containerName, blobName);

        // Assert
        Assert.False(result);
    }

    [Fact]
    public async Task UploadAsync_LogsInformationMessage()
    {
        // Arrange
        var containerName = "test-container";
        var blobName = "test-blob.txt";
        var content = new MemoryStream(Encoding.UTF8.GetBytes("test"));

        var mockContainerClient = new Mock<BlobContainerClient>();
        var mockBlobClient = new Mock<BlobClient>();

        mockBlobClient.Setup(x => x.Uri).Returns(new Uri("https://test.blob.core.windows.net/test/blob.txt"));
        mockBlobClient
            .Setup(x => x.UploadAsync(It.IsAny<Stream>(), It.IsAny<BlobUploadOptions>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Mock.Of<Response<BlobContentInfo>>());

        mockContainerClient
            .Setup(x => x.CreateIfNotExistsAsync(It.IsAny<PublicAccessType>(), null, null, It.IsAny<CancellationToken>()))
            .ReturnsAsync(Mock.Of<Response<BlobContainerInfo>>());

        mockContainerClient.Setup(x => x.GetBlobClient(blobName)).Returns(mockBlobClient.Object);
        _mockBlobServiceClient.Setup(x => x.GetBlobContainerClient(containerName)).Returns(mockContainerClient.Object);

        var sut = new BlobStorageService(_mockBlobServiceClient.Object, _mockLogger.Object);

        // Act
        await sut.UploadAsync(containerName, blobName, content, "text/plain");

        // Assert — Verify logging occurred
        _mockLogger.Verify(
            x => x.Log(
                LogLevel.Information,
                It.IsAny<EventId>(),
                It.Is<It.IsAnyType>((v, t) => v.ToString()!.Contains("Uploaded blob")),
                null,
                It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
            Times.Once);
    }
}
