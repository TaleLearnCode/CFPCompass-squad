---
title: Architecture Guide
description: High-level architectural overview for CFP Compass, a .NET 10 Azure-hosted CFP aggregation platform for community speakers.
tags:
  - architecture
  - guide
  - overview
  - cfp-compass
---

# Architecture Guide

---

## Purpose & Audience

This document is the entry point for understanding CFP Compass. It provides a high-level summary of the system's purpose, design philosophy, structural elements, and key architectural drivers. It is intentionally non-exhaustive; companion documents in `docs/architecture/` provide deeper specifications.

**Intended audience:**

| Role | Why They Should Read This |
|------|--------------------------|
| **Software Architects** | Understand the guiding principles, pattern choices, and key trade-offs that shape the system. |
| **Backend & Frontend Developers** | Understand how their work fits into the larger picture before reading detailed specifications. |
| **Platform & DevOps Engineers** | Understand the Azure service topology and deployment model. |
| **API Consumers / Third-Party Integrators** | Understand the API surface, versioning strategy, and access model. |
| **Product Owners & Business Stakeholders** | Understand the architecture's strategic intent without implementation details. |

This document does **not** replace detailed design documents. For component-level specifications, message schemas, non-goals, and system context, see the companion documents listed in the Appendices section.

---

## Business Purpose

CFP Compass exists to reduce the friction that community speakers face when discovering, tracking, and submitting to Calls for Papers (CFPs) for technology conferences and events worldwide.

**The problem it solves:** The CFP landscape is fragmented. Speakers currently track open CFPs through scattered Twitter/X posts, community Slack channels, personal spreadsheets, and conference websites, each with its own format, deadline style, and geographic scope. CFP Compass provides a single, curated, searchable hub.

**Key business outcomes:**

- **For speakers:** Discover all open CFPs in one place, filter by topic and geography, track personal submission status (Interested → Submitted → Accepted), and receive deadline reminders before opportunities close.
- **For event organizers:** Submit CFP listings through a public, zero-friction form, no account required. Claim verified ownership of a listing with a single email verification step.
- **For the community:** A historical archive of past CFPs provides context for when events typically open, helping speakers plan their submission calendars.
- **For third-party integrators:** A public REST API (fronted by Azure API Management) enables conference aggregators, community bots, and developer tools to consume CFP data programmatically.

**What CFP Compass is not:** It is not a speaker profile platform, a conference scheduling or agenda tool, a CFP tracker for organizers, or a multi-tenant SaaS product. See `docs/architecture/non-goals-and-guardrails.md` for the complete boundary definition.

---

## Architectural Overview

CFP Compass is built on **.NET 10**, hosted on **Azure**, and orchestrated locally via **.NET Aspire 13.1**. The architecture follows two primary patterns:

### Clean Architecture (Onion)

The solution is structured as a Clean Architecture system, where dependencies point strictly inward:

```
Domain (innermost) → Application → Infrastructure / Api / Web / Workers (outermost)
```

- **CFPCompass.Domain**   Pure business logic: entities, value objects, domain events, and enums—zero external dependencies.
- **CFPCompass.Application**   Application services, interfaces, DTOs, validators (FluentValidation), and AutoMapper profiles. Defines the contracts that Infrastructure implements.
- **CFPCompass.Infrastructure**   EF Core data access, repository implementations, ACS email, Blob Storage, Redis caching, and ASP.NET Core Identity configuration.
- **CFPCompass.Api**   ASP.NET Core Web API entry point. Thin controller layer that delegates to Application services.
- **CFPCompass.Web**   Blazor Server (SSR) frontend. Thin UI layer consuming Application services directly (no separate API call from Web to API in the same process).
- **CFPCompass.Workers**   Azure Container Apps Jobs for scheduled background work (digest, reminders, expiry, region assignment).
- **CFPCompass.Functions**   Azure Functions (Consumption plan) consuming Azure Service Bus messages for asynchronous write processing.
- **CFPCompass.ServiceDefaults**   Shared configuration applied to all service projects: OpenTelemetry, health checks, resilience policies, and service discovery.
- **CFPCompass.AppHost**   .NET Aspire orchestrator for local development only. Not deployed to production.

