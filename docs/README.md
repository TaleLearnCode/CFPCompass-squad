---
title: CFP Compass Documentation
description: Complete documentation for CFP Compass, the Azure-hosted .NET 10 platform aggregating Calls for Papers for community speakers.
tags:
  - cfp-compass
  - documentation
  - index
---

# CFP Compass

**CFP Compass** is a .NET 10, Azure-hosted web application that aggregates open Calls for Papers (CFPs) for community speakers. Organizers submit CFPs through a public form; admins moderate submissions before publication. Authenticated speakers track CFPs through a three-state workflow (Interested → Submitted → Accepted), receive deadline reminders and weekly digest emails, and browse a historical archive of past CFPs. A public REST API enables third-party integrations.

---

## Documentation Index

### [Architecture Guide](architecture-guide.md)

A high-level overview of the CFP Compass system intended for all stakeholders, product owners, new team members, and contributors who need to understand how the system works without deep-diving into component specifications. Covers the solution overview, core user flows, key design principles, and the technology stack.

---

### [Architecture](architecture/)

Deep-dive technical specifications for the CFP Compass system design.

| Document | Description |
|----------|-------------|
| `architecture/` | Component architecture, deployment topology, solution structure, event-driven write pattern, and .NET solution layout |

Key topics covered:
- **System Context:** How CFP Compass fits within the Azure ecosystem and the responsibilities of each component.
- **Logical Components:** Web app (Blazor Server), API Host (ASP.NET Core), background workers (Container Apps Jobs), Azure Functions (Service Bus processors), and their interactions.
- **Non-Goals and Guardrails:** What CFP Compass explicitly does not do in the MVP (e.g., no event ticket sales, no per-CFP notification preferences, English-only for MVP).
- **Event-Driven Write Pattern:** How POST/PUT operations flow through Service Bus to Azure Functions to Azure SQL, returning HTTP 202 immediately.

---

### [Contracts](contracts/)

API and event contracts following the contract-first design discipline (ADR-014). All REST API endpoints and Service Bus event schemas are specified before implementation begins.

#### API Contracts (`contracts/apis/`)

| Document | Description |
|----------|-------------|
| [`cfps.md`](contracts/apis/cfps.md) | CFP listing, browse, search, and individual CFP detail endpoints |
| [`submissions.md`](contracts/apis/submissions.md) | CFP submission creation, status polling, and reconsideration endpoints |
| [`metadata.md`](contracts/apis/metadata.md) | Reference data endpoints: taxonomy, ISO 3166 countries, IANA time zones, UN M.49 regions |
| [`account.md`](contracts/apis/account.md) | User account management, notification preferences, and CFP tracking operations |

Additional API contracts (claims, admin) are defined in progress per ADR-014.

#### Event Contracts (`contracts/events/`)

Six Service Bus topic event schemas (AsyncAPI 3.0.0):

| Event | Description |
|-------|-------------|
| `cfp-submission-created` | New CFP submission submitted via the public form |
| `cfp-submission-updated` | Organizer edited a pending submission before moderation |
| `cfp-submission-approved` | Admin approved and published a submission |
| `cfp-submission-rejected` | Admin rejected a submission |
| `cfp-submission-reconsideration` | Organizer requested reconsideration after rejection |
| `organizer-claim-requested` | Someone requested to claim an unverified CFP listing |

---

### [Data Models](data-models/)

Canonical data entity definitions for all core CFP Compass domain objects. These are the authoritative references for EF Core entity design, API request/response shapes, and database schema.

| Document | Description |
|----------|-------------|
| [`cfp.md`](data-models/cfp.md) | The core CFP entity: title, description, submission deadline, event dates, URL, format, taxonomy tags, location, contact details |
| [`user.md`](data-models/user.md) | Authenticated speaker account: identity, notification preferences, OAuth provider links, passkey registrations |
| [`taxonomy.md`](data-models/taxonomy.md) | Category and topic reference data: hierarchical taxonomy for CFP tagging and filtering |
| [`cfp-tracking.md`](data-models/cfp-tracking.md) | Speaker CFP tracking state: per-user, per-CFP tracking records with Interested/Submitted/Accepted state |

Additional data models (Moderation, Claims, Reference Data) are in progress.

---

### [Infrastructure](infrastructure/)

Azure deployment architecture, Terraform module documentation, and environment configuration.

| Document                                                     | Description                                                  |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [`infrastructure/README.md`](infrastructure/README.md)       | Infrastructure overview: Azure services, deployment topology, environment tiers (dev/staging/production) |
| [`infrastructure/overview.md`](infrastructure/overview.md)   | Terraform module structure, CI/CD pipeline overview, environment variable, and Key Vault configuration |
| [`infrastructure/architecture.md`](infrastructure/architecture.md) | Azure networking, Container Apps environment configuration, private endpoint and VNet integration details |

