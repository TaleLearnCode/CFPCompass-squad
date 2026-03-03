---
title: Architecture Specifications
description: Architectural design specifications for CFP Compass — components, communication patterns, state management, and failure resilience.
tags:
  - architecture-specifications
  - architecture
  - components
  - resilience
  - event-driven
  - messaging
  - state-management
  - domain-service
---

# Architecture Specifications: CFP Compass

## Purpose and Scope

### Purpose

This document specifies the architectural design of CFP Compass — how its nine solution projects are organized, how they communicate, what state they maintain, and how they respond to failure. It translates the logical component model (see System Context & Logical Components) into an implementable architectural design.

### Intended Audience

- **Software Architects** — validating that implementation decisions conform to architectural intent
- **Backend Developers** — understanding component responsibilities, interfaces, and dependency rules before implementing
- **Platform / DevOps Engineers** — understanding service deployment boundaries and inter-service communication patterns
- **Testers** — understanding failure modes and resilience mechanisms to design targeted test scenarios

### Document Scope

**Included topics:**
- Solution project structure and Clean Architecture layer responsibilities
- Component-to-Azure-artifact mapping
- Synchronous and asynchronous communication patterns
- Service Bus topic topology and delivery guarantees
- State management: Azure SQL, Redis, and in-memory caches
- Cross-cutting concerns: observability, security, and resilience principles
- Expected failure modes and mitigation strategies
- Integration and messaging architecture

**Excluded topics:**
- Deployment procedures and infrastructure provisioning (see Infrastructure Architecture / Terraform modules in `infra/`)
- Operational runbooks and alert configuration (see Operations Guide)
- Detailed security controls and threat model (see `docs/architecture/architecture-guide.md` §Security and Compliance, and `.squad/architecture.md` §13)
- OpenAPI and AsyncAPI message schemas (see `docs/api/openapi/` and `docs/api/asyncapi/`)
- API endpoint listing and authentication model (see Architecture Guide and API Contracts)

### Companion Documents

- **Architecture Guide** (`docs/architecture-guide.md`) — High-level overview, business purpose, and key requirements
- **System Context & Logical Components** (`docs/architecture/system-context-and-logical-components.md`) — Upstream/downstream systems, logical component model
- **Non-Goals and Guardrails** (`docs/architecture/non-goals-and-guardrails.md`) — Scope boundaries and accepted trade-offs
- **ADR Log** (`.squad/decisions.md`) — Decision rationale for ADR-001 through ADR-014

---

## Architectural Constraints and Assumptions

### Architectural Constraints

The following constraints are fixed boundaries. Changing any of them requires an explicit architectural decision record and re-evaluation of the affected design sections.

| # | Constraint | Consequence if Violated |
|---|-----------|------------------------|
| C1 | **Domain has zero external dependencies.** `CFPCompass.Domain` references no NuGet packages except the standard BCL. | Violating this introduces coupling that breaks the Clean Architecture layering and makes domain logic untestable in isolation. |
| C2 | **Application layer defines interfaces; Infrastructure implements them.** No direct infrastructure references in Application. | Infrastructure implementation details would leak into the application contract, preventing independent swappability of storage, email, or caching providers. |
| C3 | **Web layer must not access the database directly.** `CFPCompass.Web` consumes Application services; it does not reference `CFPCompass.Infrastructure` or call the database. | Direct DB access from Web creates an uncontrolled second write path and bypasses all Application-layer validation and business rules. |
| C4 | **All write operations (POST/PUT) from the public API are event-driven.** No synchronous database writes from API controllers on the write path. (ADR-007) | Synchronous writes reintroduce tight coupling to Azure SQL cold starts and remove the buffering benefits of Service Bus dead-letter queues. |
| C5 | **Contract-first discipline is mandatory.** No REST endpoint or Service Bus topic may be implemented without an approved OpenAPI 3.1 or AsyncAPI 3.0.0 spec respectively. (ADR-014) | Undocumented contracts accumulate technical debt, prevent meaningful API review, and break APIM's spec-import integration. |
| C6 | **All service projects call `AddServiceDefaults()` at startup.** OpenTelemetry, health checks, and resilience are applied uniformly. (ADR-013) | Missing `AddServiceDefaults()` creates blind spots in distributed tracing and inconsistent health check behavior across services. |
| C7 | **`CFPCompass.AppHost` is never deployed to production.** It is a dev/test-only orchestrator. | AppHost carries dev-environment abstractions and configuration that are inappropriate for production. |
| C8 | **Azure Service Bus Standard tier; topic-per-aggregate pattern.** (ADR-008) | Using Basic tier (queues only, no topics) would lose fan-out capability, preventing the cache-invalidation and notification subscription patterns. |

### Assumptions

| # | Assumption | Impact if Wrong |
|---|-----------|----------------|
| A1 | Azure SQL Serverless cold starts are ≤ 15 seconds under normal MVP load. | Longer cold starts would increase the polling window for write operations and could cause health check timeouts during startup. |
| A2 | Azure Service Bus Standard tier provides at-least-once delivery and dead-letter queues are available for all topics. | Consumers must handle duplicate messages idempotently; if dead-lettering were unavailable, failed messages would be silently lost. |
| A3 | Azure Container Apps supports WebSocket connections for SignalR (used by Blazor Server). | If WebSocket support were removed or limited, Blazor Server would degrade to long-polling, increasing latency and connection overhead. |
| A4 | APIM Developer tier response cache is invalidated correctly via the cache-purge API called by `CacheInvalidationProcessor`. | If cache purge fails silently, stale data persists in APIM cache for up to the TTL window (max 5 minutes for listings). |
| A5 | Azure Managed Redis C0 is sufficient for MVP cache volume (response caching + session state for expected MVP user load). | C0 supports 1 GB cache size and 256 MB/s bandwidth; exceeding this requires upgrade to C1 or higher. |
| A6 | Cloudflare Turnstile verification API is reachable from the API Container App at submission time. | If Turnstile is unreachable, the submission endpoint must decide between fail-open (allow submission, log warning) or fail-closed (reject). Current stance: fail-closed with clear error message. |
| A7 | OAuth providers (Google, GitHub, Microsoft) are treated as external dependencies with no SLA guarantee from CFP Compass. | Social login unavailability does not affect password or passkey login flows. |
| A8 | Azure Functions Consumption plan on .NET 10 isolated worker process supports the required Azure Service Bus trigger binding semantics. | Trigger binding changes in future runtime versions require `host.json` or code-level adaptation. |

