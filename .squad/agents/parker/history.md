# Parker — Project Knowledge

## Project

**CFP Compass** — .NET 10 / C# web application aggregating open Calls for Papers for community speakers.

- **Stack:** .NET 10, C#, Azure Container Apps, Azure SQL / Cosmos DB, Azure Functions, Terraform, GitHub Actions, Azure AD B2C
- **Lead:** Chad Green
- **Team:** Dallas (Lead), Ripley (Backend), Lambert (Frontend), Parker (DevOps), Kane (Tester), Brett (Requirements)

## Core Context

- Hosting: Azure Container Apps (primary app); Azure Functions or containerized workers (background jobs)
- Storage: Azure SQL or Cosmos DB — IaC must support both until decision is made
- Auth infrastructure: Azure AD B2C tenant and app registration
- IaC: Terraform for all Azure resources — Key Vault, Container Registry, Container Apps env, SQL/Cosmos, Functions, B2C config
- CI/CD: GitHub Actions — build, test, containerize, push to ACR, deploy to Container Apps
- Environments: at minimum dev + prod; staging desirable

## Latest Context (2026-02-28)

**Brett Requirements v2 Complete:** All 10 open questions resolved by Chad Green and integrated into `.squad/requirements.md`. Feature 1.4 (Past CFPs Archive) added. **Consult requirements.md v2 before infrastructure implementation.** Critical infrastructure change: Ensure i18n architecture is built in from day 1 — consider localization strategy for app configuration, resource names, and regional deployments.

**Dallas Architecture v1 Complete:** System architecture finalized at `.squad/architecture.md` with 6 ADRs: Azure SQL (Serverless), Blazor Server, ASP.NET Core Identity + Fido2NetLib passkeys, Container Apps Jobs, Redis Basic C0, APIM Consumption. **Read architecture.md before infrastructure provisioning.** DevOps decisions locked: Terraform IaC for Container Apps, SQL (Serverless tier), Redis Basic C0, APIM (Consumption tier), Key Vault, ACR, GitHub Actions CI/CD for containerized deployments. 4 open questions remain for Chad Green (domain, bot protection, taxonomy, email sender).

## Work — Managed Identity Gap Work Items (2026-02-28)

Created three GitHub issues to address passwordless authentication gaps:

1. **Issue #2 (HIGH):** Azure SQL needs Managed Identity for Web + API Container Apps (currently uses Key Vault secret)
2. **Issue #1 (MEDIUM):** Azure Blob Storage should replace SAS tokens with Managed Identity RBAC
3. **Issue #3 (LOW):** Azure Communication Services email should use ManagedIdentityCredential instead of connection string

**Actions taken:**
- Created `infrastructure`, `security`, `managed-identity` GitHub labels (prerequisites missing)
- All issues include problem statement, multi-phase solutions, and acceptance criteria
- Summary written to `.squad/decisions/inbox/parker-mi-gaps-created.md`
- Assigned HIGH priority to SQL issue (largest security gap); MEDIUM/LOW for storage/email

**Next:** Proceed with Phase 1 (SQL) as soon as Dallas/Ripley review application implications.

## Work — MI Gaps Ingested into Decisions (2026-03-01)

Parker's three MI GitHub issues merged into `.squad/decisions.md` with orchestration and session logs. Dallas architecture review (Agent 10) identified gaps; Parker operationalized them into prioritized work items. Decision finalized in orchestration batch; ready for implementation phase.

**Cross-agent awareness:** Dallas (Agent 11) aware of Parker's MI work; noted in ADR-015 decision and infrastructure overview update. Ash unaware of MI gaps (Technical Writer focus); not relevant to documentation scope.

## Learnings

### CFPCompass.Api.Tests Project Scaffold (2026-03-02)

