# CfpCompass.Api.Tests

⚠️ **Test Project Scaffold Required**

This directory contains test files for the `CfpCompass.Api` project. The test project `CfpCompass.Api.Tests.csproj` does not exist yet.

## Required Setup

Create the test project with:

```bash
dotnet new xunit -n CfpCompass.Api.Tests -o tests/CfpCompass.Api.Tests
cd tests/CfpCompass.Api.Tests

# Add required package references
dotnet add package Azure.Storage.Blobs --version 12.23.0
dotnet add package Moq --version 4.20.72
dotnet add package Microsoft.Extensions.Logging --version 10.0.0

# Add project reference to the API project
dotnet add reference ..\..\src\CfpCompass.Api\CfpCompass.Api.csproj
```

## Test Coverage

### Integration Tests (`BlobStorageServiceIntegrationTests.cs`)
- Upload operation returns plain URI (no SAS parameters)
- Download operation retrieves content with integrity
- Delete operation removes blob (verified by Exists)
- Exists returns false for non-existent blobs
- Upload overwrites existing blobs
- Large binary content handling

**Requirements:**
- Azurite emulator running (via Aspire AppHost or standalone Docker)
- Connection string: `UseDevelopmentStorage=true`

### Unit Tests (`BlobStorageServiceUnitTests.cs`)
- Upload calls correct SDK methods and returns plain URI
- Download returns stream from SDK
- Delete calls DeleteIfExistsAsync
- Exists returns correct boolean values
- Logging verification

**No Azure/Azurite required** — uses mocked `BlobServiceClient`

## Running Tests

Once the project is scaffolded:

```bash
# Run all tests
dotnet test tests/CfpCompass.Api.Tests/

# Run integration tests only
dotnet test tests/CfpCompass.Api.Tests/ --filter "FullyQualifiedName~IntegrationTests"

# Run unit tests only
dotnet test tests/CfpCompass.Api.Tests/ --filter "FullyQualifiedName~UnitTests"
```

## Security Constraints

All tests follow ADR-011 (Managed Identity for Azure Services):
- NO `StorageSharedKeyCredential`
- NO `BlobSasBuilder`
- NO `GenerateSasUri` calls
- NO SAS query parameters (`?sv=`, `?sig=`) in blob URIs
- Integration tests use Azurite connection string (`UseDevelopmentStorage=true`)
- Production code uses `DefaultAzureCredential` (tested indirectly via integration tests)
