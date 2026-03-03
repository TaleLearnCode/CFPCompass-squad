# Decision: ACS Email — Managed Identity Pattern

**Author:** Ripley (Backend Dev)  
**Date:** 2026-03-03  
**Issue:** #3 — [MI Gap] Azure Communication Services: Use Managed Identity for email  
**Status:** Proposed

---

## Context

Issue #3 required switching the ACS email client from connection string authentication to Managed Identity. Key design decisions were made during implementation.

## Decisions

### 1. No Aspire Hosting Package for ACS

`Aspire.Hosting.Azure.CommunicationServices` does not exist on NuGet as a stable package (package not found during restore). ACS has no local emulator equivalent, so there is no Aspire hosting integration to use.

**Decision:** ACS is NOT wired as an Aspire resource in AppHost. The endpoint URI is read from `ConnectionStrings:acs` which developers set manually in `appsettings.Development.json` or user secrets for local dev. In production, the URI is set via environment variable or Key Vault reference.

**Impact on skill file:** The aspire-package-pairs skill should reflect that ACS has no hosting or integration package — ACS is configured as a plain connection string URI, not via an Aspire resource reference.

### 2. Direct `EmailClient` Singleton vs `AddAzureClients` Factory

Two options for registering `EmailClient`:
- **Option A:** `builder.Services.AddAzureClients(clients => clients.AddEmailClient(uri))` — requires knowing exact extension method overloads from `Microsoft.Extensions.Azure`
- **Option B:** `builder.Services.AddSingleton(new EmailClient(endpoint, new DefaultAzureCredential()))` — explicit, portable, no ambiguity about overload availability

**Decision:** Option B (direct singleton). The `Azure.Communication.Email` package may not register `AddEmailClient(Uri)` through `Microsoft.Extensions.Azure` in all versions. Direct instantiation is explicit and predictable. `DefaultAzureCredential` resolves correctly in both local dev and Azure Container Apps.

### 3. ACS Email Sender RBAC — Api and Workers Only

Only `CfpCompass.Api` and `CfpCompass.Workers` receive the `ACS Email Sender` role. The Blazor Web app does not send email directly (it calls the API). Azure Functions would need separate role assignments when scaffolded.

### 4. ACS-ConnectionString Key Vault Secret

The project is greenfield — no `ACS-ConnectionString` Key Vault secret exists yet. No cleanup required. The architecture should never provision this secret; only `ConnectionStrings:acs` (the endpoint URI, non-sensitive) should be used.

## Action Items

- **Parker:** When provisioning the ACS resource via Terraform, do NOT create an `ACS-ConnectionString` Key Vault secret. Only store the endpoint URI in app configuration.  
- **Dallas:** Update ADR-013 (Aspire AppHost packages) to note ACS has no Aspire hosting/integration package — endpoint URI configured via `ConnectionStrings:acs` directly.
- **Skill update:** Update `aspire-package-pairs` skill to note ACS has no package pair.
