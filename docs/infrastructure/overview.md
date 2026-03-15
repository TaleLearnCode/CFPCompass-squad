---
title: Infrastructure Overview
description: Azure cloud infrastructure overview for CFP Compass — deployment model, services, network topology, identity, observability, and cost.
tags:
  - infrastructure-overview
  - architecture
  - azure
  - cloud
  - platform
  - observability
  - governance
  - security
---

# Infrastructure Overview

## Purpose & Scope

This document describes the Azure cloud infrastructure that hosts CFP Compass in all environments (dev, staging, prod). It covers the deployment model, Azure service inventory, network topology, identity and access strategy, observability approach, data retention, scalability characteristics, and disaster recovery posture.

Intended audience: DevOps engineers (Parker), backend engineers (Ripley), technical leads (Dallas), and anyone needing to understand how the system is deployed and operated.

---

## Deployment Model & Environments

CFP Compass is deployed as a set of containerised Azure services, managed entirely through Terraform IaC. Three environments are maintained:

| Environment | Purpose | Notes |
|-------------|---------|-------|
| **dev** | Active development and feature testing | Auto-deployed on merge to `main`; SQL serverless auto-pause always enabled |
| **staging** | Pre-production validation, UAT, and load testing | Mirrors production SKUs except where cost is prohibitive |
| **prod** | Live production workload | Terraform-managed; releases are manual-approval gated |

Each environment lives in its own Azure Resource Group (`rg-cfpcompass-dev`, `rg-cfpcompass-staging`, `rg-cfpcompass-prod`) within a single Azure subscription. Terraform workspaces and per-environment `terraform.tfvars` files drive environment-specific configuration.

---

## Azure Subscription & Resource Group Strategy

| Resource Group | Environment | Contents |
|----------------|-------------|----------|
| `rg-cfpcompass-dev` | dev | All dev-environment resources |
| `rg-cfpcompass-staging` | staging | All staging-environment resources |
| `rg-cfpcompass-prod` | prod | All production resources |
| `rg-cfpcompass-shared` | shared | Azure Container Registry (shared across envs), Terraform remote state storage |

Terraform remote state is stored in an Azure Storage Account (`stcfpcompasstfstate`) in `rg-cfpcompass-shared`, with per-environment state files and Azure Blob lease-based state locking.

---

## Core Infrastructure Components

### Owned Resources

These services are provisioned per environment and owned exclusively by CFP Compass.

| Service | SKU | Purpose | Est. Monthly Cost |
|---------|-----|---------|-------------------|
| **Azure Container Apps Environment** | Consumption | Shared environment for web, API, and jobs | Included |
| **Azure Container App — Web** | Consumption | Blazor Server (.NET 10) UI host | $5–20 (2 apps combined) |
| **Azure Container App — API** | Consumption | ASP.NET Core Web API host | (see above) |
| **Azure Container Apps Jobs** | Consumption | Background workers (CfpExpiryJob, DeadlineReminderJob, WeeklyDigestJob, WorldRegionAssignmentJob) | Included in Container Apps |
| **Azure SQL Database** | Serverless GP S0 | Primary relational data store | $5–15 |
| **Azure Managed Redis** | C0 | Distributed cache + session state | $16 |
| **Azure API Management** | Developer | API gateway, rate limiting, response caching, developer portal | $50 |
| **Azure Service Bus** | Standard | Event-driven writes; topic-per-aggregate fan-out; dead-letter queues | $10 |
| **Azure Functions** | Consumption | Service Bus message processors (write path, cache invalidation) | $0–5 |
| **Azure Front Door** | Standard | CDN, SSL termination, global edge routing | $35 |
| **Azure Communication Services** | Pay-as-you-go | Transactional and digest email delivery | ~$0.25/1,000 emails |
| **Azure App Configuration** | Free / Standard | Centralized configuration management, feature flags, Key Vault references | $0–36 |
| **Azure Key Vault** | Standard | Secrets management for all runtime credentials | ~$0.03/10K ops |
| **Azure Storage Account** | GPv2 LRS | Blob storage for event logos and file uploads | $1–3 |
| **Azure Log Analytics Workspace** | Pay-as-you-go | Centralised log and telemetry store | $2–5 |
| **Application Insights** | Pay-as-you-go | Distributed tracing, metrics, alerting | Included in Log Analytics |

**Estimated MVP total: ~$125–200/month**

