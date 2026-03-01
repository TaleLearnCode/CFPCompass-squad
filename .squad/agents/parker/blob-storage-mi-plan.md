---
title: Blob Storage — Managed Identity Migration Plan
author: Parker (DevOps)
date: 2026-03-01
issue: "#1"
status: planned
---

# Blob Storage — Managed Identity Migration Plan

## Context

GitHub Issue #1 identified that the current design documents reference **SAS tokens** for Azure Blob Storage access. The CFP Compass security posture requires all service-to-service authentication to use **Azure Managed Identity** — no connection strings, SAS tokens, or storage access keys in configuration or Key Vault.

Reference: `docs/infrastructure/overview.md` — Infrastructure Overview  
Reference: `docs/infrastructure/architecture.md` — Managed Identity Wiring

---

## Blob Storage Usage

The Storage Account (`stcfpcompass{env}`, GPv2 LRS) holds a single container:

| Container | Contents | Access Pattern |
|-----------|----------|----------------|
| `event-assets` | Event logo images uploaded by organizers | API writes (upload); Web reads (serve URLs); optional Functions processing |

---

## Which Container Apps Need Blob Access

| Service | Role Required | Reason |
|---------|--------------|--------|
| Container App (API) | `Storage Blob Data Contributor` | Accepts event logo uploads via POST; reads blobs to serve signed-less URLs |
| Container App (Web) | `Storage Blob Data Reader` | Renders event logo `<img>` tags; reads blob metadata if needed |
| Azure Functions | `Storage Blob Data Contributor` | Processes uploaded blobs (e.g., validation, resizing); writes processed output |
| Container Apps Jobs | None required at MVP | Jobs do not interact with blob storage in current design |

> **Note:** Container App (Web) only needs `Reader` because it surfaces public blob URLs (anonymous read on the container) or uses the managed identity solely for metadata/management operations. If the `event-assets` container is set to **private** (recommended), Web needs `Storage Blob Data Reader` to generate `BlobClient` instances with `DefaultAzureCredential` and serve pre-authenticated URLs without SAS tokens.

---

## Terraform Resources to Add

All role assignments live in `infra/modules/storage/main.tf` (or a dedicated `rbac.tf` within that module). The identity references come from the `identity` module outputs.

```hcl
# ── Storage Blob Data Contributor — Container App (API) ──────────────────────
# Allows the API service to upload, read, and delete event logos.
resource "azurerm_role_assignment" "api_storage_blob_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.api_identity_principal_id
  description          = "CFPCompass API: upload and manage event logos in Blob Storage"
}

# ── Storage Blob Data Reader — Container App (Web) ───────────────────────────
# Allows the Web service to read blobs (serve event logo images).
resource "azurerm_role_assignment" "web_storage_blob_reader" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.web_identity_principal_id
  description          = "CFPCompass Web: read event logos from Blob Storage"
}

# ── Storage Blob Data Contributor — Azure Functions ──────────────────────────
# Allows Functions to process uploaded blobs (validation, transformation).
resource "azurerm_role_assignment" "functions_storage_blob_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.functions_identity_principal_id
  description          = "CFPCompass Functions: process and write blobs in Blob Storage"
}
```

### Module Variable Additions (`infra/modules/storage/variables.tf`)

```hcl
variable "api_identity_principal_id" {
  type        = string
  description = "Principal ID of the Container App (API) managed identity."
}

variable "web_identity_principal_id" {
  type        = string
  description = "Principal ID of the Container App (Web) managed identity."
}

variable "functions_identity_principal_id" {
  type        = string
  description = "Principal ID of the Azure Functions managed identity."
}
```

### Root Module Wiring (`infra/main.tf`)

```hcl
module "storage" {
  source = "./modules/storage"

  # ... existing storage vars ...

  api_identity_principal_id       = module.identity.api_principal_id
  web_identity_principal_id       = module.identity.web_principal_id
  functions_identity_principal_id = module.identity.functions_principal_id
}
```

---

## What to Remove

| Item | Location | Action |
|------|----------|--------|
| `Storage-ConnectionString` secret | `infra/modules/keyvault/main.tf` | Delete the `azurerm_key_vault_secret` resource |
| `Storage-ConnectionString` output | `infra/modules/storage/outputs.tf` | Remove the sensitive output (no longer needed) |
| Storage access key retrieval | Any `azurerm_storage_account_sas` data source | Delete entirely — SAS generation is prohibited |
| `Storage-ConnectionString` env var | Container App / Function App env config | Remove; replace with `AZURE_STORAGE_ACCOUNT_URL` (non-secret) |

---

## Application-Side Change (Ripley's Scope)

> Parker's scope ends at infrastructure. Ripley (Backend) needs to update blob client registration.

Replace connection-string-based `BlobServiceClient`:
```csharp
// BEFORE (SAS / connection string)
builder.Services.AddSingleton(
    new BlobServiceClient(connectionString));
```

With `DefaultAzureCredential`:
```csharp
// AFTER (Managed Identity)
builder.Services.AddSingleton(new BlobServiceClient(
    new Uri($"https://{storageAccountName}.blob.core.windows.net"),
    new DefaultAzureCredential()));
```

The `storageAccountName` is a **non-secret** config value from Azure App Configuration (no Key Vault reference required).

---

## Key Vault Secret Inventory Change

Remove `Storage-ConnectionString` from the Key Vault secret table.  
Add `StorageAccount-Name` to App Configuration (non-secret, environment label: dev/staging/prod).

---

## Acceptance Criteria

- [ ] `azurerm_role_assignment` blocks exist in `infra/modules/storage/` for API (Contributor), Web (Reader), Functions (Contributor)
- [ ] No `azurerm_storage_account_sas` data sources anywhere in Terraform
- [ ] No `Storage-ConnectionString` secret provisioned in Key Vault
- [ ] `docs/infrastructure/overview.md` network diagram shows managed identity (not SAS tokens) for blob storage
- [ ] `docs/infrastructure/architecture.md` Managed Identity Wiring table includes blob storage rows
- [ ] Application (`BlobServiceClient`) uses `DefaultAzureCredential` + account URL (Ripley)

---

## Dependencies

- `infra/modules/identity/` must expose `api_principal_id`, `web_principal_id`, `functions_principal_id` outputs
- `infra/modules/storage/` must depend on `module.identity` (handled by root `main.tf` ordering)
- Ripley must update `BlobServiceClient` registration before this goes to staging
