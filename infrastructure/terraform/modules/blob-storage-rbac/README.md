# blob-storage-rbac

Assigns the **Storage Blob Data Contributor** RBAC role to the system-assigned managed identity of each CFP Compass Container App that requires Azure Blob Storage access. This eliminates SAS token usage in favour of `DefaultAzureCredential`-based access.

## Why this module exists

Azure Blob Storage was previously accessed via SAS tokens (tracked in [GitHub Issue #1](https://github.com/TaleLearnCode/CFPCompass-squad/issues/1)). SAS tokens:

- Expire and require rotation management
- Carry shared-credential leak risk if exposed in logs or config
- Are inconsistent with the Managed Identity pattern used for Key Vault, Service Bus, and ACR

This module replaces SAS token access with Azure RBAC using system-assigned managed identities — the same credential model used across all other CFP Compass service connections.

## Services requiring Blob Storage access

| Container App | Blob operations |
|---|---|
| `CfpCompass.Api` | Upload event logos; serve logo metadata |
| `CfpCompass.Web` | Read event logos (served via Front Door CDN) |
| `CfpCompass.Workers` | Write exports and digest outputs |

All three receive `Storage Blob Data Contributor` (role ID `ba92f5b4-2d11-453d-a403-e96b0029c9fe`) for consistency and to accommodate future write needs without re-running Terraform.

## Required Azure permissions for the Terraform principal

The service principal running Terraform must have **Owner** or **User Access Administrator** on the Storage Account resource (or its resource group) to create role assignments.

## Inputs

| Name | Type | Description |
|---|---|---|
| `storage_account_id` | `string` | Full resource ID of the Azure Storage Account |
| `container_app_principal_ids` | `map(string)` | Map of service name → system-assigned MI principal ID |
| `environment` | `string` | `dev`, `staging`, or `prod` |

## Outputs

| Name | Description |
|---|---|
| `role_assignment_ids` | Map of service name → role assignment resource ID |
| `role_assignment_principal_ids` | Map of service name → confirmed principal ID (audit) |

## Usage

```hcl
module "blob_storage_rbac" {
  source = "../../modules/blob-storage-rbac"

  storage_account_id = azurerm_storage_account.cfp_compass.id
  environment        = "dev"

  container_app_principal_ids = {
    api     = azurerm_container_app.api.identity[0].principal_id
    web     = azurerm_container_app.web.identity[0].principal_id
    workers = azurerm_container_app.workers.identity[0].principal_id
  }
}
```

## Access pattern

All blob operations in application code must use `DefaultAzureCredential`:

```csharp
// Aspire integration wires this automatically in dev:
builder.AddAzureBlobClient("blob-storage");

// In production, DefaultAzureCredential resolves the Container App's
// system-assigned managed identity — no connection string or SAS token needed.
```

SAS token generation and `Storage-ConnectionString` Key Vault secrets should be removed once all environments are migrated to this RBAC pattern.
