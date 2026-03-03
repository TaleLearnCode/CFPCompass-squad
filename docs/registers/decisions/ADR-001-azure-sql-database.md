---
title: "ADR-001: Azure SQL Database (Serverless) for Primary Data Store"
description: Selects Azure SQL Database Serverless (General Purpose S0) as the primary relational data store for its FK-heavy domain model, EF Core tooling support, and cost-efficient auto-pause during idle periods.
tags:
  - adr
  - architecture-decision-record
  - azure-sql
  - entity-framework-core
status: accepted
---
# Azure SQL Database (Serverless) for Primary Data Store

- **Status:** Accepted
- **Date:** 2026-02-28
- **Work Item:** [*arch-001* — primary data store selection]

## Context and Problem

CFP Compass requires persistent relational storage for its core domain objects: CFP listings, user accounts, speaker tracking records, moderation workflows, organizer claims, and audit logs. The data model is FK-heavy — CFPs reference users, moderation records reference both CFPs and admins, tracking records link speakers to CFPs — making relational integrity a first-class concern. The MVP is expected to have modest traffic and periods of near-zero activity (overnight, weekends), so cost efficiency during idle periods is important. A cloud-managed database service is required to avoid operational overhead.

## Decision Drivers

- Strong relational integrity with foreign keys and enforced referential constraints
- Best-in-class EF Core tooling support for migrations, LINQ queries, and conventions
- Cost-efficient for MVP traffic patterns with auto-pause during idle periods
- Familiar to the widest .NET developer audience to minimise onboarding friction
- Cloud-managed (no DBA operational overhead) on Azure
- Acceptable cold-start latency for the event-driven write pattern (cold start is mitigated by Service Bus buffering)

## Considered Options

- Azure SQL Database (Serverless, General Purpose S0)
- Azure Cosmos DB (NoSQL, serverless)
- Azure Database for PostgreSQL (Flexible Server)

## Decision Outcome

Chosen option: **Azure SQL Database (Serverless, General Purpose S0)**, because it provides the strongest relational model for the FK-heavy CFP Compass domain, the best EF Core migration and tooling support in the .NET ecosystem, and serverless auto-pause to minimise cost during the MVP's idle periods. Cosmos DB's document model and eventual consistency are not a natural fit for the relational domain, and PostgreSQL on Azure, while technically sound, offers no material advantage over Azure SQL for a .NET-first team and adds operational familiarity risk.

#### Consequences

- Good, because strong relational model enforces FK integrity across CFPs, users, tracking, and moderation.
- Good, because EF Core has first-class Azure SQL support including migrations, scaffolding, and LINQ query generation.
- Good, because serverless auto-pause reduces cost to ~$5–15/month during MVP — no charges when idle.
- Good, because familiar to the broadest .NET developer audience; minimal onboarding friction.
- Bad, because serverless cold start (~10 seconds after idle period) introduces latency on first write after a pause — mitigated by the event-driven write pattern (Service Bus buffers events during cold start).
- Bad, because vertical scaling limits compared to Cosmos DB at extreme scale — not a concern for MVP traffic volumes.

#### Implementation

1. Parker provisions Azure SQL Server + Database via the `infra/modules/sql/` Terraform module with the Serverless compute tier, General Purpose family, and S0 hardware generation.
2. Azure SQL firewall is configured to allow connections from Azure services (Container Apps, Functions).
3. Ripley implements EF Core schema with initial migration covering all core entities (Cfp, User, CfpTracking, ModerationRecord, OrganizerClaim, AuditLog, CfpListingCategory, CfpTopic, SubmissionStatus).
4. Connection string (`AzureSql-ConnectionString`) is stored in Key Vault; Container Apps and Functions resolve it via managed identity Key Vault reference.
5. Database seeding migration seeds ISO 3166 countries, IANA time zones, UN M.49 regions, taxonomy categories, and taxonomy topics.
6. Auto-pause is enabled for dev and staging; consider disabling for prod if cold-start impact on first post-pause request is unacceptable.

#### Confirmation

