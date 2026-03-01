---
title: "ADR-007: Event-Driven Write Pattern via Azure Service Bus"
description: Selects an event-driven write pattern using Azure Service Bus topics and Azure Functions subscribers so the API returns HTTP 202 Accepted immediately, fully decoupling API responsiveness from Azure SQL Serverless cold-start latency.
tags:
  - adr
  - architecture-decision-record
  - azure-service-bus
  - azure-functions
  - event-driven
status: accepted
---
# Event-Driven Write Pattern via Azure Service Bus

- **Status:** Accepted
- **Date:** 2026-03-01
- **Work Item:** [*arch-007* — write path architecture and database coupling]

## Context and Problem

CFP Compass uses Azure SQL Database in Serverless mode, which auto-pauses after idle periods and takes approximately 10 seconds to cold-start. Synchronous write operations (POST/PUT) that block on SQL availability would cause visible timeouts or degraded user experience when the database is cold. The API must remain responsive regardless of the database's current availability state. Additionally, write and read paths have different scaling characteristics: reads are served from APIM cache and benefit from high concurrency, while writes are low-frequency but must be reliably persisted. These paths should be independently scalable and loosely coupled.

## Decision Drivers

- API responsiveness must not depend on Azure SQL availability or cold-start state
- Write operations must be reliably persisted even if the database is temporarily unavailable
- Independent scaling of read (APIM cache) and write (Functions + SQL) paths
- Audit trail for all write operations
- Clear, documented API contract for callers who must understand the async behaviour
- Dead-letter queue capability for failed message handling and monitoring

## Considered Options

- Event-driven writes via Azure Service Bus (topics) + Azure Functions subscribers
- Synchronous writes directly from API to Azure SQL
- Command queue with API-side polling (self-managed queue in Azure Storage)

## Decision Outcome

Chosen option: **Event-driven writes via Azure Service Bus (Standard tier, topic-per-aggregate) with Azure Functions subscribers**, because it fully decouples API responsiveness from SQL availability, provides Service Bus's built-in dead-letter queue for failure handling, and enables fan-out (a single write event can trigger both SQL persistence and cache invalidation). The API returns HTTP 202 Accepted immediately, and callers poll a status endpoint for completion confirmation.

#### Consequences

- Good, because the API always returns HTTP 202 Accepted immediately — SQL cold-start has zero impact on caller experience.
- Good, because Service Bus buffers events during SQL cold-start; the Function retries until SQL is available.
- Good, because dead-letter queues automatically capture failed messages after maximum retries — no lost writes.
- Good, because fan-out subscriptions allow a single write event to trigger both the SQL write Function and a cache invalidation Function.
- Good, because Service Bus message metadata provides an audit trail of all write events.
- Good, because read and write paths scale independently — Functions scale with queue depth, Container App (API) scales with HTTP request concurrency.
- Bad, because the system is eventually consistent — callers must poll for completion status rather than receiving the final result synchronously.
- Bad, because added infrastructure complexity: Service Bus + Functions + status tracking table adds components to build, test, and operate.
- Bad, because message processing must be idempotent — Functions must handle duplicate delivery (Service Bus at-least-once delivery).

#### Implementation

1. Ripley implements Service Bus publishing in API controllers: on POST/PUT, validate the request, create a `SubmissionStatus` record (status: `Pending`), publish an event to the appropriate Service Bus topic, return `202 Accepted` with `Location: /api/v1/submissions/{id}/status`.
2. Ripley creates `CFPCompass.Functions` project with one Function per Service Bus topic subscription:
   - `CfpSubmissionCreatedProcessor` — subscribes to `cfp-submission-created`
   - `CfpSubmissionUpdatedProcessor` — subscribes to `cfp-submission-updated`
   - `CfpSubmissionApprovedProcessor` — subscribes to `cfp-submission-approved`
   - `CfpSubmissionRejectedProcessor` — subscribes to `cfp-submission-rejected`
   - `CacheInvalidationProcessor` — subscribes to all topics; invalidates Redis and APIM caches
