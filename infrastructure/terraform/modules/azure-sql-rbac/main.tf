# azure-sql-rbac/main.tf
#
# Grants db_datareader and db_datawriter SQL database roles to the system-assigned
# managed identity of each Container App that requires Azure SQL access.
#
# Azure SQL data-plane roles (db_datareader, db_datawriter) are SQL-level grants —
# they cannot be assigned via Azure RBAC (azurerm_role_assignment). Instead, a
# contained database user is created FROM EXTERNAL PROVIDER (Entra MI), then added
# to the relevant roles.
#
# Mechanism: null_resource + local-exec runs T-SQL via sqlcmd with Active Directory
# Default authentication. The Terraform runner (GitHub Actions service principal or
# local dev identity) must have at minimum db_owner or SQL Server Entra admin rights.
#
# Related: GitHub Issue #2 — MI Gap: Azure SQL Web + API Container Apps

terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}

resource "null_resource" "sql_role_grant" {
  for_each = var.principal_display_names

  # Re-run if the principal name, server, database, or environment changes.
  triggers = {
    principal_display_name = each.value
    sql_server_fqdn        = var.sql_server_fqdn
    database_name          = var.database_name
    environment            = var.environment
  }

  provisioner "local-exec" {
    # sqlcmd uses the runner's Azure AD identity (DefaultAzureCredential via --authentication-method=ActiveDirectoryDefault).
    # The IF-NOT-EXISTS guards make this idempotent across repeated applies.
    # Input validation rejects control characters; single quotes and brackets are escaped before
    # interpolation into the T-SQL query to prevent injection via principal display names.
    command = <<-SHELL
      set -euo pipefail

      principal_raw="${each.value}"

      # Reject control characters that could corrupt the SQL batch
      if printf '%s' "$principal_raw" | LC_ALL=C grep -qP '[[:cntrl:]]'; then
        echo "Invalid principal display name (contains control characters): $principal_raw" >&2
        exit 1
      fi

      # Escape for T-SQL string literal: ' -> ''
      principal_literal="$${principal_raw//\'/\'\'}"

      # Escape for bracket-delimited identifier: ] -> ]]
      principal_identifier="$${principal_raw//]/]]}"

      sql_query=$(cat <<-SQL
        IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'$${principal_literal}')
          BEGIN CREATE USER [$${principal_identifier}] FROM EXTERNAL PROVIDER END;
        IF IS_ROLEMEMBER('db_datareader', '$${principal_literal}') = 0
          BEGIN ALTER ROLE db_datareader ADD MEMBER [$${principal_identifier}] END;
        IF IS_ROLEMEMBER('db_datawriter', '$${principal_literal}') = 0
          BEGIN ALTER ROLE db_datawriter ADD MEMBER [$${principal_identifier}] END;
SQL
      )

      sqlcmd \
        -S "${var.sql_server_fqdn}" \
        -d "${var.database_name}" \
        --authentication-method=ActiveDirectoryDefault \
        -Q "$${sql_query}"
    SHELL
    interpreter = ["/bin/bash", "-c"]
  }
}