- **Created `tests/CfpCompass.Api.Tests/CfpCompass.Api.Tests.csproj`** — net10.0, xUnit-based, referencing `CfpCompass.Api` and `CfpCompass.AppHost` (with `IsAspireProjectResource="false"`). Added to `CFPCompass.sln` via `dotnet sln add`.
- **Added `Moq 4.*`** — Kane's gap report omitted it, but `BlobStorageServiceUnitTests.cs` requires it. Included in the project file.
- **Resolved NuGet package versions:**
  - `Aspire.Hosting.Testing` → `9.5.2`
  - `Azure.Storage.Blobs` → `12.27.0`
  - `Microsoft.Extensions.Logging.Abstractions` → `10.0.3`
  - `Microsoft.NET.Test.Sdk` → `17.14.1`
  - `Moq` → `4.20.72`
  - `xunit` → `2.9.3`
  - `xunit.runner.visualstudio` → `2.8.2`
- **Pre-existing version conflict fixed:** `CfpCompass.Api.csproj` had `Microsoft.Extensions.Azure 1.7.6` but `Aspire.Azure.Storage.Blobs 9.1.0` requires `>= 1.10.0`. Bumped to `1.10.0` — this was a latent bug blocking all restores through the Api project.
- **KubernetesClient NU1902 warning:** `CfpCompass.AppHost` pulls in `KubernetesClient 15.0.1` which has a known moderate-severity vulnerability (GHSA-w7r3-mgwf-4mqq). Not blocking; pre-existing transitive dependency via Aspire.Hosting. Flagged in decisions inbox.
- **CI note:** `squad-ci.yml` is a placeholder stub (`echo "No build commands configured"`). No `dotnet test` step exists. Integration tests require Docker (Azurite). When CI is wired up, use `--filter "Category=Integration"` to gate integration tests separately from fast unit tests.



### Issue #1 — Blob Storage RBAC (2026-03-01)

- **All three Container Apps need Blob Storage access:** `CfpCompass.Api` (upload/read logos), `CfpCompass.Web` (read logos for CDN), `CfpCompass.Workers` (write digests/exports). Assigned `Storage Blob Data Contributor` to all three — simpler and forward-proof.
- **`uuidv5` for deterministic role assignment names:** Using `uuidv5("url", ...)` on a composite key prevents Terraform from generating a new UUID on each plan, avoiding unnecessary drift and re-creation of role assignments.
- **Docs were already rich:** `docs/infrastructure/architecture.md` already existed with a detailed Managed Identity wiring table. Surgical edits only — no wholesale rewrites needed.
- **Ripley owns the application side:** SDK switch (`Aspire.Azure.Storage.Blobs`), `DefaultAzureCredential` wiring, and SAS token removal are Ripley's scope. Parker's work (Terraform RBAC) is a prerequisite, not the whole fix. The issue acceptance criteria span both agents.
- **Decisions inbox:** Summary written to `.squad/decisions/inbox/parker-issue1-blob-mi.md`.

### Cross-Agent: Ripley's Issue #1 Application Work (2026-03-01)

Ripley scaffolded Issue #1 application layer in parallel. Opened draft PR #4 with:
- `IBlobStorageService` interface and `BlobStorageService` implementation
- Aspire integration: `AddAzureBlobServiceClient("blobs")` in AppHost with Azurite emulator for local dev
- Refactored Program.cs and .csproj files for Api, AppHost, ServiceDefaults
- Pattern: `BlobServiceClient` injected via DI; DefaultAzureCredential automatic; no secrets in code

Ripley flagged naming question: Issue #1 specifies `CfpCompass.{Layer}`, but architecture.md uses `CFPCompass.{Layer}`. Dallas/Chad to resolve before remaining projects scaffolded.

Parker's Terraform work (RBAC assignments + uuidv5 deterministic naming) is a prerequisite for Ripley's application code.

### CI Workflow — squad-ci.yml (2026-03-02)

