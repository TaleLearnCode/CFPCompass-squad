---
title: Infrastructure Documentation
description: Index of CFP Compass infrastructure documentation covering Azure architecture, resource topology, and deployment design.
tags:
  - infrastructure
  - azure
  - architecture
---

# Infrastructure Documentation

This directory contains infrastructure documentation for CFP Compass — the Azure-hosted deployment model, service topology, Terraform IaC structure, and CI/CD pipeline.

## Documents

| Document | Description |
|----------|-------------|
| [overview.md](./overview.md) | Azure deployment model, service inventory, network topology, identity model, observability strategy, cost estimates, and disaster recovery posture. Start here for a complete picture of what runs in Azure. |
| [architecture.md](./architecture.md) | Terraform module structure, GitHub Actions CI/CD workflow, Docker image strategy, managed identity wiring, APIM security configuration, and operations monitoring. Reference for infrastructure engineers implementing or changing the IaC. |

## Quick Reference

**Estimated MVP cost:** ~$125–165/month

**Environments:** `dev` (auto-deploy on merge to `main`), `staging` (manual trigger), `prod` (manual approval gate)

**Key services:**
- Azure Container Apps (Consumption) — Web (Blazor Server) + API (ASP.NET Core)
- Azure Container Apps Jobs — CfpExpiryJob, DeadlineReminderJob, WeeklyDigestJob, WorldRegionAssignmentJob
- Azure SQL Database (Serverless GP S0) — primary data store
- Azure Managed Redis (C0) — distributed cache + session
- Azure API Management (Developer) — gateway, rate limiting, caching, developer portal
- Azure Service Bus (Standard) — event-driven write path
- Azure Functions (Consumption) — Service Bus processors
- Azure Front Door (Standard) — CDN, SSL termination
- Azure Communication Services — transactional email
- Azure Key Vault (Standard) — secrets (no secrets in environment variables)
- Azure Container Registry (Basic) — Docker images

**IaC:** Terraform modules in `infra/` with per-environment `terraform.tfvars`

**CI/CD:** GitHub Actions — `.github/workflows/ci.yml`, `cd-dev.yml`, `cd-staging.yml`, `cd-prod.yml`

## Related

- [Decisions Register](../registers/decisions/README.md) — all ADRs for infrastructure and architectural choices
- `.squad/architecture.md` — authoritative system architecture document
