# infrastructure/terraform/environments/prod/azure-sql-rbac.tf
#
# Caller: wires the azure-sql-rbac module for the prod environment.
# Follow the same pattern as environments/dev/azure-sql-rbac.tf.
#
# TODO: Uncomment and configure when the prod environment is provisioned.
# Prerequisites:
#   - Container Apps must have system-assigned managed identities enabled
#   - Azure SQL Server must have Entra authentication enabled
#   - Terraform runner must have db_owner or Entra admin rights on the SQL server
#
# Related: GitHub Issue #2 — MI Gap: Azure SQL Web + API Container Apps

# ---------------------------------------------------------------------------
# Placeholder — prod environment not yet provisioned
# ---------------------------------------------------------------------------
#
# data "azurerm_mssql_server" "cfp_compass_prod" {
#   name                = "sql-cfpcompass-prod"
#   resource_group_name = "rg-cfp-compass-prod"
# }
#
# data "azurerm_container_app" "api_sql_prod" {
#   name                = "ca-cfp-compass-api-prod"
#   resource_group_name = "rg-cfp-compass-prod"
# }
#
# data "azurerm_container_app" "web_sql_prod" {
#   name                = "ca-cfp-compass-web-prod"
#   resource_group_name = "rg-cfp-compass-prod"
# }
#
# module "azure_sql_rbac_prod" {
#   source = "../../modules/azure-sql-rbac"
#
#   sql_server_fqdn = data.azurerm_mssql_server.cfp_compass_prod.fully_qualified_domain_name
#   database_name   = "sqldb-cfpcompass-prod"
#   environment     = "prod"
#
#   principal_display_names = {
#     api = data.azurerm_container_app.api_sql_prod.name
#     web = data.azurerm_container_app.web_sql_prod.name
#   }
# }
#
# output "sql_rbac_granted_principals_prod" {
#   description = "Map of service name to Entra display name confirmed with db_datareader/db_datawriter in prod."
#   value       = module.azure_sql_rbac_prod.granted_principals
# }