---

## System Architecture Overview

### Runtime Positioning

CFP Compass operates as a multi-component system with distinct read and write paths:

**Read path (synchronous):**
```
Internet → Azure Front Door → APIM (response cache) → Container App (API) → Azure SQL / Redis
Internet → Azure Front Door → Container App (Web) → Application Services → Azure SQL / Redis
```

**Write path (asynchronous):**
```
Internet → Azure Front Door → APIM → Container App (API)
  → validates input
  → publishes event to Azure Service Bus topic
  → returns HTTP 202 Accepted + Location header

Azure Service Bus topic → Azure Functions (Consumption)
  → processes event
  → writes to Azure SQL
  → updates processing status record
  → publishes to cache-invalidation topic

cache-invalidation topic → CacheInvalidationProcessor Azure Function
  → purges APIM response cache
  → invalidates Redis keys
```

**Scheduled work path:**
```
Azure Container Apps Jobs (cron-triggered)
  → Application Services
  → Azure SQL (reads + writes)
  → ACS Email (via IEmailService)
```

### Component-to-Artifact Mapping

| Logical Component | Deployment Artifact | Azure Service |
|-------------------|--------------------|-----------------------|
| Web Frontend (Blazor Server) | `CFPCompass.Web` project → `cfpcompass-web` Docker image | Azure Container App #1 |
| API Host (ASP.NET Core Web API) | `CFPCompass.Api` project → `cfpcompass-api` Docker image | Azure Container App #2 |
| Background Workers | `CFPCompass.Workers` project → `cfpcompass-workers` Docker image | Azure Container Apps Job (cron) |
| Service Bus Processors | `CFPCompass.Functions` project → `cfpcompass-functions` Docker image | Azure Functions (Consumption plan) |
| Domain Logic | `CFPCompass.Domain` class library | Compiled into Api, Web, Workers, Functions |
| Application Services | `CFPCompass.Application` class library | Compiled into Api, Web, Workers, Functions |
| Data Access / Infrastructure | `CFPCompass.Infrastructure` class library | Compiled into Api, Workers, Functions |
| Shared Observability | `CFPCompass.ServiceDefaults` class library | Compiled into Api, Web, Workers, Functions |
| Local Dev Orchestrator | `CFPCompass.AppHost` — dev only | Not deployed |
| Primary Data Store | EF Core → Azure SQL Database Serverless | Azure SQL Database (GP S0) |
| Response Cache / Session | `IDistributedCache` → StackExchange.Redis | Azure Managed Redis (C0) |
| Reference Data Cache | `IMemoryCache` | In-process (Api, Workers) |
| Message Broker | Azure Service Bus SDK | Azure Service Bus Standard |
| Email Delivery | `Azure.Communication.Email` SDK | Azure Communication Services |
| Image Storage | Azure Blob Storage SDK | Azure Storage Account (GPv2, LRS) |
| Secrets | Azure Key Vault SDK (Managed Identity) | Azure Key Vault Standard |
| API Gateway | APIM Developer tier | Azure API Management |
| CDN / Edge | Azure Front Door Standard | Azure Front Door |

---

## Component Architecture Specifications

### CFPCompass.Domain

#### Responsibility
`CFPCompass.Domain` is the innermost layer of the Clean Architecture. It defines the business entities, value objects, domain events, and enumerations that represent the core CFP Compass domain. It is responsible for expressing business invariants and domain concepts — nothing more. It is NOT responsible for persistence, communication, or application orchestration.

#### Inputs and Outputs
- **Inputs:** Instantiated by Application layer services; entities receive method calls to execute business operations (e.g., `cfp.Approve()`, `cfp.Archive()`).
- **Outputs:** Returns domain objects and raises domain events (e.g., `CfpApproved`, `ClaimRequested`). Domain events are collected in memory and dispatched by the Application layer.
- **Key entities:** `Cfp`, `User`, `UserCfpTracking`, `ModerationAction`, `ClaimRequest`, `NotificationPreference`, `ApiKeyRequest`, `EmailLog`, `Country`, `Subdivision`, `Category`, `Topic`.
- **Key value objects:** `CountryCode` (ISO 3166-1), `SubdivisionCode` (ISO 3166-2), `IanaTimeZone`, `WorldRegion` (UN M.49).

#### Dependencies
- **Hard dependencies:** None. Only BCL (System.*).
- **Dependency direction:** No references to Application, Infrastructure, or any Azure SDK.

#### Configuration
No runtime configuration. All behavior is determined by the code and entity state.

---

### CFPCompass.Application

#### Responsibility
`CFPCompass.Application` orchestrates domain operations. It defines service interfaces (`ICfpService`, `IEmailService`, `ICacheService`, etc.), implements application services that coordinate domain entities and cross-cutting concerns, defines DTOs for request/response transfer, and hosts FluentValidation validators. It is NOT responsible for infrastructure implementation or HTTP concerns.

