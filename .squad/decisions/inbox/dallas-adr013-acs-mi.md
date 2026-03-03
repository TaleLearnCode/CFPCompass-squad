# Decision: ADR-013 Amendment — Azure Communication Services Managed Identity

**Owner:** Dallas (Lead & Architect)  
**Date:** 2026-03-03  
**Issue:** #3 — [MI Gap] Azure Communication Services: Use Managed Identity for email  
**Status:** Complete

## Summary

Issue #3 (Ripley's work) required switching ACS email client authentication from connection string to Managed Identity. During implementation, three key discoveries emerged:

1. **Aspire.Hosting.Azure.CommunicationServices does not exist** on NuGet (no preview, no stable). ACS has no local emulator, so Aspire provides no hosting integration.
2. **ACS endpoint URI is configured outside Aspire** via `ConnectionStrings:acs` in appsettings — non-sensitive configuration, not a secret.
3. **RBAC role assignment** (Terraform `acs-email-rbac` module) grants `ACS Email Sender` role only to Api and Workers Container App managed identities.

## Decision

**ADR-013 (.NET Aspire 13.1) has been amended** to document the ACS managed identity approach. The amendment supersedes the earlier incorrect assumption that `Aspire.Hosting.Azure.CommunicationServices` would be available.

### Changes Made

1. **Removed** `Aspire.Hosting.Azure.CommunicationServices` from ADR-013 package list (line 144).
2. **Added** new subsection "ADR-013 Amendment: Azure Communication Services Managed Identity" documenting:
   - No Aspire hosting package for ACS
   - Direct `EmailClient` instantiation with endpoint URI + `DefaultAzureCredential()`
   - RBAC role assignment to Api and Workers only
   - No `ACS-ConnectionString` secret provisioning
3. **Updated** Record History timestamp to reflect amendment date.

### Implementation Pattern

```csharp
// AcsEmailService.cs
builder.Services.AddSingleton(new EmailClient(
    new Uri(builder.Configuration["ConnectionStrings:acs"]),
    new DefaultAzureCredential()
));
```

- **Local dev:** Set `ConnectionStrings:acs` in `appsettings.Development.json` (user secrets)
- **Production:** Set via environment variable or App Configuration
- **No Key Vault entry** for the endpoint URI (non-sensitive)

### Cross-Team Impact

- **Ripley (Backend):** No changes; implementation already follows this pattern.
- **Parker (DevOps):** Ensure Terraform `acs-email-rbac` module assigns `ACS Email Sender` role (role ID `b9d4cd7b-d855-4f0c-b635-164d572a3f89`) to Api and Workers Container App MIs.
- **Kane (Tester):** No local ACS emulator available; integration tests will use sandbox ACS resource.
- **All:** ADR-013 now correctly documents ACS as outside Aspire scope.

## Rationale

Aspire does not provide hosting packages for all Azure services. The correct pattern when a hosting package does not exist is:
1. Configure the service endpoint URI in appsettings (non-sensitive).
2. Use `DefaultAzureCredential()` for authentication in all environments.
3. Let RBAC govern which managed identities can access the resource.

This avoids the anti-pattern of storing connection strings in Key Vault and keeps architecture decisions explicit in ADRs.

## Files Updated

- `docs/registers/decisions/ADR-013-dotnet-aspire.md` — Removed non-existent Aspire package reference; added amendment subsection
- `.squad/agents/dallas/history.md` — Logged the learning under "## Learnings"

## Approval

**Dallas (Lead & Architect):** ✓ Approved  
This amendment reflects Ripley's successful implementation of Issue #3 and corrects ADR-013 documentation to match reality.
