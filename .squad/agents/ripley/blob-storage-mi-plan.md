# Blob Storage — Managed Identity Implementation Plan

**Issue:** #1 — [MI Gap] Azure Blob Storage: Replace SAS tokens with Managed Identity  
**Branch:** `squad/1-blob-storage-managed-identity`  
**Author:** Ripley (Backend Dev)  
**Date:** 2026-03-01  
**Status:** Pre-implementation — no source files exist yet. This plan guides initial build.

---

## Context

CFP Compass uses an Azure Storage Account (GPv2, LRS) for image storage (CFP event images, speaker avatars). The architecture spec (`docs/architecture/architecture-specifications.md`) lists `Azure.Storage.Blobs` as a hard dependency of `CFPCompass.Infrastructure` and `IBlobStorageService` as a soft dependency interface defined in `CFPCompass.Application`. Since the project is pre-implementation, there is no SAS token code to remove — the plan ensures Managed Identity is the **only** access pattern ever introduced.

---

## Blob Containers

Two containers are provisioned by Parker's Terraform `modules/storage/` module:

| Container Name  | Purpose                              | Access Tier |
|-----------------|--------------------------------------|-------------|
| `cfp-images`    | CFP event banner/logo images         | Cool        |
| `user-avatars`  | Speaker profile photos               | Cool        |

All containers use **private access** (no public blob access). Images are served via Azure Front Door CDN using the managed identity of the Front Door origin, not via SAS URIs.

---

## Which Projects Need Blob Storage Access?

| Project                    | Access Needed | Reason                                                  |
|----------------------------|---------------|---------------------------------------------------------|
| `CFPCompass.Infrastructure` | Read + Write  | Implements `IBlobStorageService` — all blob I/O goes here |
| `CFPCompass.AppHost`        | Config only   | Wires Azurite emulator for local dev                    |
| `CFPCompass.Api`            | Indirect       | Calls `IBlobStorageService` via DI (no direct SDK ref)  |
| `CFPCompass.Workers`        | Indirect       | May call `IBlobStorageService` if cleanup jobs needed   |
| `CFPCompass.Functions`      | None          | Service Bus processors — no blob operations             |
| `CFPCompass.Web`            | None          | Blazor frontend — no direct Infrastructure reference    |

`CFPCompass.Infrastructure` is the **only** project with a direct `BlobServiceClient` dependency. All other service projects access blobs only through the `IBlobStorageService` interface.

---

## NuGet Packages

### `CFPCompass.Infrastructure`
```xml
<PackageReference Include="Azure.Storage.Blobs" Version="12.*" />
<PackageReference Include="Aspire.Azure.Storage.Blobs" Version="9.*" />
```
> `Aspire.Azure.Storage.Blobs` wraps `Azure.Storage.Blobs` and adds Aspire health checks, telemetry, and `DefaultAzureCredential`-based registration via `builder.AddAzureStorageBlobs()`.

### `CFPCompass.AppHost`
```xml
<PackageReference Include="Aspire.Hosting.Azure.Storage" Version="9.*" />
```
> Required to wire the Azurite emulator for local development and to declare the `blob-storage` resource.

---

## Aspire AppHost Wiring

Update `CFPCompass.AppHost/Program.cs` to add Azure Storage with Azurite emulation:

```csharp
var builder = DistributedApplication.CreateBuilder(args);

var sql        = builder.AddAzureSqlServer("sql").RunAsContainer();
var redis      = builder.AddAzureRedis("redis").RunAsContainer();
var serviceBus = builder.AddAzureServiceBus("servicebus").RunAsEmulator();

// Add Azure Storage — uses Azurite emulator locally
var storage = builder.AddAzureStorage("storage").RunAsEmulator();
var blobs   = storage.AddBlobs("blob-storage");

builder.AddProject<CFPCompass_Api>("api")
    .WithReference(sql)
    .WithReference(redis)
    .WithReference(serviceBus)
    .WithReference(blobs);          // <-- new

builder.AddProject<CFPCompass_Web>("web")
    .WithReference("api");

builder.AddProject<CFPCompass_Workers>("workers")
    .WithReference(sql)
    .WithReference(redis)
    .WithReference(blobs);          // <-- new (if workers need blob access)

builder.AddProject<CFPCompass_Functions>("functions")
    .WithReference(serviceBus)
    .WithReference(sql)
    .WithReference(redis);

builder.Build().Run();
```

