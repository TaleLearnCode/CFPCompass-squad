# azure-sql-rbac/variables.tf

variable "sql_server_fqdn" {
  description = "Fully-qualified domain name of the Azure SQL Server (e.g. sql-cfpcompass-dev.database.windows.net)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+\\.database\\.windows\\.net$", var.sql_server_fqdn))
    error_message = "sql_server_fqdn must end with .database.windows.net."
  }
}

variable "database_name" {
  description = "Name of the Azure SQL Database to which roles are granted."
  type        = string

  validation {
    condition     = length(var.database_name) > 0
    error_message = "database_name must not be empty."
  }
}

variable "principal_display_names" {
  description = "Map of service name to the Entra display name of the system-assigned managed identity. The display name is used as the contained-database user name in SQL. Typically matches the Container App resource name (e.g. 'ca-cfp-compass-api-dev')."
  type        = map(string)

  validation {
    condition     = length(var.principal_display_names) > 0
    error_message = "At least one principal display name must be provided."
  }
}

variable "environment" {
  description = "Deployment environment. Used in null_resource trigger keys to scope role grants."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}
