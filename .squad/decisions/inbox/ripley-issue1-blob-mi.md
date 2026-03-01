# Decision: Blob Storage Access via Managed Identity

**Author:** Ripley (Backend Dev)
**Date:** 2026-03-01
**Issue:** #1
**Branch:** `squad/1-blob-storage-managed-identity`
**PR:** https://github.com/TaleLearnCode/CFPCompass-squad/pull/4

## Decision

Azure Blob Storage is accessed exclusively via Managed Identity (DefaultAzureCredential). No SAS tokens or connection strings appear in application code.

## Implementation Pattern

- `BlobServiceClient` is registered through .NET Aspire's `AddAzureBlobServiceClient("blobs")` extension, which wires DefaultAzureCredential automatically.
- `BlobStorageService` receives `BlobServiceClient` via constructor injection — no credential instantiation in service code.
- Local development uses Azurite emulator (`RunAsEmulator()` in AppHost) — zero credential config for devs.
- Azure environments (staging, production) rely on system-assigned Managed Identity with `Storage Blob Data Contributor` RBAC (assigned by Parker via Terraform).

## Rationale

- No secrets in code or app settings — eliminates an entire class of credential leak risk.
- SAS token rotation is an operational burden that MI eliminates.
- DefaultAzureCredential works transparently in local, CI, and cloud contexts without code changes.
- .NET Aspire's resource model makes the Azurite ↔ real storage swap seamless across environments.

## Files Created

```
src/CfpCompass.Api/Services/IBlobStorageService.cs
src/CfpCompass.Api/Services/BlobStorageService.cs
src/CfpCompass.Api/Extensions/BlobStorageExtensions.cs
src/CfpCompass.Api/Program.cs
src/CfpCompass.Api/CfpCompass.Api.csproj
src/CfpCompass.AppHost/Program.cs
src/CfpCompass.AppHost/CfpCompass.AppHost.csproj
src/CfpCompass.ServiceDefaults/Extensions.cs
src/CfpCompass.ServiceDefaults/CfpCompass.ServiceDefaults.csproj
```

## Open Item

Project naming uses `CfpCompass.{Layer}` per the issue spec, but the architecture doc (`architecture.md`) uses `CFPCompass.{Layer}`. Dallas or Chad should confirm canonical casing before the remaining projects are scaffolded.
