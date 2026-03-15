# infrastructure/terraform/environments/dev/azure-sql-rbac.tf
#
# Caller: wires the azure-sql-rbac module for the dev environment.
# Grants db_datareader + db_datawriter SQL roles to the Web and API Container App
# managed identities, replacing the AzureSql-ConnectionString Key Vault secret
# with Entra Managed Identity authentication for all SQL-connected services.
#
# Prerequisite: Each Container App must have a system-assigned managed identity
# enabled (`identity { type = "SystemAssigned" }` in its resource block).
# Prerequisite: Azure SQL Server must have Entra authentication enabled and
# the Terraform runner identity must be the Entra admin (or have db_owner).
# Prerequisite: sqlcmd must be available on the Terraform runner — see the
# azure-sql-rbac module README for the GitHub Actions installation snippet.
#
# Related: GitHub Issue #2 — MI Gap: Azure SQL Web + API Container Apps

# ---------------------------------------------------------------------------
# Data sources — reference existing resources provisioned by other modules
# ---------------------------------------------------------------------------

data "azurerm_mssql_server" "cfp_compass_dev" {
  name                = "sql-cfpcompass-dev"
  resource_group_name = "rg-cfp-compass-dev"
}

data "azurerm_container_app" "api_sql_dev" {
  name                = "ca-cfp-compass-api-dev"
  resource_group_name = "rg-cfp-compass-dev"
}

data "azurerm_container_app" "web_sql_dev" {
  name                = "ca-cfp-compass-web-dev"
  resource_group_name = "rg-cfp-compass-dev"
}

# ---------------------------------------------------------------------------
# Module call
# ---------------------------------------------------------------------------

module "azure_sql_rbac_dev" {
  source = "../../modules/azure-sql-rbac"

  sql_server_fqdn = data.azurerm_mssql_server.cfp_compass_dev.fully_qualified_domain_name
  database_name   = "sqldb-cfpcompass-dev"
  environment     = "dev"

  # The display name of each Container App's system-assigned managed identity
  # matches the Container App resource name by default in Azure.
  principal_display_names = {
    api = data.azurerm_container_app.api_sql_dev.name
    web = data.azurerm_container_app.web_sql_dev.name
  }
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------

output "sql_rbac_granted_principals_dev" {
  description = "Map of service name to Entra display name confirmed with db_datareader/db_datawriter in dev — for audit and reference."
  value       = module.azure_sql_rbac_dev.granted_principals
}
