# Dallas — Project Knowledge

## Project

**CFP Compass** — .NET 10 / C# web application aggregating open Calls for Papers for community speakers.

- **Stack:** .NET 10, C#, Azure Container Apps, Azure SQL / Cosmos DB, Azure Functions, Terraform, GitHub Actions, Azure AD B2C
- **Lead:** Chad Green
- **Team:** Dallas (Lead), Ripley (Backend), Lambert (Frontend), Parker (DevOps), Kane (Tester), Brett (Requirements)

## Core Context

**Architecture Summary:** Azure SQL Database (Serverless), Blazor Server, ASP.NET Core Identity + Fido2NetLib passkeys, Container Apps Jobs, Azure Managed Redis (C0), APIM Developer tier, event-driven write pattern (Service Bus + Azure Functions), Cloudflare Turnstile + Honeypot bot protection, .NET Aspire 13.1 for local development, OpenTelemetry-based observability, contract-first API/event design (OpenAPI 3.1 + AsyncAPI 3.0.0), health check patterns across all services. **Key decisions:** 4 open questions all resolved (domain: `cfpcompass.com`, bot protection: Turnstile+Honeypot, taxonomy: 10 Primary + 10 Secondary admin-extensible, email: `noreply@cfpcompass.com`). **Requirements:** v2 complete; i18n required from day 1. **Infrastructure:** Terraform IaC; GitHub Actions CI/CD; Container Apps hosting; multi-environment support (dev/staging/prod). **Azure App Configuration:** Adopted (reversed from initial rejection) for dynamic feature flags and centralized config with Key Vault references. **Routes:** `/api/` prefix removed; routes use `/v1/` directly (ADR-015). **Managed Identity gaps:** SQL (HIGH), Blob Storage (MEDIUM via RBAC + Aspire), ACS (LOW); Redis exception (immature Entra support). **Health checks:** Per-service responsibility; ACS degraded-only; `GET /health` standard. **Contract-first design:** OpenAPI 3.1 + AsyncAPI 3.0.0 required; Spectral/AsyncAPI CLI validation on PRs.

## Recent Decisions (2026-03-02 through 2026-03-03)

### ADR-013 Aspire Package Completion (2026-03-02 through 2026-03-03)

**Issue:** #1 — Blob Storage Managed Identity.  
**Decisions:** Added both `Aspire.Hosting.Azure.Storage` (AppHost wiring) and `Aspire.Azure.Storage.Blobs` (service integration) to ADR-013. Aspire packages travel in pairs: hosting enables emulator/resource wiring; integration enables DI/health/telemetry in service projects.


## Learnings

### ADR-013 Aspire Storage Package Update (2026-03-02)

**Issue:** #1 — Blob Storage Managed Identity handoff from Scribe.
**Action:** Added `Aspire.Hosting.Azure.Storage` to the AppHost package list in ADR-013 (architecture.md line 1539). The `.csproj` already had the package at Version 9.1.0 — this was a spec-alignment update only.
**Files updated:** `.squad/architecture.md` (ADR-013), `.squad/decisions/inbox/dallas-adr013-aspire-storage.md` (new).
**Files deleted:** `.squad/handoff-dallas-adr013-blob-storage.md` (resolved).
**Learning:** Keep architecture spec package lists in sync when implementation runs ahead of documentation. The AppHost .csproj was correct; the ADR lagged behind.

### ADR-013 Aspire Integration Package Completion (2026-03-02)

**Issue:** #1 — Follow-up to prior AppHost package update.
**Action:** Prior update added `Aspire.Hosting.Azure.Storage` to AppHost list but omitted the service-side integration package. This update adds `Aspire.Azure.Storage.Blobs` to the integration packages list (used by `CFPCompass.Infrastructure` for health checks, telemetry, and `DefaultAzureCredential`-based DI). Also added inline purpose notes to both Storage entries for future clarity.
**Files updated:** `.squad/architecture.md` (ADR-013 lines 1539-1540), `.squad/decisions/inbox/dallas-adr013-storage-update.md` (new).
**Learning:** When updating package dependency lists, always update both sides — hosting packages (AppHost) AND integration packages (service projects). They travel in pairs: the hosting package enables the emulator/resource wiring, the integration package enables DI/health/telemetry in consuming services.

### Cross-Agent Note (2026-03-03 — Scribe)

ADR-013 amendment committed. Aspire.Azure.Storage.Blobs added to integration packages list alongside Aspire.Hosting.Azure.Storage in AppHost list.

