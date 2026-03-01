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

### Issue #1 — Blob Storage via Managed Identity (2026-03-01)

- **Pattern:** .NET Aspire's `AddAzureBlobServiceClient("blobs")` handles DefaultAzureCredential injection automatically — no manual `new DefaultAzureCredential()` needed in application code.
- **Local dev:** `RunAsEmulator()` in AppHost wires Azurite; no credentials or config needed for local runs.
- **Greenfield advantage:** No SAS token cleanup required — MI pattern adopted from day one.
- **Aspire resource name matters:** The string `"blobs"` passed to `AddAzureBlobServiceClient` must match the `AddBlobs("blobs")` name in AppHost exactly. Mismatch = runtime failure.
- **ServiceDefaults project naming:** `<IsAspireSharedProject>true</IsAspireSharedProject>` is required in the `.csproj` so Aspire tooling treats it correctly at build time.
- **Architecture naming:** The architecture doc uses `CFPCompass.{Layer}` (capitalized) but issue #1 explicitly requested `CfpCompass.{Layer}`. This scaffold follows the issue; future projects should reconcile with Dallas/Chad.

