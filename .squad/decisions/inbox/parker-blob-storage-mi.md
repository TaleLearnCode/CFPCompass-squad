---
title: Blob Storage — Managed Identity Decision
author: Parker (DevOps)
date: 2026-03-01
issue: "#1"
status: proposed
---

# Decision: Blob Storage Access via Managed Identity (Issue #1)

## Summary

Azure Blob Storage in CFP Compass will use **Azure RBAC with Managed Identity** for all service access. SAS tokens and storage connection strings are prohibited.

## Decision

**Adopted:** `Storage Blob Data Contributor` and `Storage Blob Data Reader` RBAC roles are assigned to Container App and Azure Functions managed identities. No SAS tokens. No `Storage-ConnectionString` in Key Vault.

## Role Assignments

| Service | Role | Justification |
|---------|------|--------------|
| Container App (API) | `Storage Blob Data Contributor` | Uploads event logos via organizer submission |
| Container App (Web) | `Storage Blob Data Reader` | Reads blobs to serve event logo images |
| Azure Functions | `Storage Blob Data Contributor` | Processes uploaded blobs (validation/transformation) |
| Container Apps Jobs | _(none at MVP)_ | No blob interaction in scheduled job design |

## What Changes

### Infrastructure (Parker)
- Add `azurerm_role_assignment` resources in `infra/modules/storage/` for each identity above
- Remove `Storage-ConnectionString` from Key Vault provisioning
- Add `Storage:AccountName` as a non-secret value in Azure App Configuration (per-environment label)

### Application (Ripley — required before staging)
- Replace `new BlobServiceClient(connectionString)` with:
  ```csharp
  new BlobServiceClient(
      new Uri($"https://{accountName}.blob.core.windows.net"),
      new DefaultAzureCredential())
  ```
- Source `accountName` from App Configuration (not Key Vault)

## Docs Updated

- `docs/infrastructure/overview.md` — network diagram, Identity & Access Model table, Key Vault secret inventory
- `docs/infrastructure/architecture.md` — Managed Identity Wiring table (corrected roles)
- `.squad/agents/parker/blob-storage-mi-plan.md` — full Terraform planning document

## Rationale

SAS tokens are time-bounded credentials that must be rotated, stored as secrets, and distributed to services. Managed Identity eliminates this entire surface area: no credential storage, no rotation, no expiry, full Azure AD audit trail.

## Cross-Agent Actions Required

- **Ripley:** Update `BlobServiceClient` registration (see application change above)
- **Dallas:** No architecture change — MI was already the stated intent; this formalises blob storage