- EF Core migrations apply successfully via CI/CD pipeline before container deployment.
- Integration tests (using SQL Server Docker container) validate all FK constraints and query patterns.
- Azure SQL serverless auto-pause confirmed in dev environment after 1-hour idle threshold.
- Connection via managed identity confirmed (no plaintext connection string in Container App environment variables).

#### Stakeholders

- **Dallas (Lead & Architect):** Decision owner; defined relational model requirements
- **Ripley (Backend):** Implements EF Core schema, migrations, and data access layer
- **Parker (DevOps):** Provisions and manages Terraform module; configures firewall and managed identity access
- **Kane (Tester):** Integration test strategy uses SQL Server Docker container as test database

## Pros and Cons of the Options

### Azure SQL Database (Serverless, General Purpose S0)

- Good, because best EF Core tooling: migrations, LINQ, scaffolding, conventions all work out of the box.
- Good, because relational model with FK enforcement is the natural fit for the CFP/user/moderation domain.
- Good, because serverless auto-pause saves ~$0 during completely idle periods.
- Good, because familiar to .NET developers; no learning curve.
- Good, because managed service: patching, backups (7-day), HA handled by Azure.
- Neutral, because Standard tier upgrade path is straightforward if serverless pause is disabled for production.
- Bad, because ~10s cold start after auto-pause — mitigated by event-driven write pattern buffering in Service Bus.
- Bad, because vertical scaling limits vs. Cosmos at extreme scale (not relevant for MVP).

### Azure Cosmos DB (NoSQL, Serverless)

- Good, because globally distributed with multi-region writes if needed.
- Good, because serverless pricing at near-zero cost during idle.
- Good, because flexible schema accommodates evolving document structure.
- Neutral, because SDK available for .NET; EF Core provider exists but is less mature.
- Bad, because document model is a poor fit for the relational domain (FK-heavy, complex joins).
- Bad, because eventual consistency model adds complexity to moderation workflows that require read-after-write consistency.
- Bad, because limited EF Core migration support; schema evolution requires manual coordination.
- Bad, because Cosmos DB free tier is limited (1,000 RU/s); costs can spike unpredictably with query patterns.

### Azure Database for PostgreSQL (Flexible Server)

- Good, because mature open-source relational database with strong FK and ACID guarantees.
- Good, because EF Core Npgsql provider is high-quality.
- Good, because no proprietary vendor lock-in; portable workload.
- Neutral, because flexible server supports pause/resume (preview feature) for cost savings.
- Bad, because no native .NET SDK; all access is through Npgsql which adds a dependency.
- Bad, because less familiar than SQL Server to the typical .NET developer audience on the team.
- Bad, because PostgreSQL-specific syntax and tooling differ from SQL Server; migration scripts and EF Core conventions may behave differently.
- Bad, because pause/resume feature is in preview and not production-grade for MVP launch.

## More Information

Azure SQL Database Serverless documentation: https://learn.microsoft.com/en-us/azure/azure-sql/database/serverless-tier-overview

The event-driven write pattern (ADR-007) was specifically designed to absorb the Azure SQL cold-start latency. Service Bus buffers write events during the ~10s DB wake-up period, so API callers receive a 202 Accepted immediately and are not blocked.

If auto-pause proves disruptive for production (e.g., peak morning usage triggers a cold start for the first user of the day), the auto-pause delay threshold can be increased or disabled independently per environment without changing the underlying SKU.

EF Core 10 is used with the SQL Server provider. Migrations are applied as part of the CD pipeline before container images are updated.

## Follow-On Information

No changes to this decision are anticipated for MVP. Post-MVP considerations:
- If serverless cold starts in production are unacceptable even with event-driven mitigation, upgrade to provisioned compute (GP S1+) rather than switching databases.
- Evaluate read replicas if read-heavy analytics queries begin to impact write latency.
- Consider Azure SQL Hyperscale tier for very large CFP archive growth (unlikely at MVP scale).

## Record History

* **Proposed**: 2026-02-28
* **Accepted**: 2026-02-28
* **Last Reviewed**: 2026-02-28