3. Each Function updates the `SubmissionStatus` record: `Pending → Processing → Completed | Failed`.
4. On failure, the Function logs the error and lets Service Bus route the message to the dead-letter queue after maximum retries.
5. Parker provisions the `infra/modules/service-bus/` Terraform module with all topics and subscriptions.
6. The status endpoint `GET /api/v1/submissions/{id}/status` returns the current status record — lightweight, cacheable.

#### Confirmation

- End-to-end write flow tested in integration: POST → 202 response → poll status → Completed.
- SQL cold-start simulation: database suspended manually; POST still returns 202; status reaches Completed within 30 seconds of SQL wake-up.
- Dead-letter queue receives messages when Function throws unrecoverable exception (confirmed in integration test).
- Idempotency: duplicate Service Bus message delivery (simulated) produces no duplicate SQL records.
- Fan-out: single write event triggers both SQL write and cache invalidation in parallel subscriptions.

#### Stakeholders

- **Dallas (Lead & Architect):** Decision owner; designed event-driven write architecture
- **Ripley (Backend):** Implements Service Bus publishing in API, `CFPCompass.Functions` processors, and `SubmissionStatus` tracking
- **Parker (DevOps):** Provisions Service Bus namespace, topics, and subscriptions via Terraform; configures Function App trigger bindings
- **Kane (Tester):** Tests write flow, status polling, dead-letter handling, and idempotency

## Pros and Cons of the Options

### Event-Driven Writes via Azure Service Bus + Azure Functions

- Good, because API is fully decoupled from SQL — 202 Accepted response is instant regardless of SQL state.
- Good, because Service Bus buffers events during SQL cold-start; no writes are lost.
- Good, because dead-letter queues provide automatic failure capture and monitoring hook.
- Good, because fan-out: write event triggers multiple subscribers (SQL write + cache invalidation).
- Good, because independent scaling: Functions scale with queue depth; API scales with HTTP concurrency.
- Good, because Service Bus message metadata provides an audit trail.
- Neutral, because requires status polling — well-documented pattern, but adds client complexity.
- Bad, because eventual consistency — callers must accept that reads immediately after a write may not reflect the write.
- Bad, because idempotent processing must be explicitly implemented.

### Synchronous Writes Directly from API to Azure SQL

- Good, because simplest implementation — direct EF Core `SaveChangesAsync()` in the API controller.
- Good, because immediate consistency — response includes the persisted result.
- Neutral, because no additional infrastructure required.
- Bad, because 10-second SQL cold-start directly blocks the API caller — unacceptable UX.
- Bad, because write and read paths are tightly coupled — SQL availability affects API availability.
- Bad, because no resilience against transient SQL failures — requires complex retry logic in the API.

### Command Queue with Self-Managed Azure Storage Queue

- Good, because Azure Storage Queue is extremely cheap (~$0.004/10K operations).
- Good, because decouples API from SQL.
- Neutral, because .NET SDK supports polling Storage Queues.
- Bad, because no topics or subscriptions — fan-out requires multiple queues or queue-side filtering.
- Bad, because no dead-letter queue capability (manual poison message handling required).
- Bad, because no built-in ordering guarantees or filtering.
- Bad, because long-polling required for low-latency processing — increases complexity vs. Functions trigger binding.

## More Information

Azure Service Bus topics and subscriptions documentation: https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview

The `SubmissionStatus` table schema:
```sql
CREATE TABLE SubmissionStatus (
    Id          UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Status      NVARCHAR(50) NOT NULL,  -- Pending | Processing | Completed | Failed
    ErrorMessage NVARCHAR(MAX) NULL,
    CreatedAt   DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    UpdatedAt   DATETIME2 NOT NULL DEFAULT GETUTCDATE()
);
```

Status records are purged after 30 days by the `CfpExpiryJob` cleanup routine.

## Follow-On Information

If the status polling pattern proves to be a friction point for API consumers, a webhook/callback pattern can be layered on top of the existing status endpoint without changing the underlying event-driven architecture. Callers would register a callback URL; the CacheInvalidationProcessor would POST to the callback on completion.

## Record History

* **Proposed**: 2026-03-01
* **Accepted**: 2026-03-01
* **Last Reviewed**: 2026-03-01