#### Inputs and Outputs
- **Inputs:** Called by `CFPCompass.Api`, `CFPCompass.Web`, `CFPCompass.Workers`, and `CFPCompass.Functions` via registered DI interfaces.
- **Outputs:** Returns DTOs to callers; raises domain events that Infrastructure (via outbox or direct dispatch) forwards to Service Bus or email services.
- **DTOs:** Request/response models for all CFP, user, submission, tracking, and admin operations.
- **Validators:** FluentValidation validators for all incoming request DTOs — country code, subdivision, IANA TZ, URL format, file size.
- **Mapping:** AutoMapper profiles map between domain entities and DTOs.

#### Dependencies
- **Hard:** `CFPCompass.Domain`.
- **Soft (via interfaces):** `ICfpRepository`, `IUserRepository`, `IEmailService`, `ICacheService`, `IServiceBusPublisher`, `IBlobStorageService` — all implemented in Infrastructure.
- **Failure handling:** If a required service (e.g., IServiceBusPublisher) throws, the Application service propagates the exception to the calling API controller, which returns an appropriate HTTP 5xx.

#### Configuration
- FluentValidation assembly scanning configured at startup in Api/Web/Workers/Functions.
- AutoMapper assembly scanning configured at startup.

---

### CFPCompass.Infrastructure

#### Responsibility
`CFPCompass.Infrastructure` implements all interfaces defined in Application. It owns the EF Core `DbContext`, repository implementations, ACS email integration, Azure Blob Storage client, Redis cache service, and ASP.NET Core Identity configuration. It is NOT responsible for any business logic — it translates domain operations into infrastructure calls.

#### Inputs and Outputs
- **Inputs:** Method calls from Application services via injected interfaces.
- **Outputs:** Persisted data (Azure SQL via EF Core), cached values (Redis), sent emails (ACS), stored blobs (Azure Storage), published messages (Azure Service Bus).
- **EF Core patterns:** Repository pattern over `CfpCompassDbContext`; Specification pattern for complex query composition; global query filters for soft-delete (`IsArchived`); value converters for string-stored enums; interceptors for `CreatedAt`/`UpdatedAt` auto-stamping.

#### Dependencies
- **Hard:** `CFPCompass.Application` (implements its interfaces); EF Core 10; `Azure.Communication.Email`; `StackExchange.Redis`; `Azure.Storage.Blobs`; `Azure.Messaging.ServiceBus`; `Fido2NetLib`; `Microsoft.AspNetCore.Identity.EntityFrameworkCore`.
- **Failure handling:** EF Core leverages Polly retry policies (configured via `AddServiceDefaults`) for transient SQL errors. Redis and Service Bus use similar Polly policies. Blob Storage operations include retry with exponential backoff.

#### Configuration
- Connection strings injected from Azure Key Vault via Managed Identity (production) or Aspire resource abstractions (development).
- Redis, Service Bus, and SQL connections use Aspire integration packages (`Aspire.Azure.*`) for automatic health check registration and connection resilience.

---

### CFPCompass.Api

#### Responsibility
`CFPCompass.Api` is the public-facing ASP.NET Core Web API host. It receives HTTP requests (via APIM for external consumers), validates them, delegates to Application services, and returns HTTP responses. On the write path, it publishes events to Service Bus and returns HTTP 202. It is NOT responsible for business logic — it is a thin HTTP adapter over Application services.

#### Inputs and Outputs
- **Inputs:** HTTP requests from APIM (external API consumers) and `CFPCompass.Web` (internal Blazor Server calls via HttpClient or direct service injection).
- **Outputs:** HTTP responses (JSON); Service Bus published events on POST/PUT.
- **Endpoints:** Versioned under `/v1/` — CFPs, metadata (topics, categories, countries, regions), user/speaker operations, submissions, claims, admin operations.
- **Async write response:** `HTTP 202 Accepted` + `Location` header + `{ "statusUrl": "...", "id": "..." }` body.

#### Dependencies
- **Hard:** `CFPCompass.Application`, `CFPCompass.Infrastructure`, `CFPCompass.ServiceDefaults`.
- **Soft:** Azure Service Bus (publish only on write path), Azure SQL (via Infrastructure), Azure Managed Redis (via Infrastructure).

#### Configuration
- CORS restricted to `cfpcompass.com` origins.
- ASP.NET Core Rate Limiting middleware for login (10/15min per IP), registration (5/hr per IP), submission (10/hr per IP).
- Cloudflare Turnstile server-side token verification on `POST /v1/submissions`.
- OpenAPI spec served via Scalar for developer convenience (canonical spec lives in `docs/api/openapi/`).
- `Program.cs` calls `builder.AddServiceDefaults()` for OpenTelemetry, health checks, and resilience.

---

### CFPCompass.Web

#### Responsibility
`CFPCompass.Web` is the Blazor Server (SSR) frontend. It renders all public-facing pages and authenticated speaker/admin UI. It directly injects and calls Application services (no HTTP round-trip to the API for the same-process Web app). It is NOT responsible for data access — all data flows through Application services.

#### Inputs and Outputs
- **Inputs:** HTTP requests from browsers (routed via Azure Front Door). User interactions handled server-side via SignalR (Blazor Server).
- **Outputs:** Rendered HTML (SSR for initial load + SignalR-driven updates for interactive components); JavaScript interop only for passkey (WebAuthn) flows.
- **Pages:** Home (CFP listing), CfpDetail, PastCfps, Submit, EditSubmission, ClaimCfp, Account (Register/Login/Settings), Dashboard (MyTracking, ApiAccess), Admin (Dashboard, PendingSubmissions, ManageUsers, etc.).
- **i18n:** All user-facing strings via `IStringLocalizer<T>`. Resource files in `Resources/`. English-only for MVP; additional locales added by adding `.resx` files without code changes.

