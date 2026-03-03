# blob-storage-rbac/main.tf
#
# Assigns the Storage Blob Data Contributor RBAC role to each Container App's
# system-assigned managed identity for the given Storage Account. All blob access
# flows through DefaultAzureCredential — no SAS tokens are used.
#
# Related: GitHub Issue #1 — MI Gap: Replace SAS tokens with Managed Identity RBAC

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
  }
}

# Storage Blob Data Contributor role definition ID (built-in, immutable)
locals {
  storage_blob_data_contributor_role_id = "ba92f5b4-2d11-453d-a403-e96b0029c9fe"
}

resource "azurerm_role_assignment" "blob_data_contributor" {
  for_each = var.container_app_principal_ids

  name                 = uuidv5("url", "blob-rbac-${var.environment}-${each.key}-${var.storage_account_id}")
  scope                = var.storage_account_id
  role_definition_id   = "/providers/Microsoft.Authorization/roleDefinitions/${local.storage_blob_data_contributor_role_id}"
  principal_id         = each.value
  principal_type       = "ServicePrincipal"

  description = "Storage Blob Data Contributor for CFP Compass ${each.key} (${var.environment}) — assigned via managed identity, no SAS tokens"
}
