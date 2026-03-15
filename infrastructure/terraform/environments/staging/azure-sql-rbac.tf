# infrastructure/terraform/environments/staging/azure-sql-rbac.tf
#
# Caller: wires the azure-sql-rbac module for the staging environment.
# Follow the same pattern as environments/dev/azure-sql-rbac.tf.
#
# TODO: Uncomment and configure when the staging environment is provisioned.
# Prerequisites:
#   - Container Apps must have system-assigned managed identities enabled
#   - Azure SQL Server must have Entra authentication enabled
#   - Terraform runner must have db_owner or Entra admin rights on the SQL server
#
# Related: GitHub Issue #2 — MI Gap: Azure SQL Web + API Container Apps

# ---------------------------------------------------------------------------
# Placeholder — staging environment not yet provisioned
# ---------------------------------------------------------------------------
#
# data "azurerm_mssql_server" "cfp_compass_staging" {
#   name                = "sql-cfpcompass-staging"
#   resource_group_name = "rg-cfp-compass-staging"
# }
#
# data "azurerm_container_app" "api_sql_staging" {
#   name                = "ca-cfp-compass-api-staging"
#   resource_group_name = "rg-cfp-compass-staging"
# }
#
# data "azurerm_container_app" "web_sql_staging" {
#   name                = "ca-cfp-compass-web-staging"
#   resource_group_name = "rg-cfp-compass-staging"
# }
#
# module "azure_sql_rbac_staging" {
#   source = "../../modules/azure-sql-rbac"
#
#   sql_server_fqdn = data.azurerm_mssql_server.cfp_compass_staging.fully_qualified_domain_name
#   database_name   = "sqldb-cfpcompass-staging"
#   environment     = "staging"
#
#   principal_display_names = {
#     api = data.azurerm_container_app.api_sql_staging.name
#     web = data.azurerm_container_app.web_sql_staging.name
#   }
# }
#
# output "sql_rbac_granted_principals_staging" {
#   description = "Map of service name to Entra display name confirmed with db_datareader/db_datawriter in staging."
#   value       = module.azure_sql_rbac_staging.granted_principals
# }
