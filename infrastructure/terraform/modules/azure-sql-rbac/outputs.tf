# azure-sql-rbac/outputs.tf

output "granted_principals" {
  description = "Map of service name to Entra display name confirmed as a contained database user with db_datareader and db_datawriter roles — for audit and reference."
  value       = { for k, v in null_resource.sql_role_grant : k => v.triggers["principal_display_name"] }
}

output "sql_server_fqdn" {
  description = "FQDN of the SQL Server against which roles were granted."
  value       = var.sql_server_fqdn
}

output "database_name" {
  description = "Name of the Azure SQL Database where roles were granted."
  value       = var.database_name
}