### Event-Driven Write Architecture

All mutating operations (POST/PUT) follow an **event-driven, eventually consistent** pattern to decouple API responsiveness from Azure SQL Database cold-start latency:

1. The API receives and validates the request, then publishes an event to **Azure Service Bus** (Standard tier, topic-per-aggregate pattern).
2. The API immediately returns **HTTP 202 Accepted** with a `Location` header pointing to a polling endpoint (e.g., `GET /v1/submissions/{id}/status`).
3. An **Azure Function** (Consumption plan) subscribes to the Service Bus topic, processes the event, writes to Azure SQL, and updates the processing status record.
4. After a successful write, the `CacheInvalidationProcessor` function invalidates relevant APIM response cache entries and Redis keys.
5. Read operations (GET) are served from the **APIM response cache** (5-minute TTL for listings, 1-minute for detail pages), significantly reducing the impact of SQL cold starts.

This pattern provides: API responsiveness independent of DB availability, automatic buffering during SQL cold starts, built-in retry via Service Bus dead-letter queues, and independently scalable read and write paths.

### Azure Service Topology

The system is composed entirely of **managed Azure services** with no self-hosted virtual machines:

- **Azure Container Apps** (Consumption plan)  
  Blazor Server web app and ASP.NET Core Web API, each as independent Container Apps.
- **Azure Container Apps Jobs**  
  Scheduled background workers (cron-triggered).
- **Azure Functions** (Consumption plan)  
  Service Bus message processors.
- **Azure API Management** (Developer tier)  
  API gateway fronting all public REST endpoints.
- **Azure Front Door** (Standard)  
  Global CDN, SSL termination, and request routing.
- **Azure SQL Database** (Serverless, GP S0)  
  Primary relational data store.
- **Azure Managed Redis** (C0)  
  Distributed response cache and session state.
- **Azure Service Bus** (Standard tier)  
  Event-driven write messaging backbone.
- **Azure Communication Services**  
  Transactional and digest email delivery.
- **Azure Key Vault** (Standard)  
  All secrets, connection strings, and credentials.
- **Azure Container Registry** (Basic)  
  Docker image storage for CI/CD.
- **Azure Blob Storage** (GPv2, LRS)  
  Event logo image storage.

---

## Solution Context

CFP Compass sits at the intersection of several external systems and user groups:

**External users and systems feeding into CFP Compass:**

- **Public internet users** (browsers)  
  Speakers browsing and tracking CFPs; organizers submitting listings via the public submission form.
- **OAuth identity providers** (Google, GitHub, Microsoft)  
  Delegate authentication for speaker account creation and login.
- **Cloudflare Turnstile**  
  Invisible bot-protection challenge on the public CFP submission form (GDPR-compliant, no Google dependency).
- **Azure Front Door**  
  Sits in front of both the web app and the API, providing CDN caching, SSL termination, and DDoS protection at the edge.
- **Azure API Management**  
  API gateway that rate-limits, authenticates (subscription keys), and caches responses for all public REST API consumers.

**Systems consumed by CFP Compass:**

- **Azure SQL Database**  
  Primary data store for all CFP, user, tracking, and moderation data.
- **Azure Managed Redis**  
  Distributed cache for API responses, session state, and rate-limit counters.
- **Azure Service Bus**  
  Asynchronous message backbone for event-driven write operations.
- **Azure Communication Services**  
  Email delivery for transactional (approval, rejection, welcome) and scheduled (digest, reminders) emails.
- **Azure Blob Storage**  
  Persistent storage for event logo images uploaded with CFP submissions.
- **Azure Key Vault**  
  Secrets management, accessed via Managed Identity from Container Apps.
- **Azure Container Registry**  
  Source of Docker images pulled by Container Apps at deployment time.

**Third-party API consumers:**

- Conference aggregators, community bots, and developer tooling are consuming the public REST API via APIM subscription keys.

For a complete upstream/downstream system context diagram, see `docs/architecture/system-context-and-logical-components.md`.

---

## Key Requirements

The following requirements have a significant architectural impact and directly shaped the design decisions above:

