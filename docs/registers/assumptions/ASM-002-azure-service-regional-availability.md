---
title: "ASM-002: Azure Services Available in Selected Deployment Region"
description: All required Azure services are available and generally accessible in the chosen deployment region.
tags:
  - assumption
  - assumption-register
  - azure
---

# Azure Services Available in Selected Deployment Region

**ID:** ASM-002

## Statement

All required Azure services — Azure Container Apps, Azure SQL Database Serverless, Azure Managed Redis, Azure API Management (Developer tier), Azure Service Bus (Standard tier), Azure Functions (Consumption plan), Azure Front Door (Standard), Azure Communication Services, Azure Key Vault, Azure Container Registry (Basic), and Azure Log Analytics — are available at the target SKUs in the selected primary deployment region.

## Context / Rationale

Azure service and SKU availability varies by region. Not all services are available at all SKU levels everywhere, and some newer services (such as Azure Managed Redis) have more limited regional footprints than mature services. CFP Compass depends on 12 distinct Azure services operating in concert within a single region to minimise latency and simplify networking (Container Apps environment, Service Bus private access, Key Vault access policies).

The primary deployment region has not been finalised at the time of this writing. Region selection directly determines:

- Whether all Terraform modules can be deployed without substitution.
- Whether Azure Managed Redis C0 SKU is available (relatively new service with limited initial region coverage).
- Whether Azure Container Apps environments support the required VNet integration and internal ingress configurations.
- Whether Azure Communication Services Email is available (limited regional availability vs. core ACS regions).

Recommended candidate regions with broad service availability include **East US 2** and **West US 2**, both of which support the full Azure service portfolio including Azure Managed Redis, ACS Email, and Azure Container Apps with VNet integration.

## Scope of Impact

- All Terraform modules in `infrastructure/` — every resource definition references the deployment region via the `location` variable.
- CI/CD GitHub Actions pipelines for infrastructure provisioning (`terraform apply`).
- Azure Container Apps environment networking (internal DNS, service-to-service communication).
- Application Insights and Log Analytics workspace co-location for minimal telemetry latency.
- Azure Front Door origin group configuration (origin must be in a supported region for AFD routing).

## Risk Level

**Medium**

The probability is manageable given that the recommended candidate regions (East US 2, West US 2) have confirmed availability for all required services. However, if a region is selected without pre-validation, the risk of a Terraform deployment failure or service substitution requirement is real — particularly for Azure Managed Redis (newest service in the stack) and ACS Email.

## Validation Evidence

Pending region selection. Before committing to a deployment region, Parker (DevOps) to validate availability of all 12 required services and SKUs via:

- Azure Portal → "Products available by region" (`https://azure.microsoft.com/explore/global-infrastructure/products-by-region/`)
- Azure CLI: `az provider list --query "[].{Provider:namespace, State:registrationState}" --output table` (post-region selection)
- Specific validation checklist:
  - [ ] `Microsoft.App` (Container Apps) — available and supports VNet integration
  - [ ] `Microsoft.Sql` (Azure SQL Database Serverless) — `S0` serverless tier available
  - [ ] `Microsoft.Cache` (Azure Managed Redis) — `C0` SKU available
  - [ ] `Microsoft.ApiManagement` (APIM) — Developer tier available
  - [ ] `Microsoft.ServiceBus` (Service Bus Standard) — available
  - [ ] `Microsoft.Web` (Azure Functions Consumption) — available
  - [ ] `Microsoft.Cdn` (Azure Front Door Standard) — available (Front Door is global but origin must be accessible)
  - [ ] `Microsoft.Communication` (ACS Email) — available in region
  - [ ] `Microsoft.KeyVault` — available
  - [ ] `Microsoft.ContainerRegistry` — Basic tier available
  - [ ] `Microsoft.OperationalInsights` (Log Analytics) — available

## Dependencies

- Region selection decision must be made and documented before Terraform module implementation begins.
- Parker (DevOps) owns region validation and Terraform `location` variable configuration.
- ACS Email regional availability must be confirmed independently (limited availability vs. core ACS).

## Review Cadence / Expiry

One-time validation at region selection; review if the deployment region is ever changed or if a new Azure service dependency is added to the architecture.

## Fallback Plan

1. If the preferred region is missing a required service at the target SKU, select the nearest alternate region from the candidate list that satisfies all requirements.
2. If Azure Managed Redis is not available in the selected region, deploy self-hosted containerised Redis (Redis Container App) per ADR-005 — no application code changes required.
3. If ACS Email is not available in the selected region, evaluate using an ACS instance in a nearby region with cross-region email sending (ACS Email does not require co-location with the compute region).
4. Document the final validated region in `infrastructure/README.md` and set `location` in the root Terraform `terraform.tfvars`.
