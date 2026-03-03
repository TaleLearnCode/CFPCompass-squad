---
id: infrastructure-architecture
title: Infrastructure Architecture
description: Terraform module structure, CI/CD pipeline, container image strategy, and managed identity configuration for CFP Compass.
tags:
  - infrastructure
  - architecture
  - terraform
  - ci-cd
  - containers
  - azure
---

# Infrastructure Architecture

## Overview

CFP Compass infrastructure is defined entirely as code using **Terraform** (azurerm + azapi providers). All Azure resources — from the Container Apps Environment to APIM policies — are provisioned and updated via Terraform modules. GitHub Actions drives CI/CD, building Docker images and deploying to Azure Container Apps on each environment's release trigger.

This document covers the Terraform module structure, environment layout, CI/CD pipeline, container image strategy, and managed identity wiring.

---

## Scope

This document covers:

- Terraform module hierarchy and file layout
- Per-environment variable strategy
- GitHub Actions CI/CD workflow structure
- Container image naming, tagging, and ACR integration
- Managed Identity configuration for Container Apps, Functions, and Jobs
- APIM VNet integration and backend policy wiring

This document does **not** cover application-level architecture (see `architecture.md` in `.squad/`) or operational runbooks.

---

## Architecture Diagram

```
GitHub Repository
    │
    ├── .github/workflows/
    │       ├── ci.yml          ─── Build + test + lint (all PRs and main)
    │       ├── cd-dev.yml      ─── Deploy to dev (auto, on merge to main)
    │       ├── cd-staging.yml  ─── Deploy to staging (manual trigger or tag)
    │       └── cd-prod.yml     ─── Deploy to prod (manual approval gate)
    │
    └── infra/
            ├── main.tf, variables.tf, outputs.tf, backend.tf, providers.tf
            └── modules/ (see Logical Components)

                    │  Terraform Apply
                    ▼
        ┌───────────────────────────────────────┐
        │         Azure Resource Group          │
        │  (rg-cfpcompass-{dev|staging|prod})   │
        │                                       │
        │  Container Apps Environment           │
        │    ├── Container App: Web (Blazor)    │
        │    ├── Container App: API (ASP.NET)   │
        │    └── Jobs: Workers                  │
        │                                       │
        │  Azure SQL DB (Serverless)            │
        │  Azure Managed Redis (C0)             │
        │  Azure Service Bus (Standard)         │
        │  Azure Functions (Consumption)        │
        │  Azure API Management (Developer)     │
        │  Azure Front Door (Standard)          │
        │  Azure Communication Services         │
        │  Azure Key Vault (Standard)           │
        │  Azure Storage Account (GPv2)         │
        │  Azure Log Analytics + App Insights   │
        │  User-Assigned Managed Identities     │
        └───────────────────────────────────────┘
```

---

## Logical Components

### Terraform Module Structure