| Requirement | Architectural Impact |
|-------------|---------------------|
| **Public CFP discovery must be SEO-indexable** | Blazor Server with SSR (not Blazor WebAssembly)   HTML is rendered server-side and crawlable |
| **Write operations must not be blocked by SQL cold starts** | Event-driven write pattern via Service Bus + Azure Functions (ADR-007) |
| **Read operations must be fast despite serverless SQL** | APIM response caching (ADR-011) with cache-tag invalidation on write completion |
| **Public submission form must be bot-resistant** | Cloudflare Turnstile (invisible challenge) + honeypot hybrid (ADR-012) |
| **API must support third-party integrations** | APIM gateway with subscription keys, rate limiting, and a developer portal |
| **Contract-first development discipline** | OpenAPI 3.1 specs approved before REST implementation; AsyncAPI 3.0.0 specs approved before Service Bus implementation (ADR-014) |
| **Admin accounts must not require a management UI for MVP** | Admin emails are defined in the environment configuration (Key Vault) and checked on every login |
| **English-only MVP with i18n future-proofing** | All UI strings go through `IStringLocalizer`; resource files are in place from day one (Decision 10) |
| **International geographic data** | ISO 3166-1 countries, ISO 3166-2 subdivisions, IANA time zones, UN M.49 world regions seeded in the database and validated on input |
| **Multi-service local development** | .NET Aspire 13.1 AppHost + ServiceDefaults for single-command startup and distributed tracing (ADR-013) |

---

## Security and Compliance

CFP Compass applies a layered security posture appropriate to a public-facing community web application:

### Authentication & Identity

- **ASP.NET Core Identity** (self-hosted) is the primary identity system chosen over Azure AD B2C for full control over passkey (WebAuthn/FIDO2) flows, UI customization, and cost predictability at MVP scale (ADR-003).
- **Passkeys (WebAuthn/FIDO2)** via `Fido2NetLib` are the preferred login mechanism, phishing-resistant by design.
- **Social login** (Google, GitHub, Microsoft OAuth) provides an alternative for users without passkey-capable devices.
- **Cookie authentication** (HttpOnly, Secure, SameSite=Strict) for the Blazor Server web app; no client-side token storage.
- The admin approves APIM subscription keys for all third-party API consumers before issuance.
- **Short-lived JWT tokens** (single-use) embedded in email links for submission editing (72h) and organizer claim verification (7 days).

### Authorization Model

| Role | Access |
|------|--------|
| Anonymous | Browse public CFP listing, view details, submit CFP form |
| Authenticated Speaker | Track CFPs, manage preferences, request API access |
| Verified Organizer | Edit owned CFP listings |
| Admin | Full dashboard, moderation, user management (email-list-based via Key Vault config) |
| API Consumer (read) | GET endpoints via APIM subscription key |
| API Consumer (read-write) | GET + POST + PUT endpoints via APIM subscription key |

### Key Security Controls

- **Secrets management:** All connection strings, OAuth credentials, and API keys are stored in **Azure Key Vault** and accessed via Managed Identity—no secrets in application config or environment variables at runtime.
- **Rate limiting:** APIM enforces per-subscription-key rate limits (100 req/min for reads, 10 req/min for writes). App-level rate limiting (ASP.NET Core middleware) provides defense-in-depth for web app endpoints (login, registration, submission).
- **Input validation:** FluentValidation at the Application layer; ISO/IANA/UN M.49 code validation against seeded lookup tables; HTML sanitization via `HtmlSanitizer` for rich text fields.
- **Bot protection:** Cloudflare Turnstile (invisible challenge, GDPR-compliant) + honeypot on the public submission form.
- **CORS:** Strict allow-list restricted to `cfpcompass.com` and `www.cfpcompass.com` for the web app; APIM handles CORS separately for API consumers.
- **Audit logging:** All admin actions, moderation state transitions, authentication events, and API key operations are written to Azure Log Analytics (structured JSON) and an `AuditLog` SQL table.
- **Content security:** Blazor auto-encodes output by default; HTML sanitization is applied to any field accepting user-authored rich text.
- **Account lockout:** 5 failed login attempts trigger a 15-minute lockout.

---

## Non-Functional Requirements

### Availability