#### Dependencies
- **Hard:** `CFPCompass.Application`, `CFPCompass.ServiceDefaults`.
- **Soft:** Application services resolve Infrastructure implementations via DI — Web has no direct reference to Infrastructure.
- **SignalR:** Azure Container Apps WebSocket support required for Blazor Server interactive mode.

#### Configuration
- Bootstrap 5 CSS framework. No JavaScript framework — Blazor handles all interactivity.
- `IJSRuntime` used only for WebAuthn passkey ceremonies.
- `Program.cs` calls `builder.AddServiceDefaults()`.
- Localization configured for English (`en`) culture as MVP default.

---

### CFPCompass.Workers

#### Responsibility
`CFPCompass.Workers` implements the scheduled background jobs that run on Azure Container Apps Jobs (cron-triggered). Each job uses Application services identically to how the API and Web layers use them. It is NOT a long-running service — each job invocation starts, executes its work, and exits.

#### Inputs and Outputs
- **Inputs:** Cron schedule triggers from Azure Container Apps Jobs runtime.
- **Outputs:** Azure SQL writes (via Application services + Infrastructure), ACS emails (via `IEmailService`).
- **Jobs:**
  - `CfpExpiryJob` — daily midnight UTC: archives CFPs > 7 days past deadline.
  - `DeadlineReminderJob` — daily 6 AM UTC: sends reminders for tracked CFPs at 7, 3, 1 day(s) before deadline.
  - `WeeklyDigestJob` — Sunday 8 AM UTC: sends new + closing-soon CFP digest to opted-in users.
  - `WorldRegionAssignmentJob` — every 6 hours: assigns UN M.49 world region to CFPs with null WorldRegion.

#### Dependencies
- **Hard:** `CFPCompass.Application`, `CFPCompass.Infrastructure`, `CFPCompass.ServiceDefaults`.
- **Soft:** Azure SQL (read + write), ACS Email, Azure Managed Redis.
- **Failure handling:** Polly retry policies from ServiceDefaults. Job execution failures are logged; Container Apps Jobs retry failed executions per configured retry policy.

#### Configuration
- Each job runs as a separate Container Apps Job execution (isolated process per invocation).
- Cron expressions configured in Terraform Container Apps Jobs definition.

---

### CFPCompass.Functions

#### Responsibility
`CFPCompass.Functions` hosts the Azure Functions that process Service Bus messages on the write path. Each Function subscribes to a specific Service Bus topic and processes the corresponding event. Functions use the same Application services as all other layers. They are NOT long-running — each invocation processes one message batch and exits.

#### Inputs and Outputs
- **Inputs:** Azure Service Bus messages (Service Bus trigger bindings per topic).
- **Outputs:** Azure SQL writes, Redis cache invalidation, APIM cache purge API calls, ACS email triggers (via Application services).
- **Processors:**
  - `CfpSubmissionProcessor` → `cfp-submissions` topic: validates and persists new/updated CFP submissions, triggers duplicate detection.
  - `UserAccountProcessor` → `user-accounts` topic: processes account registration and profile update events.
  - `NotificationProcessor` → `notifications` topic: triggers ACS email sends for transactional notifications.
  - `StatusUpdateProcessor` → `processing-status` topic: updates submission processing status records for caller polling.
  - `CacheInvalidationProcessor` → `cache-invalidation` topic: purges APIM response cache and invalidates Redis keys.
- **Health check:** `HealthCheckFunction` (HTTP trigger at `GET /api/health`) performs SQL + Service Bus dependency checks.

#### Dependencies
- **Hard:** `CFPCompass.Application`, `CFPCompass.Infrastructure`, `CFPCompass.ServiceDefaults`.
- **Runtime:** .NET 10 isolated worker process model.
- **Failure handling:** Service Bus trigger bindings retry failed processing up to 3 times (exponential backoff). After 3 failures, the message is moved to the dead-letter queue for manual review.

#### Configuration
- `host.json` configures Service Bus trigger retry policy, max concurrency, and lock renewal.
- Aspire integration packages provide connection string injection from Key Vault in production.

---

### CFPCompass.ServiceDefaults

#### Responsibility
`CFPCompass.ServiceDefaults` is a shared class library consumed by all service projects (Api, Web, Workers, Functions). Its single exported extension method — `AddServiceDefaults()` — applies a consistent baseline of OpenTelemetry (traces, metrics, logs), health check registration, Polly resilience policies, and service discovery to any service that calls it. It is NOT a deployable unit.

#### Inputs and Outputs
- **Inputs:** Called once per service at startup via `builder.AddServiceDefaults()`.
- **Outputs:** Configured `IServiceCollection` with OpenTelemetry exporters, health check endpoints, and resilience handlers.
- **Local dev:** OTLP exporter targets Aspire Dashboard.
- **Production:** OTLP exporter targets Azure Monitor / Application Insights (config-controlled).

#### Dependencies
- **Hard:** OpenTelemetry .NET SDK, Aspire workload packages, `Microsoft.Extensions.Diagnostics.HealthChecks`.

---

### CFPCompass.AppHost

#### Responsibility
`CFPCompass.AppHost` is the .NET Aspire orchestrator for local development. It declares the full service topology using Aspire's resource model (`AddProject<T>()`, `AddAzureRedis()`, `AddAzureServiceBus()`, `AddAzureSqlServer()`) and launches all services and containers with a single `dotnet run` command. **It is never deployed to production.**