```
infra/
├── main.tf                    # Root module — calls all child modules in order
├── variables.tf               # Input variables: environment, region, SKUs, tags
├── outputs.tf                 # Outputs: URLs, resource IDs, connection strings (non-secret)
├── backend.tf                 # Remote state: Azure Storage Account + Blob lease locking
├── providers.tf               # azurerm (~> 4.x) + azapi providers; feature flags
│
├── modules/
│   ├── resource-group/        # Resource group with standard tags
│   ├── container-apps/        # Container Apps Environment + Web App + API App + Jobs
│   │                          # Configures ingress, scaling rules, managed identity refs,
│   │                          # container image tags, and env var injection (from Key Vault refs)
│   ├── sql/                   # Azure SQL Server + Database (Serverless, GP S0)
│   │                          # Configures firewall rules, elastic pool (if needed), TDE
│   ├── storage/               # Storage Account (GPv2 LRS) + Blob containers
│   ├── redis/                 # Azure Managed Redis (C0) + access key output to Key Vault
│   ├── service-bus/           # Service Bus Namespace (Standard) + Topics + Subscriptions
│   │                          # Topics: cfp-submission-created, cfp-submission-updated,
│   │                          #         cfp-submission-approved, cfp-submission-rejected,
│   │                          #         cfp-submission-reconsideration, organizer-claim-requested
│   ├── functions/             # Azure Functions Consumption plan + Function App
│   │                          # Configures Service Bus trigger bindings, managed identity
│   ├── apim/                  # API Management (Developer SKU) + Products + Policies
│   │                          # Imports OpenAPI spec; configures rate-limit and cache policies
│   ├── keyvault/              # Key Vault (Standard) + Access Policies for managed identities
│   ├── acr/                   # Container Registry (Basic) + admin credentials output
│   ├── acs/                   # Azure Communication Services + Email domain verification
│   ├── frontdoor/             # Front Door (Standard) + Origins + Routes + WAF policy
│   ├── identity/              # User-assigned managed identities for Container Apps + Functions
│   ├── blob-storage-rbac/     # Storage Blob Data Contributor RBAC for Container App MIs (Issue #1)
│   ├── azure-sql-rbac/        # db_datareader/db_datawriter SQL role grants for Web + API MIs (Issue #2)
│   └── monitoring/            # Log Analytics Workspace + Application Insights
│
└── environments/
    ├── dev/
    │   ├── main.tf              # Dev module instantiation with dev-specific overrides
    │   ├── terraform.tfvars     # Dev variable values (SKU overrides, region, tags)
    │   └── blob-storage-rbac.tf # Blob Storage RBAC caller for dev environment (Issue #1)
│   └── azure-sql-rbac.tf    # Azure SQL MI role grants caller for dev environment (Issue #2)
    ├── staging/
    │   ├── main.tf
    │   └── terraform.tfvars
    └── prod/
        ├── main.tf
        └── terraform.tfvars
```

**State management:** Remote state is stored in `stcfpcompasstfstate` Storage Account (`rg-cfpcompass-shared`). Each environment has a separate state file (`dev.tfstate`, `staging.tfstate`, `prod.tfstate`). State locking uses Azure Blob lease to prevent concurrent `terraform apply` runs.

---

## Physical Components

### Container Images

Four Docker images are built and pushed to Azure Container Registry (Basic tier, `crcfpcompass.azurecr.io`):

| Image Name | Contents | Base Image |
|-----------|---------|-----------|
| `cfpcompass-web` | `CFPCompass.Web` (Blazor Server) | `mcr.microsoft.com/dotnet/aspnet:10.0` |
| `cfpcompass-api` | `CFPCompass.Api` (ASP.NET Core Web API) | `mcr.microsoft.com/dotnet/aspnet:10.0` |
| `cfpcompass-workers` | `CFPCompass.Workers` (Container Apps Jobs) | `mcr.microsoft.com/dotnet/runtime:10.0` |
| `cfpcompass-functions` | `CFPCompass.Functions` (Azure Functions) | `mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated10.0` |

**AppHost and ServiceDefaults are NOT containerised:** `CFPCompass.AppHost` is a dev-only orchestrator and is excluded from all Docker builds and CI/CD pipelines. `CFPCompass.ServiceDefaults` is a class library consumed at compile time.

**Image tags:** Each image is tagged with:
- `latest` — most recent build from `main`
- `{git-sha}` — the 7-character short SHA of the commit
- `{semver}` — semantic version tag (e.g., `1.0.0`) when a release tag is pushed

Container Apps are configured to pull images from ACR using system-assigned managed identity (no registry credentials in environment variables).

### Container Apps Jobs Schedule

| Job | Image | Schedule (CRON) | Description |
|-----|-------|----------------|-------------|
| `CfpExpiryJob` | `cfpcompass-workers` | `0 0 * * *` (daily midnight UTC) | Hides CFPs 7 days past submission deadline; archives to past-cfps |
| `DeadlineReminderJob` | `cfpcompass-workers` | `0 6 * * *` (daily 6AM UTC) | Sends deadline reminder emails to speakers tracking approaching CFPs |
| `WeeklyDigestJob` | `cfpcompass-workers` | `0 8 * * 0` (Sunday 8AM UTC) | Sends weekly CFP digest emails to subscribers |
| `WorldRegionAssignmentJob` | `cfpcompass-workers` | `0 */6 * * *` (every 6 hours) | Assigns UN M.49 world regions to CFPs with missing region data |

