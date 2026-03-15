# Skill: Azure SQL Managed Identity RBAC

**Confidence:** High (implemented and committed for Issue #2)

**When:** Granting a managed identity access to an Azure SQL Database for data operations.

## Key Insight: SQL roles ≠ Azure RBAC

Azure SQL data-plane roles (`db_datareader`, `db_datawriter`, etc.) are **SQL-level grants** — they live inside the database engine, not in the Azure control plane. This means:

- **`azurerm_role_assignment` does NOT work** for SQL data access (it targets Azure management-plane RBAC only)
- You must run T-SQL inside the database: `CREATE USER [...] FROM EXTERNAL PROVIDER; ALTER ROLE db_datareader ADD MEMBER [...]`

This is different from Blob Storage RBAC (Issue #1), which uses `azurerm_role_assignment` because Azure Storage access IS governed by Azure RBAC.

## Terraform Pattern (null_resource + sqlcmd)

```hcl
resource "null_resource" "sql_role_grant" {
  for_each = var.principal_display_names

  triggers = {
    principal_display_name = each.value
    sql_server_fqdn        = var.sql_server_fqdn
    database_name          = var.database_name
    environment            = var.environment
  }

  provisioner "local-exec" {
    command = <<-SHELL
      sqlcmd \
        -S "${var.sql_server_fqdn}" \
        -d "${var.database_name}" \
        --authentication-method=ActiveDirectoryDefault \
        -Q "IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'${each.value}')
              BEGIN CREATE USER [${each.value}] FROM EXTERNAL PROVIDER END;
            IF IS_ROLEMEMBER('db_datareader', '${each.value}') = 0
              BEGIN ALTER ROLE db_datareader ADD MEMBER [${each.value}] END;
            IF IS_ROLEMEMBER('db_datawriter', '${each.value}') = 0
              BEGIN ALTER ROLE db_datawriter ADD MEMBER [${each.value}] END;"
    SHELL
    interpreter = ["/bin/bash", "-c"]
  }
}
```

**Idempotency guards:** The `IF NOT EXISTS` / `IF IS_ROLEMEMBER` checks make this safe to re-run on every `terraform apply`.

## Prerequisites

1. Azure SQL Server must have **Entra authentication enabled** (`azurerm_mssql_server` with `azuread_administrator` block).
2. The Terraform runner identity must be the SQL Entra admin or have `db_owner` in the target database.
3. `sqlcmd` must be available on the runner. GitHub Actions install snippet:

```yaml
- name: Install sqlcmd
  run: |
    curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
    curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
    sudo apt-get update && sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev
    echo "/opt/mssql-tools18/bin" >> $GITHUB_PATH
```

## Principal Display Name

The managed identity **display name** (not the object ID / principal ID) is used as the contained database user name. For system-assigned identities on Container Apps, the display name matches the Container App resource name (e.g., `ca-cfp-compass-api-dev`).

## EF Core Connection String

```json
{
  "ConnectionStrings": {
    "SqlDatabase": "Server=<server>.database.windows.net;Database=<db>;Authentication=Active Directory Managed Identity;"
  }
}
```

No `User ID` or `Password`. In local dev, .NET Aspire injects the connection via `AddAzureSqlServer()` — this appsettings value is overridden automatically.

## Module Location in CFP Compass

`infrastructure/terraform/modules/azure-sql-rbac/` — first created for Issue #2.

## Source

Learned and implemented for [GitHub Issue #2](https://github.com/TaleLearnCode/CFPCompass-squad/issues/2) (2026-03-02).
