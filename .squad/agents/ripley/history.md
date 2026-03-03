# Ripley — Project Knowledge

## Project

**CFP Compass** — .NET 10 / C# web application aggregating open Calls for Papers for community speakers.

- **Stack:** .NET 10, C#, Azure Container Apps, Azure SQL / Cosmos DB, Azure Functions, Terraform, GitHub Actions, Azure AD B2C
- **Lead:** Chad Green
- **Team:** Dallas (Lead), Ripley (Backend), Lambert (Frontend), Parker (DevOps), Kane (Tester), Brett (Requirements)

## Core Context

- REST API: authenticated, GET/POST/PUT for CFPs, submissions, and metadata; proper authorization and versioning
- Organizer submission workflow: submitted → moderation → approved/rejected → published
- User accounts: registration, login, favorites, notification preferences
- Email triggers: deadline reminders, weekly digest — fired from Azure Functions or background workers
- Authentication via Azure AD B2C or built-in .NET Identity
- Data: Azure SQL or Cosmos DB — final choice TBD by Dallas

## Latest Context (2026-02-28)

**Brett Requirements v1 Delivered:** Requirements breakdown initially available at `.squad/requirements.md` — 6 epics, 15 features, 30+ user stories with Given/When/Then acceptance criteria. Included 10 flagged open questions requiring team decision.

**Brett Requirements v2 Complete:** All 10 open questions resolved by Chad Green and integrated. Feature 1.4 (Past CFPs Archive) added. **Consult requirements.md v2 before backend implementation.** Critical backend change: API must support i18n from day 1 — all string fields (CFP title, description, organizer name, etc.) must be properly localized. No hard-coded strings.

**Dallas Architecture v1 Complete:** System architecture finalized at `.squad/architecture.md` with 6 ADRs: Azure SQL (Serverless), Blazor Server, ASP.NET Core Identity + Fido2NetLib passkeys, Container Apps Jobs, Redis Basic C0, APIM Consumption. **Read architecture.md before backend schema design.** Backend decisions locked: EF Core on SQL, passkey integration via Fido2NetLib, APIM rate limiting enforcement (100 req/min read, 10 req/min write), container-based deployment. 4 open questions remain for Chad Green (domain, bot protection, taxonomy, email sender).

## Learnings

### 2026-03-01 — Issue #1: Blob Storage Managed Identity

**Finding:** Project is pre-implementation — no source files exist. No SAS token code to remove. The architecture spec already mandates `Azure.Storage.Blobs` in Infrastructure and `IBlobStorageService` in Application, but ADR-013's Aspire AppHost wiring is missing `Aspire.Hosting.Azure.Storage`. The managed identity table in the infra docs also omits `Storage Blob Data Contributor` for any identity.

**Decisions made:**
- Use `builder.AddAzureStorageBlobs("blob-storage")` (Aspire integration), not a manual `BlobServiceClient` constructor — consistent with how SQL/Redis/ServiceBus are registered.
- `IBlobStorageService` has no SAS methods. Returns plain blob URIs. Images served via Front Door CDN (which uses its own MI to read from storage).
- Only `Container App: API` and `Container Apps Jobs` need `Storage Blob Data Contributor` RBAC. Web and Functions do not.
- `appsettings.json` uses `ServiceUri` pattern only. No account keys in config ever.

**Artifacts produced:**
- `.squad/agents/ripley/blob-storage-mi-plan.md` — full implementation plan with code
- `.squad/decisions/inbox/ripley-blob-storage-mi.md` — decision record for Scribe to merge
- Action item for Parker: Terraform RBAC assignments + update infra architecture docs
- Action item for Dallas: Update ADR-013 to include `Aspire.Hosting.Azure.Storage` in AppHost packages list


### Issue #1 — Blob Storage via Managed Identity (2026-03-01)

- **Pattern:** .NET Aspire's `AddAzureBlobServiceClient("blobs")` handles DefaultAzureCredential injection automatically — no manual `new DefaultAzureCredential()` needed in application code.
- **Local dev:** `RunAsEmulator()` in AppHost wires Azurite; no credentials or config needed for local runs.
- **Greenfield advantage:** No SAS token cleanup required — MI pattern adopted from day one.
- **Aspire resource name matters:** The string `"blobs"` passed to `AddAzureBlobServiceClient` must match the `AddBlobs("blobs")` name in AppHost exactly. Mismatch = runtime failure.
- **ServiceDefaults project naming:** `<IsAspireSharedProject>true</IsAspireSharedProject>` is required in the `.csproj` so Aspire tooling treats it correctly at build time.
- **Architecture naming:** The architecture doc uses `CFPCompass.{Layer}` (capitalized) but issue #1 explicitly requested `CfpCompass.{Layer}`. This scaffold follows the issue; future projects should reconcile with Dallas/Chad.

### Cross-Agent: Parker's Issue #1 Infrastructure Work (2026-03-01)

Parker created Terraform module for Issue #1 in parallel. Infrastructure half complete:
- `blob-storage-rbac` module with `azurerm_role_assignment` loop for three Container Apps
- Role assignments use `uuidv5` for deterministic naming (prevents Terraform drift)
- Dev environment caller at `infrastructure/terraform/environments/dev/blob-storage-rbac.tf`
- Architecture docs updated: MI wiring table + SAS→RBAC migration notes
- All three Container Apps (Api, Web, Workers) receive `Storage Blob Data Contributor` RBAC

Ripley's application code depends on Parker's Terraform RBAC assignments. Parker confirmed all three Container Apps need Blob access.

### Issue #3 — ACS Email via Managed Identity (2026-03-03)

- **Finding:** `Aspire.Hosting.Azure.CommunicationServices` does NOT exist on NuGet. ACS has no local emulator, so there is no Aspire resource abstraction to use. ACS is configured via plain `ConnectionStrings:acs` (the endpoint URI).
- **Pattern:** `EmailClient` registered as a direct singleton with `new EmailClient(endpoint, new DefaultAzureCredential())`. No `AddAzureClients` factory needed — direct instantiation is cleaner when no Aspire integration package exists.
- **RBAC:** ACS Email Sender role (`b9d4cd7b-d855-4f0c-b635-164d572a3f89`) assigned to `Api` and `Workers` Container Apps. Web does not send email directly.
- **No cleanup needed:** Project is greenfield — `ACS-ConnectionString` Key Vault secret was never provisioned. Architecture should never create it.
- **Skill created:** `.squad/skills/azure-sdk-managed-identity/SKILL.md` — covers both Aspire-integrated and direct-registration MI patterns for all Azure SDK clients.
- **Decision doc:** `.squad/decisions/inbox/ripley-issue3-acs-mi.md` merged into `.squad/decisions.md` by Scribe (2026-03-03)
- **PR #12** opened on `squad/3-acs-managed-identity`
- **Cross-agent task:** Parker (Issue #2) completed SQL MI in parallel; blocked on Parker's Key Vault decision re: not provisioning ACS-ConnectionString secret

### Cross-Agent Note (2026-03-03 — Scribe)

Tests written by Kane for BlobStorageService are at `tests/CfpCompass.Api.Tests/BlobStorageServiceIntegrationTests.cs`. Note: DeleteAsync returns Task (not Task<bool> as in the plan). Tests verify deletion via ExistsAsync.