> The cost increase over the initial estimate (~$75–105) is driven by APIM Developer tier ($50 fixed vs. pay-per-call Consumption), Azure Service Bus Standard ($10), and Azure App Configuration (Free tier at MVP, ~$36/month at Standard if request volume exceeds 10K/day). The trade-off is justified: dedicated APIM capacity eliminates cold-start latency, VNet integration enables secure backend communication, Service Bus provides event-driven resilience with dead-letter queues, and App Configuration provides centralized configuration management with feature flags for trunk-based development.

### Shared Platform Resources

| Service | SKU | Purpose |
|---------|-----|---------|
| **Azure Container Registry** | Basic | Docker image store shared across environments (`cfpcompass-web`, `cfpcompass-api`, `cfpcompass-workers`, `cfpcompass-functions`) |

---

## Network & Connectivity Model

CFP Compass uses a **public-endpoint model with APIM gateway** for MVP. All public traffic enters through Azure Front Door; API traffic is routed through APIM before reaching the API Container App.

```
Internet
    │
    ├── Azure Front Door (Standard) ──► Container App (Web) [public ingress, Blazor Server]
    │
    └── Azure Front Door (Standard) ──► APIM (Developer, internal mode)
                                              │
                                              ▼
                                     Container App (API) [ASP.NET Core Web API]
                                              │
                            ┌─────────────────┼──────────────────────────┐
                            │                 │                          │
                            ▼                 ▼                          ▼
                      Azure SQL DB      Azure Managed          Azure Service Bus
                     (firewall: allow    Redis (C0)            (managed identity)
                      Azure services)  (access key auth)
                            │
                      Azure Key Vault   Azure Blob Storage     Azure Comm. Services
                      (managed identity) (managed identity:    (connection string
                                          Blob Data roles)      from Key Vault)

    Azure App Configuration (labels: dev/staging/prod)
        ├── Non-sensitive config values (log levels, URLs, schedules)
        ├── Feature flags (trunk-based development)
        └── Key Vault references (secrets surfaced via App Config)

    Azure Functions (Consumption)
        ├── Subscribes to Service Bus topics
        ├── Writes to Azure SQL
        ├── Invalidates Redis cache
        └── Purges APIM response cache
```

**APIM Developer tier VNet integration (internal mode):**
- The Container App API backend communicates with APIM over a private network path.
- Azure SQL allows connections from Azure services via firewall rule; managed identity is used where possible.
- Redis uses access key authentication retrieved from Key Vault at startup.
- All configuration is centralized in **Azure App Configuration** with per-environment labels (dev/staging/prod). Secrets are stored in Key Vault and surfaced via App Configuration Key Vault references — one retrieval pattern for all config values.
- All secrets are fetched from Key Vault via Azure Managed Identity — no secrets in environment variables at runtime.

**Upgrade path:** Developer tier → Standard V2 when traffic volume requires zone redundancy and a higher SLA. Standard V2 is preferred over Premium for the first upgrade step.

---

## Identity & Access Model

CFP Compass uses **Azure Managed Identity** as the primary credential mechanism for service-to-service communication. No secrets are stored in application configuration or environment variables at runtime.

| Service | Identity Type | Access Target |
|---------|--------------|--------------|
| Container App (Web) | System-assigned managed identity | Key Vault (secrets read), Azure SQL (`db_datareader`, `db_datawriter`), Azure Blob Storage (`Storage Blob Data Reader`) |
| Container App (API) | System-assigned managed identity | Key Vault (secrets read), Service Bus (send), ACR (pull), Azure SQL (`db_datareader`, `db_datawriter`), Azure Blob Storage (`Storage Blob Data Contributor`) |
| Azure Functions | System-assigned managed identity | Key Vault (secrets read), Service Bus (listen), Azure SQL (`db_datawriter`), Azure Blob Storage (`Storage Blob Data Contributor`) |
| Container Apps Jobs | System-assigned managed identity | Key Vault (secrets read), Azure SQL (`db_datareader`, `db_datawriter`) |

**Key Vault secret inventory:**

| Secret | Purpose |
|--------|---------|
| `Redis-ConnectionString` | Cache connection |
| `ServiceBus-ConnectionString` | Service Bus connection |
| `ACS-ConnectionString` | Email service |
| `Fido2-Origins` | WebAuthn allowed origins |
| `AdminEmails` | Comma-separated admin email list |
| `OAuth-Google-ClientId` / `ClientSecret` | Google OAuth |
| `OAuth-GitHub-ClientId` / `ClientSecret` | GitHub OAuth |
| `OAuth-Microsoft-ClientId` / `ClientSecret` | Microsoft OAuth |
| `Jwt-SigningKey` | JWT signing for email tokens |
| `Turnstile-SiteKey` | Cloudflare Turnstile site key |
| `Turnstile-SecretKey` | Cloudflare Turnstile secret key |

