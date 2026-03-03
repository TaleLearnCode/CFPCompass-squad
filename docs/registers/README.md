---
title: Registers
description: Index of CFP Compass registers including Architecture Decision Records, risks, and assumptions.
tags:
  - register
  - adr
  - risk
  - assumption
---

# Registers — CFP Compass

This directory contains the three decision, risk, and assumption registers that govern the CFP Compass architecture. Together, these registers provide a traceable record of every significant architectural trade-off, the risks those trade-offs introduce, and the assumptions that must hold for the architecture to function as intended.

## Register Overview

### [Decisions (ADR Register)](decisions/)

Architecture Decision Records (ADRs) document significant decisions about the CFP Compass technical stack, infrastructure choices, and design patterns. Each ADR captures the context, the decision made, alternatives considered, and the consequences of that decision.

**14 ADRs documented:**

| ADR | Title | Status |
|-----|-------|--------|
| ADR-001 | Azure SQL Database (Serverless) | Accepted |
| ADR-002 | Blazor Server with .NET 10 SSR | Accepted |
| ADR-003 | ASP.NET Core Identity + FIDO2/WebAuthn Passkeys | Accepted |
| ADR-004 | Azure Container Apps Jobs for Background Workers | Accepted |
| ADR-005 | Azure Managed Redis (C0) with Containerised Fallback | Accepted |
| ADR-006 | Azure API Management Developer Tier | Accepted |
| ADR-007 | Event-Driven Write Architecture via Service Bus | Accepted |
| ADR-008 | Azure Functions (Consumption) for Service Bus Processors | Accepted |
| ADR-009 | Azure Front Door Standard for CDN and SSL Termination | Accepted |
| ADR-010 | Azure Communication Services for Email | Accepted |
| ADR-011 | APIM Response Caching for Public Read Endpoints | Accepted |
| ADR-012 | Cloudflare Turnstile for Bot Protection | Accepted |
| ADR-013 | .NET Aspire 9.1 for Development Orchestration | Accepted |
| ADR-014 | Contract-First API and Event Design (OpenAPI + AsyncAPI) | Accepted |

**When to add a new ADR:** When making a significant technical decision that involves trade-offs, affects more than one component, or would be difficult to reverse. Use the ADR template in `docs-template/registers/decisions/`.

---

### [Risks](risks/)

The risk register tracks identified threats to system availability, correctness, cost, and user experience. Risks are assessed for likelihood and severity, with documented mitigation strategies and contingency plans.

**5 identified risks:**

| ID | Title | Likelihood | Severity | Status |
|----|-------|-----------|----------|--------|
| [RSK-001](risks/RSK-001-sql-serverless-cold-start.md) | Azure SQL Serverless Cold Start Latency | High | Medium | Open |
| [RSK-002](risks/RSK-002-apim-developer-tier-availability.md) | APIM Developer Tier Availability Limitation | Low | High | Open |
| [RSK-003](risks/RSK-003-cloudflare-turnstile-dependency.md) | Cloudflare Turnstile External Dependency | Low | Medium | Open |
| [RSK-004](risks/RSK-004-service-bus-message-processing-lag.md) | Service Bus Message Processing Lag | Low | Low | Open |
| [RSK-005](risks/RSK-005-azure-managed-redis-pricing.md) | Azure Managed Redis Pricing at Scale | Medium | Low | Open |

**When to add a new risk:** When an architectural decision accepts a known trade-off that could cause future harm, when a new external dependency is introduced with limited SLA or redundancy, or when a known platform constraint (SKU limitation, pricing model, third-party service) may degrade user experience or availability.

---

### [Assumptions](assumptions/)

The assumption register documents conditions that are taken as given — either because they were unconfirmed at design time, or because they depend on external factors outside the team's direct control. When an assumption is invalidated, fallback plans activate.

**5 architectural assumptions:**

| ID | Title | Risk Level | Status |
|----|-------|-----------|--------|
| [ASM-001](assumptions/ASM-001-domain-availability.md) | cfpcompass.com Domain Availability and DNS Control | High | Active |
| [ASM-002](assumptions/ASM-002-azure-service-regional-availability.md) | Azure Services Available in Selected Deployment Region | Medium | Active |
| [ASM-003](assumptions/ASM-003-cloudflare-turnstile-free-tier.md) | Cloudflare Turnstile Free Tier Remains Available | Low | Active |
| [ASM-004](assumptions/ASM-004-acs-email-delivery.md) | Azure Communication Services Email Delivery Rates | Medium | Active |
| [ASM-005](assumptions/ASM-005-sql-serverless-auto-pause-acceptable.md) | Azure SQL Serverless Auto-Pause Cold Start Is Acceptable for MVP | High | Active |

**When to add a new assumption:** When an architectural decision was made based on an unconfirmed external fact; when a key dependency (pricing, service availability, third-party behaviour) is taken as given without current evidence; or when a "good enough for MVP" design choice depends on a condition that may not hold at scale.

---

## Cross-Register Traceability

The three registers are interlinked. The following table shows key relationships:

| Assumption | If Invalidated → | Related Risk | Relevant ADR |
|-----------|-----------------|-------------|-------------|
| ASM-001 (domain) | Infrastructure provisioning blocked | — | All domain-dependent config |
| ASM-002 (region availability) | Service substitution required | — | ADR-005, ADR-006 |
| ASM-003 (Turnstile free tier) | Bot protection cost increases | RSK-003 | ADR-012 |
| ASM-004 (ACS email delivery) | Email deliverability poor | — | ADR-010 |
| ASM-005 (cold start acceptable) | Performance SLO breached | RSK-001 | ADR-001, ADR-007, ADR-011 |

## Templates

Use the document templates in `docs-template/registers/` when creating new entries:

- Risk template: `docs-template/registers/risks/rsk-001-data-freshness.md` (use as style reference)
- Assumption template: `docs-template/registers/assumptions/asm-001-ssis-job-cadence.md` (use as style reference)
