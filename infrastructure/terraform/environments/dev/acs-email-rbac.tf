# infrastructure/terraform/environments/dev/acs-email-rbac.tf
#
# Caller: wires the acs-email-rbac module for the dev environment.
# The ACS resource and Container App resources are declared in their respective
# modules (acs/ and container-apps/) and referenced here via data sources.
#
# Prerequisite: Each Container App must have a system-assigned managed identity
# enabled (`identity { type = "SystemAssigned" }` in its resource block).
#
# Note: ACS-ConnectionString Key Vault secret should be removed once this RBAC
# assignment is confirmed working in all environments (Issue #3 cleanup step).

# ---------------------------------------------------------------------------
# Data sources — reference existing resources provisioned by other modules
# ---------------------------------------------------------------------------

data "azurerm_communication_service" "cfp_compass_dev" {
  name                = "acs-cfp-compass-dev"   # adjust to match your naming convention
  resource_group_name = "rg-cfp-compass-dev"
}

data "azurerm_container_app" "api_dev_acs" {
  name                = "ca-cfp-compass-api-dev"
  resource_group_name = "rg-cfp-compass-dev"
}

data "azurerm_container_app" "workers_dev_acs" {
  name                = "ca-cfp-compass-workers-dev"
  resource_group_name = "rg-cfp-compass-dev"
}

# ---------------------------------------------------------------------------
# Module call
# ---------------------------------------------------------------------------

module "acs_email_rbac_dev" {
  source = "../../modules/acs-email-rbac"

  acs_resource_id = data.azurerm_communication_service.cfp_compass_dev.id
  environment     = "dev"

  container_app_principal_ids = {
    api     = data.azurerm_container_app.api_dev_acs.identity[0].principal_id
    workers = data.azurerm_container_app.workers_dev_acs.identity[0].principal_id
  }
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "acs_email_rbac_role_assignment_ids_dev" {
  description = "Role assignment IDs for ACS Email Sender RBAC in dev — for audit and reference."
  value       = module.acs_email_rbac_dev.role_assignment_ids
}
