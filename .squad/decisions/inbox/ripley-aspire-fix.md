# Decision: Aspire 9 NuGet SDK Migration Pattern for .NET 10

**Author:** Ripley  
**Date:** 2026-03-03  
**Related Issue:** #12 (squad/3-acs-managed-identity CI fix) / mirrors #11 fix

## Context

PR #12 and PR #11 both failed CI with NETSDK1228 because the `aspire` workload is not supported in the .NET 10 SDK. Aspire 9+ ships as NuGet packages only — `dotnet workload install aspire` is obsolete.

## Decision

All Aspire AppHost projects in this repo must use the NuGet-based SDK pattern:

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <Sdk Name="Aspire.AppHost.Sdk" Version="9.1.0" />
  <PropertyGroup>
    <IsAspireHost>true</IsAspireHost>
    <TargetFramework>net10.0</TargetFramework>
    ...
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Aspire.Hosting.AppHost" Version="9.1.0" />
    <!-- other Aspire.Hosting.Azure.* packages as needed -->
  </ItemGroup>
</Project>
```

Key rules:
1. `<Sdk Name="Aspire.AppHost.Sdk" Version="9.1.0" />` is **required** — it replaces the old workload.
2. `<PackageReference Include="Aspire.Hosting.AppHost" Version="9.1.0" />` is **also required** — both elements must be present.
3. No `global.json` workload references are needed.
4. ServiceDefaults (`Extensions.cs`) must have explicit `using Microsoft.AspNetCore.Builder;` and `using Microsoft.Extensions.DependencyInjection;` — implicit usings do not cover these in this project.

## Consequences

- All new AppHost projects scaffolded on this repo will include both the `<Sdk>` element and the `PackageReference` from day one.
- The CI workflow (`squad-ci.yml`) uses `actions/setup-dotnet@v4` with `dotnet-version: '10.x'` — no workload installation step is needed or wanted.
- Developers should not run `dotnet workload install aspire` — it will error on .NET 10 and is unnecessary.
