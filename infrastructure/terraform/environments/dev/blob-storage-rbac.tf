# infrastructure/terraform/environments/dev/blob-storage-rbac.tf
#
# Caller: wires the blob-storage-rbac module for the dev environment.
# The storage account and Container App resources are declared in their
# respective modules (storage/ and container-apps/) and referenced here
# via data sources or module outputs.
#
# Prerequisite: Each Container App must have a system-assigned managed
# identity enabled (`identity { type = "SystemAssigned" }` in its resource block).

# ---------------------------------------------------------------------------
# Data sources — reference existing resources provisioned by other modules
# ---------------------------------------------------------------------------

data "azurerm_storage_account" "cfp_compass_dev" {
  name                = "stcfpcompassdev"      # adjust to match your naming convention
  resource_group_name = "rg-cfp-compass-dev"
}

data "azurerm_container_app" "api_dev" {
  name                = "ca-cfp-compass-api-dev"
  resource_group_name = "rg-cfp-compass-dev"
}

data "azurerm_container_app" "web_dev" {
  name                = "ca-cfp-compass-web-dev"
  resource_group_name = "rg-cfp-compass-dev"
}

data "azurerm_container_app" "workers_dev" {
  name                = "ca-cfp-compass-workers-dev"
  resource_group_name = "rg-cfp-compass-dev"
}

# ---------------------------------------------------------------------------
# Module call
# ---------------------------------------------------------------------------

module "blob_storage_rbac_dev" {
  source = "../../modules/blob-storage-rbac"

  storage_account_id = data.azurerm_storage_account.cfp_compass_dev.id
  environment        = "dev"

  container_app_principal_ids = {
    api     = data.azurerm_container_app.api_dev.identity[0].principal_id
    web     = data.azurerm_container_app.web_dev.identity[0].principal_id
    workers = data.azurerm_container_app.workers_dev.identity[0].principal_id
  }
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "blob_rbac_role_assignment_ids_dev" {
  description = "Role assignment IDs for Blob Storage RBAC in dev — for audit and reference."
  value       = module.blob_storage_rbac_dev.role_assignment_ids
}