> `AddAzureStorage("storage").RunAsEmulator()` pulls the `mcr.microsoft.com/azure-storage/azurite` container automatically via Aspire. No manual Azurite setup needed.

---

## DI Registration in Infrastructure

In `CFPCompass.Infrastructure/DependencyInjection.cs` (or wherever Infrastructure registers services):

```csharp
// Called from CFPCompass.Api Program.cs, CFPCompass.Workers Program.cs, etc.
public static IHostApplicationBuilder AddInfrastructure(this IHostApplicationBuilder builder)
{
    // Azure Storage Blobs via Aspire integration
    // - Local dev: connects to Azurite emulator (Aspire injects connection)
    // - Production: uses DefaultAzureCredential with Storage Account URI
    builder.AddAzureStorageBlobs("blob-storage");

    // Register IBlobStorageService implementation
    builder.Services.AddScoped<IBlobStorageService, BlobStorageService>();

    // ... other registrations (EF Core, Redis, Service Bus, etc.)
    return builder;
}
```

> `builder.AddAzureStorageBlobs("blob-storage")` resolves from the Aspire service model in development (Azurite connection string) and from environment configuration in production. In production, the Aspire Azure Storage integration uses `DefaultAzureCredential` when a storage account URI (not a connection string) is provided.

### Production `appsettings.json` pattern

Do **not** use connection strings with storage account keys. Use the account URI:

```json
{
  "Azure": {
    "Storage": {
      "blob-storage": {
        "ServiceUri": "https://stcfpcompass{env}.blob.core.windows.net"
      }
    }
  }
}
```

> At runtime, `DefaultAzureCredential` picks up the Container App's system-assigned managed identity automatically. No additional configuration required.

> **Never** add `AccountKey`, `SharedAccessSignature`, or `DefaultEndpointsProtocol=...;AccountKey=...` connection strings to any `appsettings*.json` file.

---

## IBlobStorageService Interface

Defined in `CFPCompass.Application/Interfaces/IBlobStorageService.cs`:

```csharp
namespace CFPCompass.Application.Interfaces;

/// <summary>
/// Abstraction for Azure Blob Storage operations.
/// All blobs are accessed via Managed Identity — no SAS tokens.
/// </summary>
public interface IBlobStorageService
{
    /// <summary>Upload a blob, returning the blob URI (without SAS).</summary>
    Task<Uri> UploadAsync(
        string containerName,
        string blobName,
        Stream content,
        string contentType,
        CancellationToken cancellationToken = default);

    /// <summary>Download a blob as a stream.</summary>
    Task<Stream> DownloadAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default);

    /// <summary>Delete a blob. Returns false if blob does not exist.</summary>
    Task<bool> DeleteAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default);

    /// <summary>Check whether a blob exists.</summary>
    Task<bool> ExistsAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default);
}
```

> **No `GetSasUri`, `GenerateSasUri`, or SAS-related methods.** Callers receive plain blob URIs; serving images to end-users goes through Azure Front Door, which accesses the storage account directly using its managed identity.

---

## BlobStorageService Implementation

In `CFPCompass.Infrastructure/Services/BlobStorageService.cs`:

