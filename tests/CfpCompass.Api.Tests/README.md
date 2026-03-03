# CfpCompass.Api.Tests

This directory contains test files for the `CfpCompass.Api` project. The test project `CfpCompass.Api.Tests.csproj` is already scaffolded and ready to use.

## Package References (see `CfpCompass.Api.Tests.csproj`)

The `.csproj` is authoritative for package versions. Key dependencies:

- `Azure.Storage.Blobs` (floating `12.*`)
- `Microsoft.Extensions.Logging.Abstractions` (floating `10.*`)
- `Moq` (floating `4.*`)
- `xunit` / `xunit.runner.visualstudio` (floating `2.*`)
- `Aspire.Hosting.Testing` (floating `9.*`)

## Test Coverage

### Integration Tests (`BlobStorageServiceIntegrationTests.cs`)
- Upload operation returns plain URI (no SAS parameters)
- Download operation retrieves content with integrity
- Delete operation removes blob (verified by Exists)
- Exists returns false for non-existent blobs
- Upload overwrites existing blobs
- Large binary content handling

**Requirements:**
- Azurite emulator running (via Docker, Aspire AppHost, or the CI workflow's Docker step)
- Tests skip gracefully when Azurite is unreachable
- Connection string: `UseDevelopmentStorage=true`

### Unit Tests (`BlobStorageServiceUnitTests.cs`)
- Upload calls correct SDK methods and returns plain URI
- Download returns stream from SDK
- Delete calls DeleteIfExistsAsync
- Exists returns correct boolean values
- Logging verification

**No Azure/Azurite required** — uses mocked `BlobServiceClient`

## Running Tests

```bash
# Run all tests
dotnet test tests/CfpCompass.Api.Tests/

# Run integration tests only (requires Azurite)
dotnet test tests/CfpCompass.Api.Tests/ --filter "Category=Integration"

# Run unit tests only
dotnet test tests/CfpCompass.Api.Tests/ --filter "Category!=Integration"
```

## Security Constraints

All tests follow ADR-011 (Managed Identity for Azure Services):
- NO `StorageSharedKeyCredential`
- NO `BlobSasBuilder`
- NO `GenerateSasUri` calls
- NO SAS query parameters (`?sv=`, `?sig=`) in blob URIs
- Integration tests use Azurite connection string (`UseDevelopmentStorage=true`)
- Production code uses `DefaultAzureCredential` (tested indirectly via integration tests)
