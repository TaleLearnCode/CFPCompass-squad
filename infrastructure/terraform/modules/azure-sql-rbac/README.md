# azure-sql-rbac

Grants **`db_datareader`** and **`db_datawriter`** SQL database roles to the system-assigned managed identity of each CFP Compass Container App that requires Azure SQL access. This removes the `AzureSql-ConnectionString` Key Vault secret dependency from the Web and API services, making all four services (Web, API, Jobs, Functions) consistent in their SQL authentication model.

## Why this module exists

The previous design used `AzureSql-ConnectionString` stored in Key Vault to give Web and API Container Apps database access — i.e., SQL Server password-based authentication. Container Apps Jobs and Azure Functions already used Entra Managed Identity for SQL access (tracked in [GitHub Issue #2](https://github.com/TaleLearnCode/CFPCompass-squad/issues/2)).

This module closes the gap:

- **Eliminates credential secrets** — no connection string in Key Vault for Web/API
- **Consistent MI auth** — all four services authenticate to Azure SQL via `DefaultAzureCredential`
- **Principle of least privilege** — `db_datareader` + `db_datawriter` only; no `db_owner`

## Services receiving SQL access

| Container App | SQL Roles Granted | Reason |
|---|---|---|
| `CfpCompass.Api` | `db_datareader`, `db_datawriter` | Reads CFP listings; writes on behalf of Functions (read-after-write status checks) |
| `CfpCompass.Web` | `db_datareader`, `db_datawriter` | Reads CFP data for display; writes user preferences and tracking |

> Jobs and Functions already have SQL access granted separately outside this module.

## EF Core connection string format

After this module runs, the EF Core connection string must use `Authentication=Active Directory Managed Identity` and **must not** include `User ID` or `Password`:

```json
{
  "ConnectionStrings": {
    "SqlDatabase": "Server=<server>.database.windows.net;Database=<database>;Authentication=Active Directory Managed Identity;"
  }
}
```

In local development, .NET Aspire injects the SQL connection automatically via the `AddAzureSqlServer()` resource model — no manual connection string required.

## Required Azure permissions for the Terraform principal

The service principal running Terraform must be set as the **Azure SQL Entra admin** (or have `db_owner` in the target database) to create contained database users via T-SQL.

Additionally, `sqlcmd` must be installed on the Terraform runner. GitHub-hosted runners (`ubuntu-latest`) do not include `sqlcmd` by default — install it in the workflow:

```yaml
- name: Install sqlcmd
  run: |
    curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
    curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
    sudo apt-get update && sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev
    echo "/opt/mssql-tools18/bin" >> $GITHUB_PATH
```

## Inputs

| Name | Type | Description |
|---|---|---|
| `sql_server_fqdn` | `string` | FQDN of the Azure SQL Server (e.g. `sql-cfpcompass-dev.database.windows.net`) |
| `database_name` | `string` | Name of the target Azure SQL Database |
| `principal_display_names` | `map(string)` | Map of service name → Entra display name of the system-assigned MI (matches the Container App resource name) |
| `environment` | `string` | `dev`, `staging`, or `prod` |

## Outputs

| Name | Description |
|---|---|
| `granted_principals` | Map of service name → confirmed Entra display name granted SQL roles (audit) |
| `sql_server_fqdn` | FQDN of the SQL Server where roles were granted |
| `database_name` | Name of the Azure SQL Database where roles were granted |

## Usage

```hcl
module "azure_sql_rbac" {
  source = "../../modules/azure-sql-rbac"

  sql_server_fqdn = "sql-cfpcompass-dev.database.windows.net"
  database_name   = "sqldb-cfpcompass-dev"
  environment     = "dev"

  principal_display_names = {
    api = "ca-cfp-compass-api-dev"
    web = "ca-cfp-compass-web-dev"
  }
}
```

## Key Vault cleanup

Once all environments are confirmed using MI auth, remove `AzureSql-ConnectionString` from:

1. `infra/modules/keyvault/main.tf` — delete the `azurerm_key_vault_secret` resource for `AzureSql-ConnectionString`
2. Container App environment variable configuration — remove the Key Vault reference `@Microsoft.KeyVault(SecretUri=...AzureSql-ConnectionString...)`
3. `docs/infrastructure/overview.md` — remove from the Key Vault secret inventory table
