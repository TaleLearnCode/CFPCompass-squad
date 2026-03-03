---
title: Azure SQL — Managed Identity for Web + API (Issue #2)
author: Parker (DevOps)
date: 2026-03-02
issue: "#2"
---

# Decision: Azure SQL MI Role Grants via null_resource + sqlcmd

## Context

Issue #2 identified that the Web and API Container Apps used `AzureSql-ConnectionString` in Key Vault for SQL access, while Jobs and Functions already used Entra Managed Identity. The fix requires:

1. Granting `db_datareader` + `db_datawriter` SQL database roles to the Web and API managed identities
2. Switching EF Core connection string to `Authentication=Active Directory Managed Identity`
3. Removing `AzureSql-ConnectionString` from Key Vault

## Key Decision: null_resource + sqlcmd (not azurerm_role_assignment)

SQL data-plane roles (`db_datareader`, `db_datawriter`) are **SQL-level grants**, not Azure RBAC. They cannot be assigned via `azurerm_role_assignment` (which targets management-plane Azure RBAC, not SQL row-level security). The correct Terraform mechanism is:

```hcl
resource "null_resource" "sql_role_grant" {
  for_each = var.principal_display_names
  provisioner "local-exec" {
    command = "sqlcmd -S ... --authentication-method=ActiveDirectoryDefault -Q 'CREATE USER ... FROM EXTERNAL PROVIDER; ...'"
  }
}
```

This differs from the `blob-storage-rbac` module pattern, which uses `azurerm_role_assignment` because Blob Storage access is governed by Azure RBAC.

## Implications for Other Agents

- **Ripley:** EF Core must register the SQL provider without connection string credentials. Use `Authentication=Active Directory Managed Identity` in the connection string. The `Aspire.Azure.Data.Sql` integration package handles `DefaultAzureCredential` automatically in local dev via the `AddAzureSqlServer()` resource model.
- **CI/CD (Parker):** GitHub Actions workflows for Terraform must install `sqlcmd` before `terraform apply` (see `azure-sql-rbac` module README for the install snippet).
- **Keyvault module:** `AzureSql-ConnectionString` secret resource in `infra/modules/keyvault/main.tf` should be deleted once all environments confirm MI auth — not done yet as no keyvault module file exists.

## Connection String Format (Decided)

```json
{
  "ConnectionStrings": {
    "SqlDatabase": "Server=<server>.database.windows.net;Database=<database>;Authentication=Active Directory Managed Identity;"
  }
}
```

No `User ID`, no `Password`, no `Encrypt` override needed (TLS enforced by default on Azure SQL).

## Environment Coverage

Dev caller (`environments/dev/azure-sql-rbac.tf`) created. Staging and prod callers should follow the same pattern when those environments are provisioned. No environment-specific variable changes are needed — the module is parameterized by FQDN, database name, and principal display names.
