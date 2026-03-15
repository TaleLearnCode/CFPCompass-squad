# Decision: Aspire Workload → NuGet SDK Migration Pattern

**Author:** Parker  
**Date:** 2026-03-03  
**Status:** Resolved (applied to PR #11 / squad/2-azure-sql-managed-identity)

---

## Context

CI on PR #11 (`squad/2-azure-sql-managed-identity`) was failing with:

- **NETSDK1228** — `CfpCompass.AppHost`: "This project depends on the Aspire Workload which has been deprecated."
- **CS0246** (cascade) — `CfpCompass.ServiceDefaults/Extensions.cs`: `WebApplication` type not found.

Root cause: .NET 10 SDK raises NETSDK1228 when `IsAspireHost=true` but `AspireHostingSDKVersion` is missing. This property is set by the `Aspire.AppHost.Sdk` MSBuild SDK, which was absent from the project file.

Once the primary build failure was resolved, additional pre-existing errors surfaced (all masked by the early abort):

| File | Error | Fix |
|------|-------|-----|
| `ServiceDefaults/Extensions.cs` | Missing `using` for `WebApplication`, `AddServiceDiscovery`, `AddHealthChecks`, `ConfigureHttpClientDefaults`, `AddOpenTelemetry` overloads | Added 4 missing `using` directives |
| `Api/Extensions/BlobStorageExtensions.cs` | `AddAzureBlobServiceClient` does not exist — method is `AddAzureBlobClient` in `Aspire.Azure.Storage.Blobs 9.1.0` | Renamed method, added DI using |
| `Tests/BlobStorageServiceUnitTests.cs` | `null` passed for non-nullable `PublicAccessType` / `DeleteSnapshotsOption` (struct enums) in `Azure.Storage.Blobs 12.27.0` | Replaced `null` with `It.IsAny<T>()` |

---

## Migration Pattern (for future reference)

### AppHost.csproj

```xml
<Project Sdk="Microsoft.NET.Sdk">

  <!-- Required: sets AspireHostingSDKVersion, satisfying .NET 10 NETSDK1228 check -->
  <Sdk Name="Aspire.AppHost.Sdk" Version="9.1.0" />

  <PropertyGroup>
    <IsAspireHost>true</IsAspireHost>
    ...
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Aspire.Hosting.AppHost" Version="9.1.0" />
    ...
  </ItemGroup>
</Project>
```

### ServiceDefaults/Extensions.cs — Required using directives

`Microsoft.NET.Sdk` (non-Web) projects need explicit usings that `.Web` SDK provides automatically:

```csharp
using Microsoft.AspNetCore.Builder;                // WebApplication
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.DependencyInjection;    // AddHealthChecks, AddServiceDiscovery, ConfigureHttpClientDefaults
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Logging;               // CRITICAL: required for ILoggingBuilder.AddOpenTelemetry(Action<>) overload
using OpenTelemetry;
using OpenTelemetry.Logs;                          // OpenTelemetryLoggerOptions
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;
```

> **Note on `Microsoft.Extensions.Logging`:** Without this using, `ILoggingBuilder.AddOpenTelemetry(Action<OpenTelemetryLoggerOptions>)` produces `CS1501` ("no overload takes 1 arguments") even though the DLL contains the overload. The using is required for correct overload resolution in this package combination.

---

## ⚠️ Action Required: PR #12 (squad/3-acs-managed-identity)

**Ripley / Dallas: PR #12 is likely affected by the same issues.**

- `squad/3-acs-managed-identity` had a partial Aspire fix (`AppHost.csproj` + some usings) but was **missing `using Microsoft.Extensions.Logging;`** and the `BlobStorageExtensions.cs` / test fixes.
- Parker applied the complete fix and pushed to `squad/3-acs-managed-identity` in the same session.
- **Verify that PR #12 CI passes** after this push. If not, the same pattern applies.

---

## Files Changed

| File | Change |
|------|--------|
| `src/CfpCompass.AppHost/CfpCompass.AppHost.csproj` | Added `<Sdk Name="Aspire.AppHost.Sdk" Version="9.1.0" />` |
| `src/CfpCompass.ServiceDefaults/Extensions.cs` | Added 4 missing using directives (Builder, DI, Logging, OTel.Logs) |
| `src/CfpCompass.Api/Extensions/BlobStorageExtensions.cs` | `AddAzureBlobServiceClient` → `AddAzureBlobClient`; added DI using |
| `tests/CfpCompass.Api.Tests/Services/BlobStorageServiceUnitTests.cs` | `null` → `It.IsAny<PublicAccessType/DeleteSnapshotsOption>()` |