#### Inputs and Outputs
- **Inputs:** `dotnet run` from developer workstation.
- **Outputs:** Running local instances of Api, Web, Workers, Functions; containerized Redis and SQL Server; Aspire Dashboard at `https://localhost:18888`.

#### Dependencies
- .NET Aspire 13.1 workload (`dotnet workload install aspire`).
- Docker Desktop for containerized dependencies.

---

## Component Communication Patterns

### Synchronous Communication

**Web App → Application Services (in-process):**
The Blazor Server Web app calls Application services directly via DI-injected interfaces. No HTTP round-trip. Response is synchronous; Blazor Server component awaits the result.

**External API Consumer → APIM → API Host (HTTP):**
Third-party consumers call the public REST API via APIM. APIM validates subscription keys, applies rate limits, checks the response cache, and (on cache miss) forwards to the API Container App. Timeout at APIM: 30 seconds. On API unavailability, APIM returns 503.

**Functions → Azure SQL (HTTP/TDS):**
Azure Functions write to SQL synchronously within the Function execution. Connection pool managed by EF Core. Retry policy (Polly): 3 retries with exponential backoff (2s, 4s, 8s) for transient errors.

**CacheInvalidationProcessor → APIM cache purge API (HTTP):**
After a successful write, `CacheInvalidationProcessor` calls the APIM REST API to purge cached responses for affected cache keys. This is a best-effort, synchronous HTTP call within the Function execution. Failure is logged but does not fail the Function — stale cache will expire within TTL.

**Workers → Application Services (in-process):**
Background jobs call Application services directly — same pattern as Web. Services resolve Infrastructure implementations via DI.

### Asynchronous Communication

CFP Compass uses **Azure Service Bus Standard tier** with **topic-per-aggregate** pattern for all event-driven communication.

**Service Bus Topics and Consumers:**

| Topic | Producer | Consumer Function | Purpose |
|-------|----------|------------------|---------|
| `cfp-submissions` | `CFPCompass.Api` | `CfpSubmissionProcessor` | New/updated CFP writes |
| `user-accounts` | `CFPCompass.Api` | `UserAccountProcessor` | Account registration/updates |
| `notifications` | `CfpSubmissionProcessor`, `UserAccountProcessor` | `NotificationProcessor` | Trigger transactional emails |
| `processing-status` | `CfpSubmissionProcessor`, `UserAccountProcessor` | `StatusUpdateProcessor` | Update polling status records |
| `cache-invalidation` | `CfpSubmissionProcessor` | `CacheInvalidationProcessor` | Purge APIM + Redis caches |

**Event Flow (CFP Submission example):**
```
1. POST /v1/cfps
   → API validates input
   → API publishes CfpSubmissionCreated to `cfp-submissions` topic
   → API returns HTTP 202 with Location header

2. cfp-submissions topic → CfpSubmissionProcessor
   → Persists Cfp entity to Azure SQL
   → Runs duplicate detection (URL match check)
   → Publishes CfpSubmissionReceived to `processing-status` topic
   → Publishes CfpSubmissionNotification to `notifications` topic

3. processing-status topic → StatusUpdateProcessor
   → Updates ProcessingStatus record (Pending → Completed | Failed)
   → Caller's polling endpoint reflects updated status

4. notifications topic → NotificationProcessor
   → Renders ACS email template
   → Sends via Azure Communication Services

5. (On admin approval) CfpSubmissionProcessor publishes to `cache-invalidation` topic
   → CacheInvalidationProcessor purges APIM listing cache + Redis keys
```

### Message Delivery Guarantees

**Guarantee: At-least-once delivery.**

Azure Service Bus Standard tier guarantees at-least-once delivery per subscription. Messages may be delivered more than once in failure/retry scenarios. All Function processors are designed for **idempotency**: they check for existing records before inserting and use conditional updates. The `CfpSubmissionProcessor` checks for an existing `Cfp` with the same submission ID before inserting; `CacheInvalidationProcessor` cache purge operations are inherently idempotent (purging an already-purged key is a no-op).

**Dead-letter queue:** After 3 delivery attempts (default Service Bus retry), failed messages are moved to the dead-letter sub-queue. The operations team reviews dead-lettered messages via Azure Portal or a dedicated monitoring alert.

**Message TTL:** 24 hours. Messages not processed within 24 hours are automatically expired (moved to dead-letter). In practice, Functions process messages within seconds to minutes.

**Ordering:** Per-session ordering is not required for CFP Compass's MVP write patterns. Messages within the same topic are processed in received order on a best-effort basis, but the system does not depend on strict ordering between independent aggregate writes.

---

## State Management Architecture

### Stateful Components

| Component | State Maintained | Why |
|-----------|-----------------|-----|
| Azure SQL Database | All persistent domain state | Authoritative source of truth for CFPs, users, tracking, moderation, status records |
| Azure Managed Redis (C0) | API response cache, session state, app-level rate-limit counters | Distributed cache shared across Container App instances |
| `IMemoryCache` (in-process, Api + Workers) | Reference data: countries, subdivisions, topics, categories | High-read-frequency, rarely-changing data; avoids SQL round-trips per request |
| Azure Service Bus | In-flight messages (unacknowledged events) | Buffers events between API publish and Function processing |
| APIM response cache | Cached HTTP responses for public GET endpoints | Edge cache to serve listings without SQL cold-start latency |

### State Storage and Lifecycle

**Azure SQL Database (Primary State):**
- **What:** All CFP entities, user accounts, tracking records, moderation actions, claim requests, email logs, notification preferences, API key records, processing status records, audit log.
- **Lifetime:** Persistent; no automatic expiry. Soft-delete (`IsArchived` global query filter) used instead of hard delete for CFPs and users.
- **Recreation:** Not automatically derived; canonical source of truth. Backups via Azure SQL automated backup (point-in-time restore, 7-day retention for Serverless GP tier).
- **On restart:** State fully persisted in Azure SQL; no in-memory state is lost.

