---
title: CFP Compass Contracts
description: Overview of the contract-first approach for REST APIs and Service Bus events in CFP Compass, and how the contract documents relate to the OpenAPI and AsyncAPI machine-readable specifications.
tags:
  - architecture
  - contracts
  - api-contract
  - event-contract
  - governance
  - adr-014
---

# CFP Compass Contracts

This directory contains the canonical contract documentation for all governed interfaces in CFP Compass — both REST API endpoints and Azure Service Bus event schemas.

> **ADR-014: Contract-First Design**
> All REST endpoints and Service Bus topics require an approved specification before implementation begins. This directory houses the prose contract documents. Machine-readable specs live in `docs/api/`.

---

## What Is a Contract Document?

A contract document is the authoritative, human-readable specification for a governed interface. It defines:

- **Purpose and scope** — what the interface covers and what it explicitly does not cover
- **Request and response models** — field names, types, constraints, and semantics
- **Validation and governance rules** — what the API or event guarantees at its boundary
- **Execution semantics** — what happens when a request is accepted or an event is published
- **Error handling** — what errors are possible and how they are reported
- **Security and access control** — authentication mechanisms and authorization rules
- **Relationships** — how the interface connects to other APIs, events, and architecture artifacts

Contract documents are **not** implementation guides. They contain no code, no implementation details, and no tool-specific syntax. Each section is independently reviewable and updatable.

---

## Contract-First Workflow (ADR-014)

```
1. Requirements identified
        │
        ▼
2. Contract document authored (this directory)
        │
        ▼
3. Machine-readable spec authored
   ├── REST API  → OpenAPI 3.1 YAML (docs/api/openapi/)
   └── Events    → AsyncAPI 3.0 YAML (docs/api/asyncapi/)
        │
        ▼
4. Spec PR reviewed and merged (approval gate)
        │
        ▼
5. Implementation PR opened — must reference approved spec PR
        │
        ▼
6. CI validates spec conformance on every PR
   ├── REST: Spectral lint (spectral:oas ruleset)
   └── Events: AsyncAPI CLI (asyncapi validate)
```

No REST endpoint may be implemented without a merged OpenAPI spec. No Service Bus topic may be produced or consumed without a merged AsyncAPI spec. Implementation PRs that touch API routes or event producers/consumers must reference the approved spec PR in the PR description.

---

## Directory Structure

```
docs/contracts/
├── README.md                         ← This file
├── apis/
│   ├── README.md                     ← API contracts index
│   ├── cfps.md                       ← CFPs API Contract
│   ├── metadata.md                   ← Metadata API Contract
│   ├── account.md                    ← Account & User API Contract
│   ├── submissions.md                ← Submissions API Contract
│   ├── claims.md                     ← Organizer Claims API Contract
│   └── admin.md                      ← Admin API Contract
└── events/
    ├── README.md                     ← Event contracts index
    ├── cfp-submission-created.md
    ├── cfp-submission-updated.md
    ├── cfp-submission-approved.md
    ├── cfp-submission-rejected.md
    ├── cfp-submission-reconsideration-requested.md
    └── organizer-claim-requested.md
```

---

## API Contracts (`apis/`)

Six REST API contract documents covering all endpoint groups in `CfpCompass.Api`:

| Contract | Endpoints | Via APIM |
|----------|-----------|----------|
| [`cfps.md`](./apis/cfps.md) | `GET/POST/PUT /api/v1/cfps`, archive, history | ✅ Yes |
| [`metadata.md`](./apis/metadata.md) | Topics, categories, countries, regions | ✅ Yes |
| [`account.md`](./apis/account.md) | Register, login, logout, tracking, preferences | ❌ Internal only |
| [`submissions.md`](./apis/submissions.md) | Submit, edit, reconsider, status poll | ❌ Internal only |
| [`claims.md`](./apis/claims.md) | Initiate claim, verify claim | ❌ Internal only |
| [`admin.md`](./apis/admin.md) | Moderation, users, API keys, dashboard | ❌ Internal only |

See [`apis/README.md`](./apis/README.md) for the full endpoint index and authentication summary.

### Relationship to OpenAPI Specs

The OpenAPI 3.1 spec at `docs/api/openapi/cfp-compass-api-v1.yaml` is the **machine-readable source of truth** for the APIM-exposed endpoints (CFPs and Metadata). APIM imports this spec directly — it IS the APIM policy source of truth.

The contract documents in this directory are the **prose complement**: they capture governance rules, execution semantics, error handling rationale, and relationships that are not expressible in OpenAPI schema syntax. Both must be consistent — if they diverge, the OpenAPI spec takes precedence for implementation but the contract document must be updated to match.