Key infrastructure components:
- **Azure Container Apps:** Web app (Blazor Server) and API Host (.NET Web API) as separate Container Apps within a shared environment.
- **Azure SQL Database Serverless:** Primary relational store; auto-pause after 60 minutes of inactivity.
- **Azure Managed Redis (C0):** Distributed cache for session state and API response caching overflow.
- **Azure API Management (Developer tier):** Public REST API gateway with rate limiting, API key management, and response caching.
- **Azure Service Bus (Standard):** Event-driven write operations via the topic-per-aggregate pattern.
- **Azure Functions (Consumption):** Service Bus message processors for async write operations.
- **Azure Front Door (Standard):** Global CDN, SSL termination, and static asset caching.
- **Azure Communication Services:** Transactional and digest email delivery.

---

### [Process Flows](process-flows/)

Key system workflow documentation describing end-to-end data and control flows for the primary use cases.

Process flows covered (in progress):

| Flow | Description |
|------|-------------|
| CFP Submission | Organizer submits CFP → honeypot + Turnstile validation → Service Bus publish → HTTP 202 → Function processes → SQL write → admin queue |
| CFP Moderation | Admin reviews submission → approve/reject → event published → notification sent to organizer |
| Speaker CFP Tracking | Authenticated speaker marks CFP as Interested/Submitted/Accepted → state persisted to tracking table |
| Organizer Claim Flow | Unverified listing claim request → admin review → claim approved/rejected → organizer account linked |
| API Write Pattern | HTTP POST/PUT → validation → Service Bus publish → 202 Accepted → Function processor → SQL write → cache invalidation |

---

### [Registers](registers/)

Decision, risk, and assumption registers providing full traceability of architectural trade-offs.

#### [Decisions (ADR Register)](registers/decisions/)

Architecture Decision Records documenting every significant technical choice, the context in which it was made, alternatives considered, and consequences accepted.

Key ADRs: Azure SQL Serverless (ADR-001), Blazor Server (ADR-002), Event-Driven Writes (ADR-007), APIM Caching (ADR-011), Cloudflare Turnstile (ADR-012), Contract-First Design (ADR-014).

#### [Risk Register](registers/risks/)

Identified risks with likelihood/severity assessments, mitigation strategies, detection signals, and contingency plans.

| ID | Title | Likelihood | Severity |
|----|-------|-----------|----------|
| RSK-001 | Azure SQL Serverless Cold Start Latency | High | Medium |
| RSK-002 | APIM Developer Tier Availability Limitation | Low | High |
| RSK-003 | Cloudflare Turnstile External Dependency | Low | Medium |
| RSK-004 | Service Bus Message Processing Lag | Low | Low |
| RSK-005 | Azure Managed Redis Pricing at Scale | Medium | Low |

#### [Assumption Register](registers/assumptions/)

Architectural assumptions that must hold for the system to operate as intended, with validation evidence and fallback plans.

| ID | Title | Risk Level |
|----|-------|-----------|
| ASM-001 | cfpcompass.com Domain Availability and DNS Control | High |
| ASM-002 | Azure Services Available in Selected Deployment Region | Medium |
| ASM-003 | Cloudflare Turnstile Free Tier Remains Available | Low |
| ASM-004 | Azure Communication Services Email Delivery Rates | Medium |
| ASM-005 | Azure SQL Serverless Auto-Pause Cold Start Is Acceptable for MVP | High |

---

## How to Contribute to Docs

### Contract-First Workflow (ADR-014)

All REST API endpoints and Service Bus event schema changes must follow the contract-first process:

1. **Write the spec first.** For REST changes, update or create an OpenAPI 3.1 spec in `docs/contracts/apis/`. For Service Bus event changes, update or create an AsyncAPI 3.0.0 spec in `docs/contracts/events/`.
2. **Open a spec PR.** The spec PR is where the design review team feedback happens, before implementation begins.
3. **Get approval.** Spec PR must be merged before an implementation PR is opened. No exceptions.
4. **Open the implementation PR.** Reference the approved spec PR in the implementation PR description.

See [ADR-014](registers/decisions/ADR-014-contract-first-design.md) for full details on the approval workflow, tooling (Spectral, AsyncAPI CLI, oasdiff), and CI enforcement.

### Adding Register Entries

- **New ADR:** Use the template in `docs-template/registers/decisions/`. Assign the next sequential ADR number. Status should be `Proposed` until reviewed.
- **New Risk:** Use `docs-template/registers/risks/rsk-001-data-freshness.md` as the style reference. Update `registers/risks/README.md` to add the entry to the summary table.
- **New Assumption:** Use `docs-template/registers/assumptions/asm-001-ssis-job-cadence.md` as the style reference. Update `registers/assumptions/README.md` to add the entry to the summary table.

### General Documentation Standards

- All documentation is written in Markdown. Follow the existing heading and formatting conventions.
- Cross-reference related documents using relative paths (e.g., `[ADR-007](registers/decisions/ADR-007-event-driven-writes.md)`).
- Do not leave placeholder text or TODO comments in merged documentation. Complete all sections, or note that a document is `In Progress` in its title.
- Documentation for a feature follows the feature branch; spec and register updates are part of the same PR as the feature they describe (except for contract-first specs, which precede implementation).