**Azure Managed Redis (Distributed Cache):**
- **What:** API response cache keys (JSON-serialized response bodies), ASP.NET Core Data Protection key ring, session state, app-level rate-limit counters.
- **Lifetime:** TTL-based. API cache keys: 5 minutes (listings), 1 minute (detail), 60 minutes (reference data). Session state: 14-day sliding expiration. Rate-limit counters: per-window TTL.
- **Recreation:** Fully derived from Azure SQL. On Redis flush or restart, cache repopulates on next request (cold hit). No data loss — only transient latency increase.
- **On restart:** Azure Managed Redis is a managed service; restart is transparent. On C0, there is a single replica; during Azure-initiated maintenance, brief cache unavailability is possible. The application handles `RedisConnectionException` gracefully — reads fall through to SQL (cache miss); writes proceed to SQL directly.

**In-Process `IMemoryCache` (Reference Data):**
- **What:** ISO 3166-1 country list, ISO 3166-2 subdivision list, topic list, category list.
- **Lifetime:** 24-hour absolute TTL. Refreshed on next request after expiry (lazy refresh). Admin-triggerable manual refresh endpoint.
- **Recreation:** Fully derived from Azure SQL seeded reference tables.
- **On restart:** Cache is empty on cold start; repopulates from SQL on first request. No data loss.

**Service Bus In-Flight State:**
- **What:** Messages published by API controllers awaiting Function processing.
- **Lifetime:** Up to 24 hours (message TTL) or until processed/dead-lettered.
- **On restart:** Service Bus retains messages. Container App or Function restart does not lose in-flight messages. Unacknowledged messages are re-delivered (at-least-once guarantee).

### State Consistency and Synchronization

**Consistency model: Eventual consistency for write operations.**

The write path is intentionally eventually consistent:
1. After API returns HTTP 202, the CFP is not yet in Azure SQL.
2. The caller polls `GET /v1/submissions/{id}/status` until status transitions to `Completed`.
3. Once `Completed`, the CFP is in SQL and (after cache invalidation) available via GET endpoints.

**Cache invalidation coordination:**
- APIM response cache and Redis keys are invalidated by `CacheInvalidationProcessor` after successful writes.
- APIM cache purge is best-effort (logged on failure; stale responses expire within TTL).
- Redis invalidation uses `DEL` on specific keys; key naming convention ensures correct targeting.

**Conflict resolution:**
- **Last-write-wins** for entity updates (EF Core `UpdatedAt` tracking).
- **Idempotent Function processors** prevent duplicate inserts (check before insert, conditional update).
- **No distributed transaction** spans the API → Service Bus → Function write path. Partial failures (API publishes event but Function fails to write) are recovered via Service Bus retry and dead-letter queue review.

---

## Cross-Cutting Concerns

### Observability Principles

All service projects share a consistent observability baseline via `CFPCompass.ServiceDefaults`:

- **Structured logging:** Serilog with JSON output; all log entries include `TraceId`, `SpanId`, `CorrelationId`, `UserId` (where authenticated), `RequestPath`, and `Environment`.
- **Distributed tracing:** OpenTelemetry `System.Diagnostics.Activity` with W3C `traceparent` propagation. Trace context flows: HTTP (Api) → Service Bus message headers → Function → SQL. A single `TraceId` spans the full write path.
- **Metrics:** HTTP request rate, latency percentiles (p50/p95/p99), error rate, Service Bus message processing latency, and SQL query duration. Exported via OTLP.
- **Health checks:** `GET /health` (aggregate dependency status) and `GET /alive` (liveness) on all Container App services. `GET /api/health` on Functions.
- **Local development:** OTLP exporters target the Aspire Dashboard (`https://localhost:18888`).
- **Production:** OTLP exporters target Azure Monitor / Application Insights and Azure Log Analytics — switched via `APPLICATIONINSIGHTS_CONNECTION_STRING` environment variable (sourced from Key Vault).

### Security Principles

- **Authentication:** ASP.NET Core Identity (cookie-based for Web; subscription key via APIM for API consumers). Passkeys (WebAuthn/FIDO2) via `Fido2NetLib` as the preferred auth mechanism.
- **Authorization:** Role claims checked at Application service layer and API controller level. Admin role is dynamically assigned on login based on Key Vault-stored email list.
- **Secrets:** Azure Key Vault accessed via Managed Identity. No secrets in code, config files, or environment variables at runtime.
- **Data protection:** HTTPS enforced at Azure Front Door (TLS termination). All secrets encrypted at rest in Key Vault. Azure SQL and Redis use Azure-managed encryption at rest.
- **Input validation:** FluentValidation at Application layer (before any domain operation). API model binding provides a secondary validation layer. HTML sanitization (`HtmlSanitizer`) applied to rich-text fields.
- **Audit trail:** Admin actions and moderation events written to both Azure Log Analytics (via Serilog) and the `AuditLog` SQL table.

### Resilience and Fault Tolerance Principles