Internal endpoints (Account, Submissions, Claims, Admin) are documented only in these contract files for MVP. OpenAPI specs for internal endpoints may be added in a future iteration.

---

## Event Contracts (`events/`)

Six Azure Service Bus event contract documents covering the full CFP submission lifecycle and the organizer claim flow:

| Contract | Topic | Key Consumers |
|----------|-------|---------------|
| [`cfp-submission-created.md`](./events/cfp-submission-created.md) | `cfp-submissions` | `CfpSubmissionProcessor`, `NotificationProcessor`, `StatusUpdateProcessor` |
| [`cfp-submission-updated.md`](./events/cfp-submission-updated.md) | `cfp-submissions` | `CfpSubmissionProcessor`, `StatusUpdateProcessor` |
| [`cfp-submission-approved.md`](./events/cfp-submission-approved.md) | `cfp-submissions` | `CfpSubmissionProcessor`, `NotificationProcessor`, `CacheInvalidationProcessor` |
| [`cfp-submission-rejected.md`](./events/cfp-submission-rejected.md) | `cfp-submissions` | `CfpSubmissionProcessor`, `NotificationProcessor` |
| [`cfp-submission-reconsideration-requested.md`](./events/cfp-submission-reconsideration-requested.md) | `cfp-submissions` | `CfpSubmissionProcessor`, `NotificationProcessor` |
| [`organizer-claim-requested.md`](./events/organizer-claim-requested.md) | `organizer-claims` | `CacheInvalidationProcessor`, `NotificationProcessor` |

See [`events/README.md`](./events/README.md) for the full event lifecycle diagram and consumer summary.

### Relationship to AsyncAPI Specs

The AsyncAPI 3.0.0 specs at `docs/api/asyncapi/` are the **machine-readable source of truth** for all Service Bus event schemas. The AsyncAPI CLI validates these specs in CI on every PR that touches the `docs/api/asyncapi/` directory.

The event contract documents in this directory are the **prose complement**: they describe processing rules, idempotency guarantees, error handling strategies, governance policies, and relationships to other contracts that cannot be captured in the AsyncAPI spec's schema-centric format.

---

## Authentication and Trust Model Overview

| Context | Mechanism | Covered In |
|---------|-----------|------------|
| External API consumers (public API) | APIM subscription key (`Ocp-Apim-Subscription-Key`) | `cfps.md`, `metadata.md` |
| Web application users (speakers) | ASP.NET Core Identity cookie (HttpOnly, 14-day sliding) | `account.md`, `claims.md` |
| Anonymous submitters (public form) | Cloudflare Turnstile + honeypot | `submissions.md` |
| Submission edit/reconsider tokens | Single-use JWT (72h, email link) | `submissions.md` |
| Organizer claim verification tokens | Single-use JWT (7d, email link) | `claims.md` |
| Admin users | Cookie + Admin claim (email in `CFPCOMPASS_ADMIN_EMAILS`) | `admin.md` |

---

## Governance Principles

- **Producer authority**: Only the designated producer may publish to a given Service Bus topic. No other service component may bypass the API layer to directly publish.
- **Schema versioning**: The `schemaVersion` field in every event payload enables consumers to detect and reject incompatible messages. Breaking schema changes require a coordinated deployment plan.
- **Audit trail**: All admin actions and all moderation state transitions are written to the `AuditLog` table in Azure SQL and to Azure Log Analytics via Serilog structured logging.
- **Dead-letter monitoring**: Azure Monitor alerts fire when any Service Bus subscription's dead-letter queue depth exceeds 0 in production.
- **Contract changes**: Changes to contract documents and machine-readable specs follow the same PR review and approval gate process as code changes.

---

## Related Resources

| Resource | Purpose |
|----------|---------|
| `docs/api/openapi/cfp-compass-api-v1.yaml` | OpenAPI 3.1 spec — APIM-exposed REST endpoints |
| `docs/api/asyncapi/cfp-submissions.asyncapi.yaml` | AsyncAPI 3.0 spec — `cfp-submissions` topic |
| `docs/api/asyncapi/organizer-claims.asyncapi.yaml` | AsyncAPI 3.0 spec — `organizer-claims` topic |
| Architecture §4 | API Design — APIM topology, rate limits, caching, async write pattern |
| Architecture §7 | Background Services — Azure Functions processors |
| Architecture §11 | API & Event Contract Design — spec-first requirement, CI tooling |
| ADR-007 | Event-driven async writes via Azure Service Bus |
| ADR-012 | Bot protection — Cloudflare Turnstile |
| ADR-014 | Contract-first API and event design (the decision that mandates this directory) |
