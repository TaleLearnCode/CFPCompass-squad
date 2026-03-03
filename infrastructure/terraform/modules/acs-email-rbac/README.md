# acs-email-rbac

Assigns the **ACS Email Sender** RBAC role to the system-assigned managed identity of each CFP Compass Container App that sends email through Azure Communication Services. This eliminates ACS connection string usage in favour of `DefaultAzureCredential`-based access.

## Why this module exists

ACS Email was previously accessed via a connection string stored in Key Vault (tracked in [GitHub Issue #3](https://github.com/TaleLearnCode/CFPCompass-squad/issues/3)). Connection strings:

- Must be rotated and re-deployed when regenerated
- Carry shared-credential leak risk if exposed in logs or config
- Are inconsistent with the Managed Identity pattern used for Key Vault, Blob Storage, and Service Bus

This module replaces connection string access with Azure RBAC using system-assigned managed identities — the same credential model used across all other CFP Compass service connections.

## Services requiring ACS Email Sender access

| Container App | Email operations |
|---|---|
| `CfpCompass.Api` | Submission confirmation, claim verification, single-use JWT emails |
| `CfpCompass.Workers` | Deadline reminders, weekly digest |

Both receive `ACS Email Sender` (role ID `b9d4cd7b-d855-4f0c-b635-164d572a3f89`) since both originate outbound email flows.

## Required Azure permissions for the Terraform principal

The service principal running Terraform must have **Owner** or **User Access Administrator** on the ACS resource (or its resource group) to create role assignments.

## Inputs

| Name | Type | Description |
|---|---|---|
| `acs_resource_id` | `string` | Full resource ID of the Azure Communication Services resource |
| `container_app_principal_ids` | `map(string)` | Map of service name → system-assigned MI principal ID |
| `environment` | `string` | `dev`, `staging`, or `prod` |

## Outputs

| Name | Description |
|---|---|
| `role_assignment_ids` | Map of service name → role assignment resource ID |
| `role_assignment_principal_ids` | Map of service name → confirmed principal ID (audit) |

## Usage

```hcl
module "acs_email_rbac" {
  source = "../../modules/acs-email-rbac"

  acs_resource_id = azurerm_communication_service.cfp_compass.id
  environment     = "dev"

  container_app_principal_ids = {
    api     = azurerm_container_app.api.identity[0].principal_id
    workers = azurerm_container_app.workers.identity[0].principal_id
  }
}
```

## Access pattern

All email operations in application code use `DefaultAzureCredential` with the ACS endpoint URI (not a connection string):

```csharp
// AcsEmailExtensions.cs wires this in all environments:
var endpoint = new Uri(builder.Configuration.GetConnectionString("acs")!);
builder.Services.AddSingleton(new EmailClient(endpoint, new DefaultAzureCredential()));

// In production, DefaultAzureCredential resolves the Container App's
// system-assigned managed identity — no connection string or Key Vault secret needed.
```

The `ACS-ConnectionString` Key Vault secret should be removed once all environments are migrated to this RBAC pattern. The only ACS-related configuration remaining is `ConnectionStrings:acs` (the endpoint URI, which is non-sensitive and safe to store in app config).