- **Timeout strategy:** All outbound service calls (SQL, Redis, Service Bus, ACS, Blob) have explicit timeouts. HTTP calls from CacheInvalidationProcessor to APIM: 10 seconds. EF Core queries: 30 seconds.
- **Retry strategy:** Polly configured in `ServiceDefaults` with exponential backoff (2s base, 3 retries) for transient errors on SQL, Redis, and HTTP. Service Bus SDK provides its own retry internally.
- **Bulkhead strategy:** Azure Container Apps scales out independently for the Web app and API — load on one does not starve the other. Functions scale independently per topic subscription.
- **Circuit breaker:** Polly circuit breaker on outbound HTTP calls (e.g., Turnstile verification, APIM cache purge). Opens after 5 consecutive failures within 30 seconds; half-open probe after 60 seconds.
- **Graceful degradation:** ACS email service failures are treated as `Degraded` — API and Web continue operating; email delivery retries asynchronously. Redis failures fall through to SQL (cache miss). APIM cache purge failures are logged; stale responses expire within TTL.

---

## Failure Modes and Resilience

### Expected Failure Scenarios

| Scenario | Trigger | Impact | Mitigation |
|----------|---------|--------|-----------|
| Azure SQL cold start (serverless auto-pause) | First request after ≥ 60 min idle | 5–15s latency on first read or write; health check temporarily Unhealthy | APIM response cache serves reads; write path publishes to Service Bus (not SQL directly); startup probe grace period |
| Redis unavailable | Azure Managed Redis maintenance or C0 restart | Session state and cache misses; all requests fall through to SQL | Application handles `RedisConnectionException`; reads proceed via SQL; write path unaffected |
| Service Bus unavailable | Transient Service Bus issue | Write operations (POST/PUT) fail with 503 | API returns 503; caller retries; Service Bus SDK retries internally |
| Azure Functions cold start | No messages processed for extended period (Consumption plan) | 1–5s processing latency on first message | Message TTL of 24 hours provides buffer; polling callers wait for status update |
| Function processing failure | Invalid message, transient SQL error, unexpected exception | Message retried up to 3 times; then dead-lettered | Service Bus dead-letter queue; alerting on dead-letter message count |
| ACS email delivery failure | ACS outage or email quota exceeded | Transactional and batch emails not sent | Treated as Degraded; email retry via Service Bus `notifications` topic re-queuing; manual resend if needed |
| APIM cache purge failure | Network issue between Function and APIM management API | Stale cache served for up to TTL window (max 5 min for listings) | Best-effort purge; TTL provides automatic expiry; acceptable eventual consistency window |
| Azure Front Door outage | Regional Azure outage | Complete service unavailability | Azure Front Door is a global service with built-in redundancy; single point of external entry |
| Invalid message in dead-letter queue | Message schema mismatch or unhandled exception | Stuck processing; caller's status endpoint shows `Failed` | Dead-letter queue alert; operations team inspects and either replays or rejects |
| OAuth provider outage | Google/GitHub/Microsoft auth unavailable | Social login unavailable | Passkey and password login remain available as alternatives |

### Retry Boundaries and Backoff Strategies

| Layer | Retry Target | Strategy | Max Retries | Idempotent? |
|-------|-------------|----------|-------------|------------|
| API → Service Bus (publish) | Service Bus publish | Polly: exponential (2s, 4s, 8s) | 3 | Yes (duplicate check on consume) |
| Function → Azure SQL | EF Core / SQL | Polly: exponential (2s, 4s, 8s) | 3 | Yes (upsert pattern) |
| Function → Redis | StackExchange.Redis | Polly: exponential (1s, 2s, 4s) | 3 | Yes (DEL is idempotent) |
| Function → APIM cache purge | Polly: circuit breaker + retry | Exponential (2s, 4s) | 2 | Yes (purge is idempotent) |
| Service Bus trigger retry | Service Bus SDK | Exponential (10s, 30s, 90s) | 3 (then DLQ) | Required (idempotent processors) |
| Workers → SQL | Polly: exponential | 3 | Yes |

**Permanent errors** (validation failures, schema mismatches, business rule violations) are **not retried** — they are logged and the message is moved to the dead-letter queue with a reason.

### Impact Isolation and Blast Radius

| Failure | Blast Radius | Isolation Mechanism |
|---------|-------------|---------------------|
| Azure SQL cold start | Read latency only (cache serves reads); writes queue in Service Bus | APIM cache + event-driven write pattern |
| Redis unavailable | Cache miss performance degradation only | Fallthrough to SQL; no data loss |
| Function failure | Write path for affected aggregate only | Service Bus retry + DLQ; read path unaffected |
| Workers job failure | That job's batch only (e.g., one night's reminders) | Independent job processes; no cascading failure |
| ACS outage | Email delivery only | ACS marked Degraded; API + Web remain Healthy |
| APIM Developer tier issue | Public REST API unavailable; Blazor Web unaffected | Web app uses Application services directly, not APIM |

### Data Consistency in Failure

- **Duplicate write prevention:** Function processors check for existing records before inserting (by submission ID). Duplicate messages result in a no-op (idempotent upsert).
- **Partial write window:** Between API publishing event and Function completing write, the caller's `status` endpoint shows `Pending`. No CFP data is visible in GET endpoints until `Completed`.
- **Cache inconsistency window:** If `CacheInvalidationProcessor` fails to purge, stale cache responses persist for up to the TTL window (maximum 5 minutes for listing pages, 1 minute for detail). This is an accepted, documented eventual consistency window.
- **Dead-lettered messages:** A dead-lettered message means the write did not complete. The caller's status endpoint shows `Failed`. Resolution requires operations team intervention (replay or reject from dead-letter queue).

---

## Integration and Messaging Architecture

### Event and Message Types

**Published events (from `CFPCompass.Api` to Service Bus):**