> **Azure SQL:** Target state is **Managed Identity–only** access. All four services (Web, API, Jobs, Functions) authenticate to Azure SQL via Entra Managed Identity; the EF Core connection string uses `Authentication=Active Directory Managed Identity` — no username or password. `AzureSql-ConnectionString` is no longer required by Web/API/Jobs/Functions and is being phased out of Key Vault (cleanup pending; ADR-001 still reflects the earlier Key Vault–stored connection string approach). SQL database roles (`db_datareader`, `db_datawriter`) are granted to each service's managed identity via the `azure-sql-rbac` Terraform module. See Issue #2.

> **Blob Storage:** `Storage-ConnectionString` is **not** stored in Key Vault. Blob Storage access is granted via Azure RBAC (Managed Identity) — the storage account name is a non-secret value stored in **Azure App Configuration** as `Storage:AccountName` with per-environment labels. `BlobServiceClient` is initialised with `DefaultAzureCredential` and the account URL (`https://{accountName}.blob.core.windows.net`). See Issue #1 and `.squad/agents/parker/blob-storage-mi-plan.md`.

**Application-level authentication** is handled by ASP.NET Core Identity (passkeys via Fido2NetLib, OAuth social login). See [ADR-003](../registers/decisions/ADR-003-aspnet-core-identity.md) for rationale.

---

## Observability & Diagnostics Strategy

All services emit structured JSON logs, distributed traces, and custom metrics through **.NET Aspire ServiceDefaults** (OpenTelemetry), which exports to **Azure Monitor / Application Insights** in production.

| Signal | Source | Destination |
|--------|--------|-------------|
| Structured logs | Serilog (all services) | Azure Log Analytics Workspace |
| Distributed traces | OpenTelemetry (auto + manual) | Application Insights |
| Custom metrics | OpenTelemetry metrics API | Application Insights |
| Health checks | `/health` (detail), `/alive` (liveness) | Azure Container Apps health probes |
| APIM analytics | Built-in APIM monitoring | Azure Monitor |

**Local development:** Aspire Dashboard at `https://localhost:18888` provides distributed tracing and log correlation during development (see [ADR-013](../registers/decisions/ADR-013-dotnet-aspire.md)).

**Correlation IDs** propagate across all service boundaries (API → Service Bus → Functions → SQL) via OpenTelemetry `Activity` propagation.

**Audit logging:** Admin actions, moderation state transitions, and authentication events are written to both the Log Analytics workspace (structured JSON) and the `AuditLog` SQL table for queryable compliance records.

---

## Data Retention & Compliance

| Data Type | Retention Period | Mechanism |
|-----------|-----------------|-----------|
| Azure SQL (active CFPs, users) | Indefinite (while active) | Azure SQL automated backups (7 days) |
| Azure SQL (status records) | 30 days after completion | TTL-based cleanup job |
| Azure SQL (audit log) | 1 year | Soft delete; admin-only purge |
| Log Analytics logs | 30 days (default) | Configurable retention policy |
| Application Insights telemetry | 90 days | Configurable sampling + retention |
| Service Bus messages (dead-letter) | 14 days | Azure Service Bus default TTL |
| Blob storage (event logos) | Indefinite (while CFP active) | Manual cleanup on CFP deletion |

**GDPR / privacy:** CFP Compass collects personal data (speaker email, name) for tracking. Personal data is stored in Azure SQL (EU region for prod). No cross-border transfer occurs. Cloudflare Turnstile is used without persistent cross-site tracking cookies (see [ADR-012](../registers/decisions/ADR-012-bot-protection-turnstile.md)).

---

## Scalability & Performance Characteristics

| Component | Scale Mechanism | Notes |
|-----------|----------------|-------|
| Container App (Web) | Automatic horizontal scaling (KEDA) | Scales to zero during off-peak |
| Container App (API) | Automatic horizontal scaling (KEDA) | Scales independently from web |
| Azure Functions | Consumption auto-scale | Scales with Service Bus queue depth |
| Azure SQL | Serverless auto-scale (GP S0) | Auto-pause after idle; ~10s cold start |
| Azure Managed Redis | Fixed C0 (1 GB) | Upgrade to C1 if memory pressure observed |
| APIM | Fixed Developer tier capacity | Upgrade to Standard V2 at scale |
| Azure Service Bus | Standard shared throughput | Upgrade to Premium for dedicated throughput |

