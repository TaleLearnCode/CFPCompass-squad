# acs-email-rbac/main.tf
#
# Assigns the ACS Email Sender RBAC role to each Container App's system-assigned
# managed identity for the given ACS resource. All email sending flows through
# DefaultAzureCredential — no connection strings are used.
#
# Related: GitHub Issue #3 — MI Gap: ACS Email — Use Managed Identity

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.100.0"
    }
  }
}

# ACS Email Sender role definition ID (built-in, immutable)
locals {
  acs_email_sender_role_id = "b9d4cd7b-d855-4f0c-b635-164d572a3f89"
}

resource "azurerm_role_assignment" "acs_email_sender" {
  for_each = var.container_app_principal_ids

  name                 = uuidv5("url", "acs-email-rbac-${var.environment}-${each.key}-${var.acs_resource_id}")
  scope                = var.acs_resource_id
  role_definition_id   = "/providers/Microsoft.Authorization/roleDefinitions/${local.acs_email_sender_role_id}"
  principal_id         = each.value
  principal_type       = "ServicePrincipal"

  description = "ACS Email Sender for CFP Compass ${each.key} (${var.environment}) — assigned via managed identity, no connection string"
}