---

## Data Flow

### CI/CD Pipeline

```
PR opened
    └── ci.yml
          ├── dotnet build (solution)
          ├── dotnet test (unit + integration)
          ├── Spectral lint (OpenAPI specs in docs/api/openapi/)
          ├── AsyncAPI CLI validate (AsyncAPI specs in docs/api/asyncapi/)
          └── Docker build (build check only, no push)

Merge to main
    └── cd-dev.yml
          ├── docker build + push → ACR (all 4 images, tagged with git-sha + latest)
          ├── terraform init + plan (dev)
          ├── terraform apply (dev) — auto-approved
          └── az containerapp update (web, api) → new image tag

Manual trigger or semver tag
    └── cd-staging.yml
          ├── docker build + push → ACR (semver tag)
          ├── terraform plan (staging)
          ├── terraform apply (staging)
          └── az containerapp update (web, api, workers, functions)

Manual trigger with approval gate
    └── cd-prod.yml
          ├── Requires GitHub Environment "production" approval
          ├── terraform plan (prod) — plan output posted as PR comment
          ├── terraform apply (prod)
          └── az containerapp update (web, api, workers, functions)
```

### Write Path (Event-Driven)

```
Client POST/PUT
    │
    ▼
Container App (API)
    ├── Validate request (FluentValidation)
    ├── Publish event to Service Bus topic
    └── Return HTTP 202 Accepted + Location header
            │
            ▼ (async)
    Azure Functions (Consumption)
        ├── Service Bus trigger fires
        ├── Process event
        ├── Write to Azure SQL
        ├── Update processing status (Pending → Completed | Failed)
        ├── Invalidate Redis cache entries
        └── Purge APIM response cache

Client polls GET /api/v1/submissions/{id}/status
    └── Returns: Pending | Processing | Completed | Failed
```

### Read Path (Cached)

```
Client GET (public listing/detail)
    │
    ▼
Azure Front Door → APIM
    ├── Check APIM response cache
    │     ├── Cache HIT → return cached response (sub-second)
    │     └── Cache MISS → forward to Container App (API)
    │                           │
    │                           ▼
    │                     Azure SQL (or Redis for session data)
    │                           │
    │                           ▼
    │                     Response cached in APIM
    └── Return response to client
```

---

## Security and Compliance

### Managed Identity Wiring

| Resource | Identity | Grants |
|----------|---------|--------|
| Container App (Web) | System-assigned | Key Vault: `secrets/get`; Azure SQL: `db_datareader`, `db_datawriter`; Azure Blob Storage: `Storage Blob Data Reader` |
| Container App (API) | System-assigned | Key Vault: `secrets/get`; Service Bus: `Azure Service Bus Data Sender`; ACR: `AcrPull`; Azure SQL: `db_datareader`, `db_datawriter`; Azure Blob Storage: `Storage Blob Data Contributor` |
| Container Apps Jobs | System-assigned | Key Vault: `secrets/get`; Azure SQL: `db_datareader`, `db_datawriter` |
| Azure Functions | System-assigned | Key Vault: `secrets/get`; Service Bus: `Azure Service Bus Data Receiver`; Azure SQL: `db_datawriter`; Azure Blob Storage: `Storage Blob Data Contributor` |