**Read path performance:** APIM response caching offsets Azure SQL cold starts for public GET endpoints. Cache TTLs: 5 minutes (listing pages), 1 minute (CFP detail), 60 minutes (topics/categories), 24 hours (countries/regions). See [ADR-011](../registers/decisions/ADR-011-apim-response-caching.md).

**Write path performance:** The event-driven write pattern (Service Bus → Azure Functions → SQL) ensures the API always returns HTTP 202 Accepted without blocking on SQL availability. See [ADR-007](../registers/decisions/ADR-007-event-driven-write-pattern.md).

---

## Disaster Recovery & Business Continuity

| Scenario | Recovery Approach | RTO | RPO |
|----------|------------------|-----|-----|
| Container App failure | KEDA auto-restart; multiple replicas | < 5 min | 0 (stateless) |
| Azure SQL failure | Azure SQL built-in HA + 7-day backup | < 15 min | < 5 min |
| Redis failure | Application falls back gracefully; SQL direct reads | < 2 min | 0 (cache is ephemeral) |
| Service Bus failure | API returns 503; retry on reconnect | < 5 min | 0 (in-flight messages retained) |
| Azure Functions failure | Dead-letter queue retains messages for reprocessing | < 30 min | < 1 min |
| Key Vault failure | Cached secrets remain valid; Azure SLA 99.99% | N/A (Azure-managed) | N/A |

**Backup strategy:** Azure SQL automated backups (7-day full, 1-hour log). Blob storage is LRS (locally redundant); upgrade to GRS for disaster recovery at additional cost. No custom backup tooling required for MVP.

---

## Non-Goals & Constraints

- **No private VNet (VNet injection) for MVP.** APIM Developer tier internal mode is the extent of network isolation. Full VNet injection is deferred until traffic and compliance requirements justify the cost and complexity.
- **No zone redundancy for MVP.** All services run in a single Azure availability zone. Upgrade to Standard V2 (APIM) and zone-redundant SQL when SLA requirements demand it.
- **No multi-region deployment.** Azure Front Door provides edge caching globally, but backend services are single-region.
- **No APIM Premium tier.** The upgrade path from Developer is to Standard V2, not Premium.
- **AppHost is not deployed to production.** .NET Aspire AppHost is a local development orchestrator only. Production hosting is Container Apps + Terraform.

---

## Security & Compliance

- **No secrets in environment variables at runtime.** All secrets are fetched from Key Vault via Managed Identity.
- **Bot protection on public forms.** Cloudflare Turnstile (invisible challenge) + honeypot field protects the CFP submission form. See [ADR-012](../registers/decisions/ADR-012-bot-protection-turnstile.md).
- **APIM rate limiting.** 100 read requests/min and 10 write requests/min per API key. Enforced at the APIM layer.
- **App-level rate limiting.** ASP.NET Core Rate Limiting middleware for per-IP limits on login (10/15 min), registration (5/hour), and submission (10/hour).
- **CORS.** Restricted to `https://cfpcompass.com` and `https://www.cfpcompass.com` for the web origin. APIM allows API-key-authenticated consumers from any origin.
- **Input validation.** FluentValidation on all DTOs; ISO 3166 and IANA TZ validation; HTML sanitisation via HtmlSanitizer.
- **Audit logging.** All admin actions, moderation transitions, and authentication events are logged to both Log Analytics and the `AuditLog` SQL table.
- **Admin identity.** Admin emails are stored in Key Vault and checked on every login. No admin management UI for MVP.

---

## Related Documents

- [Infrastructure Architecture](./architecture.md) — Terraform module structure, CI/CD pipeline, container image strategy
- [ADR-001: Azure SQL Database](../registers/decisions/ADR-001-azure-sql-database.md)
- [ADR-005: Azure Managed Redis](../registers/decisions/ADR-005-azure-managed-redis.md)
- [ADR-006: APIM Developer Tier](../registers/decisions/ADR-006-apim-developer-tier.md)
- [ADR-007: Event-Driven Write Pattern](../registers/decisions/ADR-007-event-driven-write-pattern.md)
- [ADR-011: APIM Response Caching](../registers/decisions/ADR-011-apim-response-caching.md)
- [ADR-012: Bot Protection](../registers/decisions/ADR-012-bot-protection-turnstile.md)
- [ADR-013: .NET Aspire](../registers/decisions/ADR-013-dotnet-aspire.md)
- [ADR-015: Remove /api/ Route Prefix](../registers/decisions/ADR-015-remove-api-route-prefix.md)
- [Decisions Register](../registers/decisions/README.md)
