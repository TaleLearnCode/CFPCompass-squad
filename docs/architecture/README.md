---
title: Architecture Documentation Index
description: Index and navigation guide for CFP Compass architecture documentation.
tags:
  - architecture
  - index
  - cfp-compass
---

# CFP Compass Architecture Documentation

This folder contains the canonical documentation for the CFP Compass architecture. Each document covers a specific architectural concern and is designed to be read independently or as part of the full documentation set.

---

## Documents

### [`system-context-and-logical-components.md`](./system-context-and-logical-components.md)

**What it covers:** Where CFP Compass fits in its ecosystem the upstream systems that feed into it (Azure Front Door, APIM, OAuth providers, Cloudflare Turnstile, end users), the downstream services it depends on (Azure SQL, Redis, Service Bus, ACS, Blob Storage, Key Vault, ACR), and the logical decomposition of CFP Compass into eight distinct components with explicit responsibilities and scope boundaries.

**Read this when you need to:** Understand the structural boundaries of the system, what is external, what is internal, who owns what, and how the major logical pieces fit together. Includes a Mermaid system context diagram and a data flow summary for the two primary operational flows (public read path and CFP submission write path).

**Key topics:**

- System context diagram (upstream → CFP Compass → downstream)
- Upstream system responsibility boundaries (Front Door, APIM, OAuth providers, Turnstile)
- Downstream service ownership model (SQL, Redis, Service Bus, ACS, Key Vault)
- Eight logical components: Domain Logic, Application Services, Infrastructure, Web App, API Host, Background Workers, Service Bus Processors, Shared Baseline
- Data flow summary: public CFP discovery (read) and CFP submission (write)

---

### [`architecture-specifications.md`](./architecture-specifications.md)

**What it covers:** The detailed architectural design of all nine CFP Compass solution projects, component responsibilities, input/output contracts, inter-component dependencies, communication patterns (synchronous and asynchronous), state management (Azure SQL, Redis, in-memory), failure modes and resilience strategies, and integration with all Azure services.

**Read this when you need to:** Understand how the system is built at an architectural level, how components communicate, what they own, how they fail, and how they recover. This is the primary reference for developers implementing new features or modifying existing components.

**Key topics:**
- Clean Architecture layer responsibilities (Domain → Application → Infrastructure → API/Web/Workers)
- Event-driven write pattern: API → Service Bus → Azure Functions → SQL → HTTP 202
- Service Bus topic topology: `cfp-submissions`, `user-accounts`, `notifications`, `processing-status`, `cache-invalidation`
- At least once delivery guarantees and idempotent processor design
- Azure SQL, Redis, and in-memory caching strategy and lifecycle
- Failure scenarios and mitigation: SQL cold starts, Redis unavailability, Function dead-letter queues

---

### [`non-goals-and-guardrails.md`](./non-goals-and-guardrails.md)

**What it covers:** The explicit scope boundaries of CFP Compass eight capabilities that are intentionally excluded (speaker profiles, organizer CFP management, email marketing, real-time notifications, multi-tenancy, data export/analytics, conference scheduling, and replacement of existing conference tools) plus five architectural guardrails (contract-first development, event-driven writes only, English-only MVP with i18n in place, no direct DB access from the Web layer, env-config admin accounts).

**Read this when you need to:** Evaluate a feature request, architecture change proposal, or integration idea against the defined scope. This document prevents scope creep and provides a rationale for why specific capabilities are absent, ensuring future maintainers understand that these are deliberate decisions, not omissions.

**Key topics:**
- Eight documented non-goals with rationale and consumer redirection guidance
- Five architectural guardrails with accepted tradeoffs and design implications
- Four accepted strategic tradeoffs (eventual consistency, APIM Developer tier, ASP.NET Core Identity, single-tenant)
- Platform scope lens: In Scope / Out of Scope / By Design quick-reference table
- Governance guidance: how to use this document for feature requests and architecture reviews

---

## Related Documents

| Document | Location | Purpose |
|----------|----------|---------|
| Architecture Guide | `docs/architecture-guide.md` | High-level overview: business purpose, architectural overview, Azure service topology, key requirements, security, and NFRs |
| ADR Log (Decisions) | `.squad/decisions.md` | All Architecture Decision Records (ADR-001 through ADR-014) with full rationale |
| Canonical Architecture | `.squad/architecture.md` | The authoritative technical architecture reference maintained by the Lead Architect |
| OpenAPI Spec | `docs/api/openapi/cfp-compass-api-v1.yaml` | REST API contract (OpenAPI 3.1)   approved before implementation |
| AsyncAPI Specs | `docs/api/asyncapi/` | Service Bus event contracts (AsyncAPI 3.0.0)   approved before implementation |
| Terraform Infrastructure | `infra/` | Infrastructure as Code for all Azure services |