```csharp
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using CFPCompass.Application.Interfaces;

namespace CFPCompass.Infrastructure.Services;

internal sealed class BlobStorageService(BlobServiceClient blobServiceClient, ILogger<BlobStorageService> logger)
    : IBlobStorageService
{
    public async Task<Uri> UploadAsync(
        string containerName,
        string blobName,
        Stream content,
        string contentType,
        CancellationToken cancellationToken = default)
    {
        var containerClient = blobServiceClient.GetBlobContainerClient(containerName);
        await containerClient.CreateIfNotExistsAsync(cancellationToken: cancellationToken);

        var blobClient = containerClient.GetBlobClient(blobName);

        await blobClient.UploadAsync(content, new BlobHttpHeaders { ContentType = contentType },
            cancellationToken: cancellationToken);

        logger.LogInformation("Uploaded blob {BlobName} to container {Container}", blobName, containerName);

        return blobClient.Uri;  // Plain URI — no SAS
    }

    public async Task<Stream> DownloadAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default)
    {
        var blobClient = blobServiceClient
            .GetBlobContainerClient(containerName)
            .GetBlobClient(blobName);

        var response = await blobClient.DownloadStreamingAsync(cancellationToken: cancellationToken);
        return response.Value.Content;
    }

    public async Task<bool> DeleteAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default)
    {
        var blobClient = blobServiceClient
            .GetBlobContainerClient(containerName)
            .GetBlobClient(blobName);

        var response = await blobClient.DeleteIfExistsAsync(cancellationToken: cancellationToken);
        return response.Value;
    }

    public async Task<bool> ExistsAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default)
    {
        var blobClient = blobServiceClient
            .GetBlobContainerClient(containerName)
            .GetBlobClient(blobName);

        return await blobClient.ExistsAsync(cancellationToken);
    }
}
```

> `BlobServiceClient` is injected by Aspire's `builder.AddAzureStorageBlobs()` registration. It uses `DefaultAzureCredential` in production automatically.

---

## Blob Container Name Constants

In `CFPCompass.Application/Constants/BlobContainers.cs`:

```csharp
namespace CFPCompass.Application.Constants;

/// <summary>Azure Blob Storage container names.</summary>
public static class BlobContainers
{
    public const string CfpImages   = "cfp-images";
    public const string UserAvatars = "user-avatars";
}
```

---

## Local Development

No special setup required beyond the normal Aspire workflow:

```bash
dotnet run --project src/apphost/CFPCompass.AppHost
```

Aspire pulls `mcr.microsoft.com/azure-storage/azurite` and starts the emulator automatically. `builder.AddAzureStorageBlobs("blob-storage")` resolves to the Azurite connection string injected by Aspire — identical code runs in development and production.

**Developer prerequisites:** Docker Desktop running (for Azurite container). No Azure credentials needed for blob operations in local development.

---

## Production Managed Identity Requirements (Parker / Terraform)

The following RBAC assignments must be provisioned by Parker in `infra/modules/storage/` and `infra/modules/identity/`:

| Identity                          | Role                          | Scope                |
|-----------------------------------|-------------------------------|----------------------|
| Container App: API (system-assigned)      | Storage Blob Data Contributor | Storage Account      |
| Container Apps Jobs (system-assigned)     | Storage Blob Data Contributor | Storage Account      |

> Container App: Web and Azure Functions do NOT need blob access based on current architecture.

The storage account URI follows the pattern: `https://stcfpcompass{env}.blob.core.windows.net`

---

## SAS Token Prohibition

Because this project is pre-implementation:
- **Never introduce** `GenerateSasUri`, `GetSasUri`, `BlobSasBuilder`, `StorageSharedKeyCredential`, or `DefaultEndpointsProtocol=...;AccountKey=...` in any application code or configuration.
- All blob access **must** use `BlobServiceClient` registered via `builder.AddAzureStorageBlobs()` with `DefaultAzureCredential`.
- All `appsettings.Production.json` and Key Vault secrets for storage **must** use the `ServiceUri` pattern, never a connection string with an account key.

---

## Acceptance Criteria Checklist (for Kane's testing)

- [ ] `dotnet run --project src/apphost/CFPCompass.AppHost` starts Azurite and blob operations succeed locally
- [ ] `IBlobStorageService.UploadAsync` returns a plain blob URI (no `?sv=`, `?sig=`, or SAS query params)
- [ ] `IBlobStorageService.DownloadAsync` succeeds for an uploaded blob
- [ ] No `StorageSharedKeyCredential`, `BlobSasBuilder`, or `GenerateSasUri` anywhere in source code
- [ ] Infrastructure unit tests mock `IBlobStorageService` — no live Azure calls in unit tests
- [ ] Integration test against Azurite passes (upload → download → delete)
- [ ] Production: Container App (API) can upload to `cfp-images` container using managed identity (no key in config)