| Topic | Event Type | Trigger |
|-------|------------|---------|
| `cfp-submissions` | `CfpSubmissionCreated` | `POST /v1/cfps` |
| `cfp-submissions` | `CfpSubmissionUpdated` | `PUT /v1/cfps/{id}` |
| `cfp-submissions` | `CfpModerationRequested` | Admin moderation action |
| `user-accounts` | `UserRegistered` | `POST /v1/account/register` |
| `user-accounts` | `UserProfileUpdated` | `PUT /v1/me/preferences` |
| `notifications` | `TransactionalEmailRequested` | Downstream processors |
| `processing-status` | `ProcessingStatusUpdated` | Downstream processors |
| `cache-invalidation` | `CacheInvalidationRequested` | `CfpSubmissionProcessor` after successful write |

**Consumed events (by Azure Functions):**

See the Service Bus topic/consumer mapping in the Component Communication Patterns section above.

All message schemas are specified in AsyncAPI 3.0.0 specs in `docs/api/asyncapi/`. Producers and consumers must conform to approved specs.

### Integration Points (System-to-System)

| External System | Protocol | Direction | SLA Expectation | Unavailability Handling |
|----------------|----------|-----------|----------------|------------------------|
| Azure SQL Database | TDS (EF Core) | Read + Write | Azure SQL GP Serverless: 99.99% | Polly retry; cold-start buffering via Service Bus |
| Azure Managed Redis | Redis protocol (StackExchange.Redis) | Read + Write | Azure Managed Redis C0: ~99.9% | Graceful fallthrough to SQL on `RedisConnectionException` |
| Azure Service Bus | AMQP (Azure.Messaging.ServiceBus) | Publish + Subscribe | Azure Service Bus Standard: 99.9% | API returns 503 on publish failure; no data loss on transient failure |
| Azure Communication Services | HTTPS (Azure.Communication.Email) | Write (send email) | ACS: 99.9% | Treated as Degraded; email retry via re-queue |
| Azure Blob Storage | HTTPS (Azure.Storage.Blobs) | Read + Write | Azure Storage GPv2: 99.9% | Image upload fails gracefully; existing images served from CDN |
| Azure Key Vault | HTTPS (Azure.Security.KeyVault) | Read only (startup) | Azure Key Vault: 99.99% | Startup fails if Key Vault unreachable (secrets required at boot) |
| Cloudflare Turnstile | HTTPS (REST) | Write (verify token) | Best-effort (external) | Circuit breaker; fail-closed (reject submission if Turnstile unreachable) |
| APIM cache purge API | HTTPS (REST) | Write | APIM Developer: ~99.9% | Best-effort; cache expires within TTL on failure |
| OAuth providers (Google/GitHub/Microsoft) | HTTPS (OAuth 2.0) | Read (token exchange) | External; no SLA | Social login degraded; passkey/password login unaffected |

### Protocol Specifications

| Protocol | Usage | Version / Standard |
|----------|-------|-------------------|
| HTTPS | All HTTP communication (API, Web, APIM, OAuth, Key Vault, Turnstile) | TLS 1.2+ (enforced at Azure Front Door) |
| AMQP | Azure Service Bus messaging | AMQP 1.0 (via Azure.Messaging.ServiceBus SDK) |
| Redis protocol | Cache operations | Redis 7.x (Azure Managed Redis) via StackExchange.Redis |
| TDS | Azure SQL Database | via EF Core / Microsoft.Data.SqlClient |
| W3C Trace Context | Distributed tracing propagation | `traceparent` header (W3C Trace Context Level 2) |
| OpenAPI 3.1 | REST API contract specification | OpenAPI Initiative 3.1.0 |
| AsyncAPI 3.0.0 | Service Bus event contract specification | AsyncAPI Initiative 3.0.0 |

---

## Relationship to Other Architecture Artifacts

### Architecture Guide

This document instantiates the architectural overview described in `docs/architecture-guide.md`. All nine solution projects correspond to the Clean Architecture structure described there. The event-driven write pattern (API → Service Bus → Functions → SQL → 202 Accepted) is the concrete implementation of the pattern introduced in the Architecture Guide. No deviations from standard Clean Architecture layering — all dependency rules are strictly followed.

### System Context and Logical Components

The logical components described in `docs/architecture/system-context-and-logical-components.md` map directly to the solution projects specified here:

| Logical Component | This Document's Project(s) |
|------------------|--------------------------|
| Web Application | `CFPCompass.Web` |
| API Host | `CFPCompass.Api` |
| Background Workers | `CFPCompass.Workers` |
| Service Bus Processors | `CFPCompass.Functions` |
| Domain / Application | `CFPCompass.Domain` + `CFPCompass.Application` |
| Infrastructure | `CFPCompass.Infrastructure` |
| Shared Baseline | `CFPCompass.ServiceDefaults` |

### Other Standards and Specifications

- **API Contracts:** `docs/api/openapi/cfp-compass-api-v1.yaml` — OpenAPI 3.1 REST API specification. Imported directly into APIM.
- **Event Contracts:** `docs/api/asyncapi/` — AsyncAPI 3.0.0 specifications for all Service Bus topics.
- **Key ADRs:** ADR-001 (Azure SQL), ADR-002 (Blazor Server), ADR-003 (ASP.NET Core Identity), ADR-004 (Container Apps Jobs), ADR-005 (Azure Managed Redis), ADR-006 (APIM Developer tier), ADR-007 (Event-driven writes), ADR-008 (Service Bus Standard), ADR-009 (HTTP 202 pattern), ADR-010 (Multi-select taxonomy), ADR-011 (APIM response caching), ADR-012 (Cloudflare Turnstile), ADR-013 (.NET Aspire 13.1), ADR-014 (Contract-first).
- **Infrastructure Architecture:** `infra/` Terraform modules define all Azure resource provisioning. This document's component-to-artifact mapping aligns with the Container Apps, Functions, Service Bus, and SQL Terraform module configurations.
