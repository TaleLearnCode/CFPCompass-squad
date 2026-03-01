# Parker — Issue #1: Blob Storage Managed Identity RBAC

**Date:** 2026-03-01
**Branch:** `squad/1-blob-storage-managed-identity`
**Issue:** https://github.com/TaleLearnCode/CFPCompass-squad/issues/1
**Status:** Parker's scope complete — pushed and ready for PR

---

## What was done

Created the `blob-storage-rbac` Terraform module and wired it for the dev environment. This is the infrastructure half of Issue #1.

### Files added / changed

| File | Change |
|---|---|
| `infrastructure/terraform/modules/blob-storage-rbac/main.tf` | `azurerm_role_assignment` loop — Storage Blob Data Contributor for each Container App MI |
| `infrastructure/terraform/modules/blob-storage-rbac/variables.tf` | Inputs: `storage_account_id`, `container_app_principal_ids` (map), `environment` |
| `infrastructure/terraform/modules/blob-storage-rbac/outputs.tf` | Outputs: role assignment IDs + principal IDs for audit |
| `infrastructure/terraform/modules/blob-storage-rbac/README.md` | Usage docs, required permissions, code example |
| `infrastructure/terraform/environments/dev/blob-storage-rbac.tf` | Dev caller — wires data sources + calls module |
| `docs/infrastructure/architecture.md` | Updated MI wiring table; added SAS → RBAC migration note; updated module layout |

---

## Decision rationale

- **All three Container Apps** (`Api`, `Web`, `Workers`) receive `Storage Blob Data Contributor` rather than scoping to read-only for Web/Api. This is forward-compatible and avoids a second Terraform change if write requirements emerge.
- **Deterministic role assignment names** via `uuidv5` prevent drift between `terraform plan` runs.
- **No staging/prod callers yet** — following dev-first pattern. Staging and prod callers should be added when those environments are provisioned.

---

## Handoff to Ripley

Parker's Terraform work is a prerequisite for Ripley's application changes:

1. Add `Aspire.Azure.Storage.Blobs` NuGet package to `CfpCompass.Api`, `CfpCompass.Web`, `CfpCompass.Workers`
2. Wire `builder.AddAzureBlobClient("blob-storage")` in each host
3. Replace SAS token generation with `DefaultAzureCredential`-backed `BlobServiceClient`
4. Remove `Storage-ConnectionString` from Key Vault once all environments are confirmed

Issue #1 acceptance criteria are split across Parker (Terraform ✅) and Ripley (SDK/code ⚠️ pending).