> **Blob Storage access (Issue #1, 2026-03-01):** SAS tokens have been replaced with `Storage Blob Data Contributor` RBAC assignments on the Container App managed identities. All blob operations use `DefaultAzureCredential` via the `Aspire.Azure.Storage.Blobs` integration package. SAS token generation and the `Storage-ConnectionString` Key Vault secret should be removed once all environments confirm MI-based access. RBAC assignments are managed by the `blob-storage-rbac` Terraform module. See [GitHub Issue #1](https://github.com/TaleLearnCode/CFPCompass-squad/issues/1).

> **Azure SQL access (Issue #2, 2026-03-02):** `AzureSql-ConnectionString` has been removed from Key Vault. All four services authenticate to Azure SQL via Entra Managed Identity. The EF Core connection string uses `Authentication=Active Directory Managed Identity` — no username or password. SQL database roles (`db_datareader`, `db_datawriter`) are granted via the `azure-sql-rbac` Terraform module (`null_resource` + `sqlcmd` local-exec). See [GitHub Issue #2](https://github.com/TaleLearnCode/CFPCompass-squad/issues/2).

**Key Vault references in Container Apps:** Environment variables in Container Apps are configured as Key Vault references (`@Microsoft.KeyVault(SecretUri=...)`) rather than plain values. At runtime, the Container Apps runtime resolves secrets directly from Key Vault using the app's managed identity.

### APIM Security Configuration

- **Rate limiting:** 100 requests/min (read operations), 10 requests/min (write operations) per subscription key. Policy applied at Product level.
- **Response caching:** Cache-control policies per endpoint. TTL: 5 min (listings), 1 min (detail), 60 min (topics/categories), 24 h (countries/regions).
- **Backend authentication:** APIM communicates with the Container App (API) backend over the VNet-integrated private path. No public-facing Container App ingress for the API container (APIM is the sole public entry point for `/api/*`).
- **CORS:** Configured at APIM policy level to allow API-key-authenticated consumers from any origin.
- **OpenAPI spec import:** APIM imports `docs/api/openapi/cfp-compass-api-v1.yaml` during `terraform apply` to keep gateway configuration in sync with the contract.

---

## Operations and Monitoring

### Health Checks

All service projects expose health check endpoints via .NET Aspire ServiceDefaults:

| Endpoint | Purpose |
|---------|---------|
| `GET /health` | Detailed health check (SQL connectivity, Redis, Service Bus) |
| `GET /alive` | Liveness probe (is the process alive?) |

Container Apps health probes are configured in Terraform to poll `/alive` (liveness) and `/health` (readiness).

### Alerting

Application Insights alerts are configured for:

- HTTP 5xx error rate > 1% over 5 minutes
- Average response time > 2 seconds over 5 minutes
- Azure SQL DTU utilisation > 80% over 10 minutes
- Dead-letter queue depth > 10 messages (Service Bus)
- Failed Azure Functions executions > 5 in 5 minutes

### Log Queries

Structured JSON logs from Serilog flow to the Log Analytics Workspace. Key queries:

- Admin action audit: `AuditLog_CL | where ActionType_s != ""`
- API error rate: `requests | where resultCode >= 500`
- Service Bus dead-letter: `traces | where message contains "dead-letter"`

---

## Non-Goals and Guardrails

- **No direct commits to `main`.** All changes (including Terraform and GitHub Actions changes) must go through a branch and pull request.
- **No secrets in Terraform state.** Sensitive outputs (connection strings) are written to Key Vault by the relevant Terraform module; state files do not contain plaintext secrets.
- **No AppHost in production builds.** The `CFPCompass.AppHost` project is excluded from all Dockerfiles and CI/CD deployment steps.
- **No Premium APIM tier.** Upgrade path is Developer → Standard V2 only.
- **No manual `terraform apply` against prod.** All production Terraform changes must go through the `cd-prod.yml` workflow with GitHub Environment approval.

---

## References

- [Infrastructure Overview](./overview.md)
- [ADR-001: Azure SQL Database](../registers/decisions/ADR-001-azure-sql-database.md)
- [ADR-004: Container Apps Jobs](../registers/decisions/ADR-004-container-apps-jobs.md)
- [ADR-005: Azure Managed Redis](../registers/decisions/ADR-005-azure-managed-redis.md)
- [ADR-006: APIM Developer Tier](../registers/decisions/ADR-006-apim-developer-tier.md)
- [ADR-007: Event-Driven Write Pattern](../registers/decisions/ADR-007-event-driven-write-pattern.md)
- [ADR-013: .NET Aspire](../registers/decisions/ADR-013-dotnet-aspire.md)
- [ADR-014: Contract-First API Design](../registers/decisions/ADR-014-contract-first-design.md)
- [Decisions Register](../registers/decisions/README.md)
- CFP Compass `.squad/architecture.md` (authoritative system architecture)