- **Target:** 99.5% uptime for the web app and API (aligned with Azure Container Apps + APIM Developer tier SLAs).
- **Degraded mode:** APIM response cache ensures read endpoints remain available (serving cached responses) even when Azure SQL is paused or cold-starting. Write operations queue in Service Bus during transient failures.
- **Azure Communication Services** failures are treated as `Degraded` (not `Unhealthy`). The API remains operational, and the email queue is for retry.
- **Health checks:** All services expose the `GET /health` (aggregate dependencies) and `GET /alive` (liveness) endpoints, which are consumed by Azure Container Apps startup, liveness, and readiness probes.

### Performance

- **Read latency target:** Public CFP listing pages served within 500ms under normal load (APIM response cache eliminates SQL round-trips for cached responses).
- **Write latency target:** API returns HTTP 202 within 200ms of request receipt (publishes to Service Bus and returns immediately; DB write is asynchronous).
- **Cache strategy:**
  - APIM response cache: 5-minute TTL for listing pages, 1-minute for detail pages, 60-minute for topics/categories, 24-hour for country/region reference data.
  - Azure Managed Redis (C0): Distributed cache for session state and app-level response caching.
  - `IMemoryCache`: In-process reference data (countries, topics) refreshed every 24 hours.

### Scalability

- **Container Apps** scale out automatically on HTTP request volume (Consumption plan).
- **Azure Functions** scale to zero between messages and scale out per message during bursts.
- **Azure SQL Serverless** auto-scales vCores within configured min/max bounds; auto-pauses after 60 minutes of inactivity (cost optimization for MVP).
- **APIM Developer tier** provides dedicated capacity with no cold-start upgrade path to Standard V2 when traffic and cost justify it.

### Maintainability

- **Contract-first development** (ADR-014): OpenAPI 3.1 and AsyncAPI 3.0.0 specs approved before implementation. APIM imports the OpenAPI spec directly, and the contract and gateway stay in sync.
- **Clean Architecture** enforces dependency rules that make layers independently testable and replaceable.
- **.NET Aspire ServiceDefaults** provides consistent OpenTelemetry, health checks, and resilience policies across all service projects from a single shared configuration.
- **Terraform IaC** for all Azure infrastructure, repeatable, version-controlled, environment-parameterized (dev/staging/prod).
- **GitHub Actions CI/CD**: Build + test on PR; deploy to dev, staging, and prod on branch merges.

### Observability

- **Distributed tracing:** OpenTelemetry via ServiceDefaults propagates W3C `traceparent` context across HTTP, Service Bus, and Azure SDK calls. A single trace ID spans the full write path: API → Service Bus → Function → SQL.
- **Structured logging:** Serilog with JSON output; logs correlated with trace IDs.
- **Metrics:** Runtime (CPU, memory, GC), HTTP request rates, and custom application metrics exported via OTLP.
- **Local development:** Aspire Dashboard at `https://localhost:18888`   real-time log, trace, and metrics viewer; no additional setup.
- **Production:** OpenTelemetry exporters send telemetry to Azure Monitor / Application Insights and Azure Log Analytics configuration-only switch from dev.

---

## Appendices / References

| Document | Location | Purpose |
|----------|----------|---------|
| Architecture Specifications | `docs/architecture/architecture-specifications.md` | Component-level design, communication patterns, state management, and failure modes |
| System Context & Logical Components | `docs/architecture/system-context-and-logical-components.md` | Upstream/downstream systems, logical component model, system context diagram |
| Non-Goals and Guardrails | `docs/architecture/non-goals-and-guardrails.md` | Explicit scope boundaries, architectural guardrails, and accepted trade-offs |
| Architecture Decision Records | `.squad/decisions.md` | Full ADR log (ADR-001 through ADR-014) |
| Canonical Architecture | `.squad/architecture.md` | Authoritative system architecture reference (maintained by Lead Architect) |
| OpenAPI Spec | `docs/api/openapi/cfp-compass-api-v1.yaml` | REST API contract (OpenAPI 3.1) |
| AsyncAPI Specs | `docs/api/asyncapi/` | Service Bus event contracts (AsyncAPI 3.0.0) |