- **Replaced the placeholder stub** with a proper two-job workflow targeting `push` and `pull_request` to `main`.
- **Job 1 (`build-and-unit-test`):** restore → build Release → `dotnet test` with `--filter "Category!=Integration"` → upload TRX artifact. Uses `--no-build` on the test step to avoid double-building.
- **Job 2 (`integration-test`):** `needs: build-and-unit-test`, restore → `dotnet test` on the Api.Tests project with `--filter "Category=Integration"` → upload TRX artifact. Commented that Docker is available on `ubuntu-latest` by default (required for Azurite).
- **Workflow-level env vars:** `DOTNET_SKIP_FIRST_TIME_EXPERIENCE` and `DOTNET_CLI_TELEMETRY_OPTOUT` both set to `true`.
- **No secrets required:** Integration tests run against Azurite locally; no Azure credentials in CI.
- **Existing workflows preserved:** Checked all `.github/workflows/` — the other Squad workflows (`squad-triage.yml`, `squad-release.yml`, `squad-promote.yml`, `squad-preview.yml`, `squad-label-enforce.yml`, `squad-issue-assign.yml`, `squad-insider-release.yml`, `squad-heartbeat.yml`, `squad-docs.yml`, `sync-squad-labels.yml`) are untouched. Only `squad-ci.yml` was modified.
- **Trait gap found:** `BlobStorageServiceIntegrationTests.cs` has no `[Trait("Category", "Integration")]` on any method or class. The `--filter "Category=Integration"` will match zero tests until Kane adds the class-level trait. Wrote `.squad/decisions/inbox/parker-ci-trait-gap.md` to flag this for Kane.
- **Filter strategy:** Class-level `[Trait("Category", "Integration")]` is the correct xUnit pattern — decorates all `[Fact]` methods on the class without per-method boilerplate.

### Issue #1 — Planning Doc & Role Correction (2026-03-01, session 2)
- **No Terraform files exist yet** — project is pre-implementation. Wrote `.squad/agents/parker/blob-storage-mi-plan.md` as the authoritative planning document with exact `azurerm_role_assignment` HCL blocks, module variable wiring, and list of items to remove (SAS tokens, `Storage-ConnectionString`).
- **Web should be Reader, not Contributor:** Previous session assigned `Storage Blob Data Contributor` to all three services. Corrected architecture.md to grant `Storage Blob Data Reader` to Container App (Web) — Web only reads/serves logos, never writes. Contributor is overly permissive for a read-only consumer.
- **Container Apps Jobs need no blob access at MVP** — Jobs (CfpExpiryJob, DeadlineReminderJob, etc.) do not interact with Blob Storage in the current design. Removed erroneous Contributor assignment from Jobs row.
- **`Storage-ConnectionString` removed from Key Vault inventory** — overview.md updated with explicit callout: blob access is RBAC-only; storage account name is non-secret App Configuration value.
- **Decisions inbox written** — `.squad/decisions/inbox/parker-blob-storage-mi.md` documents the final role assignments and cross-agent actions required (Ripley must update `BlobServiceClient`).

### Issue #2 — Azure SQL Managed Identity (2026-03-03)
- **Completed:** Created `azure-sql-rbac` Terraform module using null_resource pattern with `sqlcmd` for deterministic role assignments
- **Updated connection string format** in `appsettings.json` to support Managed Identity authentication (removed `Password=` requirement)
- **Removed `AzureSql-ConnectionString`** from Key Vault documentation — SQL access is RBAC-only
- **Updated architecture docs** with SQL MI wiring table for Container Apps (Web + API + Functions)
- **PR #11** opened on `squad/2-azure-sql-managed-identity`
- **Skill created:** `.squad/skills/azure-sql-mi/SKILL.md` — SQL MI pattern for Team reference
- **Cross-agent task:** Ripley (Issue #3) completed ACS MI in parallel; no blocking dependencies

### Issue #3 — ACS Managed Identity (Cross-Agent Note, 2026-03-03)
- **Ripley's work on Issue #3 (ACS Email)** completed in parallel: refactored `AcsEmailService` to use `DefaultAzureCredential` + endpoint URI (no Aspire package exists). Terraform module created; decision documented. **Action item for Parker:** Do NOT create `ACS-ConnectionString` Key Vault secret during ACS resource provisioning — only endpoint URI in app config.
- **New skill:** `.squad/skills/azure-sdk-managed-identity/SKILL.md` covers both Aspire-integrated and direct-registration MI patterns.
