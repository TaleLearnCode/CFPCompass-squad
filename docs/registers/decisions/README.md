---
title: Architecture Decision Records
description: Index of all Architecture Decision Records (ADRs) for CFP Compass, documenting key technical decisions and their rationale.
tags:
  - adr
  - architecture-decision-record
  - decisions
  - register
---
# Architecture Decision Records

This register documents all architectural decisions made for CFP Compass. Each ADR captures the context, options considered, decision made, and consequences. ADRs are immutable once accepted — revisions produce a new ADR that supersedes the original.

## ADR Index

| ADR | Title | Status | Date | Summary |
|-----|-------|--------|------|---------|
| [ADR-001](./ADR-001-azure-sql-database.md) | Azure SQL Database (Serverless) for Primary Data Store | Accepted | 2026-02-28 | Azure SQL Serverless GP S0 chosen over Cosmos DB and PostgreSQL for relational integrity, EF Core maturity, and auto-pause cost savings (~$5–15/month). |
| [ADR-002](./ADR-002-blazor-server.md) | Blazor Server with .NET 10 SSR for Web Frontend | Accepted | 2026-02-28 | Blazor Server provides both server-side rendering (SEO) and rich interactivity in a single C# codebase; chosen over Razor Pages and Blazor WASM. |
| [ADR-003](./ADR-003-aspnet-core-identity.md) | ASP.NET Core Identity over Azure AD B2C | Accepted | 2026-02-28 | Self-hosted Identity with Fido2NetLib for passkeys; avoids B2C custom policy complexity and per-auth costs; simple admin email list via Key Vault. |
| [ADR-004](./ADR-004-container-apps-jobs.md) | Azure Container Apps Jobs for Background Workers | Accepted | 2026-02-28 | Scheduled jobs (CfpExpiryJob, DeadlineReminderJob, WeeklyDigestJob, WorldRegionAssignmentJob) run as Container Apps Jobs — same container ecosystem, Terraform-managed, pay-per-execution. |
| [ADR-005](./ADR-005-azure-managed-redis.md) | Azure Managed Redis over Azure Cache for Redis | Accepted | 2026-03-01 (revised) | Azure Cache for Redis retiring 2028-09-30; Azure Managed Redis (C0, Redis 7.x) is Microsoft's replacement. Containerised Redis documented as fallback. Supersedes original Azure Cache for Redis selection. |
| [ADR-006](./ADR-006-apim-developer-tier.md) | Azure API Management Developer Tier | Accepted | 2026-03-01 (revised) | Developer tier provides dedicated capacity (no cold start) and VNet integration; ~$50/month justified over Consumption tier's cold-start and VNet limitations. Upgrade path: Developer → Standard V2. Supersedes original Consumption tier selection. |
| [ADR-007](./ADR-007-event-driven-write-pattern.md) | Event-Driven Write Pattern via Azure Service Bus | Accepted | 2026-03-01 | POST/PUT → Service Bus publish → HTTP 202 Accepted → Azure Functions write to SQL. Decouples API responsiveness from SQL cold starts; dead-letter queues handle failures. |
| [ADR-008](./ADR-008-service-bus-standard-tier.md) | Azure Service Bus Standard Tier | Accepted | 2026-03-01 | Standard tier (topics + subscriptions + dead-letter queues) chosen over Basic (queues only) and Premium (over-engineered). ~$10/month; enables fan-out to multiple subscribers. |
| [ADR-009](./ADR-009-http-202-accepted-pattern.md) | HTTP 202 Accepted Response Pattern for Async Writes | Accepted | 2026-03-01 | Write endpoints return 202 + `Location` header. Status transitions: Pending → Processing → Completed \| Failed. Callers poll `GET /api/v1/submissions/{id}/status`. |
| [ADR-010](./ADR-010-multi-select-taxonomy.md) | Multi-Select Taxonomy with Junction Tables | Accepted | 2026-02-28 | Many-to-many via `CfpListingCategory` and `CfpTopic` junction tables. 10 Primary Domains + 10 Secondary Tag groups seeded; admin-extensible. At least one category required; topics optional. |
| [ADR-011](./ADR-011-apim-response-caching.md) | APIM Response Caching for Read Path | Accepted | 2026-03-01 | APIM caches public GET responses. TTL: 5 min (listing), 1 min (detail), 60 min (taxonomy), 24 h (reference data). Event-driven invalidation via CacheInvalidationProcessor Function on Service Bus write events. |
| [ADR-012](./ADR-012-bot-protection-turnstile.md) | Bot Protection: Cloudflare Turnstile + Honeypot | Accepted | 2026-02-28 | Public CFP submission form protected by Cloudflare Turnstile (invisible, GDPR-compliant, free, no Google) + hidden honeypot field. Scored 4.70/5 vs reCAPTCHA v3 (4.15) in weighted decision matrix. |
| [ADR-013](./ADR-013-dotnet-aspire.md) | .NET Aspire 13.1 for Local Orchestration and Observability | Accepted | 2026-03-01 | AppHost provides single-command local startup; ServiceDefaults enforces OpenTelemetry, health checks, and resilience across all service projects. Aspire Dashboard at `https://localhost:18888`. AppHost NOT deployed to production. |
| [ADR-014](./ADR-014-contract-first-design.md) | Contract-First API and Event Design | Accepted | 2026-03-01 | All REST endpoints require approved OpenAPI 3.1 spec; all Service Bus topics require approved AsyncAPI 3.0.0 spec before implementation. Specs in `docs/api/`. CI enforced via Spectral + AsyncAPI CLI + oasdiff. |

## ADR Lifecycle

ADRs in this register follow this lifecycle:

```
Proposed → Accepted
         → Rejected
Accepted → Deprecated
         → Superseded by [new ADR]
```

Once an ADR is accepted, it is **immutable** — it records the decision as it was made, including the context and reasoning at that time. If circumstances change and a decision must be revised, a **new ADR** is created that supersedes the original. Both the original and the new ADR remain in the register.

## Creating a New ADR

1. Copy the ADR template from `docs-template/registers/decisions/adr-template.md`
2. Name the file `ADR-{NNN}-{short-kebab-title}.md` (next sequential number)
3. Fill in all sections — no placeholder text
4. Create a spec PR or requirements PR referencing the ADR if the decision affects an API contract or data schema
5. Update this README table after the ADR is accepted

## Superseded Decisions

Two decisions have been revised and superseded during architecture evolution:

| Original Decision | Superseded By | Reason |
|------------------|--------------|--------|
| Azure Cache for Redis C0 (v1.0, 2026-02-28) | [ADR-005](./ADR-005-azure-managed-redis.md) | Azure Cache for Redis retiring 2028-09-30 |
| APIM Consumption tier (v1.0, 2026-02-28) | [ADR-006](./ADR-006-apim-developer-tier.md) | Consumption tier cold start and no VNet integration |

## Related Documents

- [Infrastructure Overview](../../infrastructure/overview.md)
- [Infrastructure Architecture](../../infrastructure/architecture.md)
- `.squad/architecture.md` — authoritative system architecture (source of truth for all ADRs)
- `.squad/decisions.md` — chronological decision log maintained by Scribe
