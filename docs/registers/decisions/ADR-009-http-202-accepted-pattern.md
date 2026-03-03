---
title: "ADR-009: HTTP 202 Accepted Response Pattern for Async Writes"
description: HTTP 202 Accepted with a Location header and status polling endpoint is adopted as the standard response pattern for all asynchronous write operations.
tags:
  - adr
  - architecture-decision-record
  - aspnet-core
  - http
status: accepted
---

# HTTP 202 Accepted Response Pattern for Async Writes

- **Status:** Accepted
- **Date:** 2026-03-01
- **Work Item:** [*arch-009* — async write API contract definition]

## Context and Problem

The event-driven write pattern (ADR-007) means that write operations (POST/PUT) do not produce an immediately consistent result — the API publishes to Service Bus and returns before the Azure Function has written to SQL. The API must communicate this async behaviour to callers in a standard, discoverable way. Callers (the Blazor Server web app, third-party API consumers) need a mechanism to determine when a write has completed and whether it succeeded or failed. A consistent HTTP response pattern is required so that all write endpoints behave uniformly and can be documented in the OpenAPI spec.

## Decision Drivers

- HTTP-standard response pattern for asynchronous operations — predictable by any HTTP client
- Callers must be able to determine completion status without polling indefinitely
- Failed processing must include enough error detail for callers to diagnose the problem
- Status endpoint must be lightweight and cacheable (simple record lookup)
- Pattern must be documentable in OpenAPI 3.1 spec (202 response + Location header + status schema)
- Consistent behaviour across all write endpoints (CFP submission, updates, approvals, rejections, claims)

## Considered Options

- HTTP 202 Accepted + Location header + status polling endpoint
- HTTP 200 OK with synchronous write (blocking on SQL)
- HTTP 200 OK with optimistic response (assume success, no status tracking)

## Decision Outcome

Chosen option: **HTTP 202 Accepted + Location header + status polling endpoint**, because it is the RFC 7231-standard response for asynchronous operations, provides callers with a clear contract for polling, and allows the status endpoint to be a simple, lightweight, cacheable record lookup. The pattern is documentable in OpenAPI 3.1 and applies uniformly to all write endpoints.

#### Consequences

- Good, because HTTP 202 Accepted is the RFC 7231 standard for async operations — any HTTP client library understands the semantics.
- Good, because the `Location` header in the 202 response tells the caller exactly where to poll — no guessing or out-of-band communication.
- Good, because the status endpoint (`GET /api/v1/submissions/{id}/status`) is a simple record lookup — minimal latency and SQL load.
- Good, because failed status includes error details — callers can diagnose processing failures without contacting support.
- Good, because the pattern applies uniformly to all write endpoints — consistent API behaviour.
- Bad, because callers must implement polling logic — adds complexity to Blazor Server UI (must show a "processing" state and poll until resolved) and to third-party integrators.
- Bad, because status records add storage overhead — mitigated by TTL-based cleanup after 30 days.

#### Implementation

1. All write endpoints (`POST /api/v1/cfps`, `PUT /api/v1/cfps/{id}`, `POST /api/v1/claims`, etc.) return:
   ```
   HTTP/1.1 202 Accepted
   Location: /api/v1/submissions/{id}/status
   Content-Type: application/json

   { "submissionId": "{id}", "status": "Pending" }
   ```
2. Ripley implements `SubmissionStatus` entity with the following state machine:
   - `Pending` — created by API on event publish; not yet picked up by Function
   - `Processing` — Function has received the message and begun processing
   - `Completed` — Function has successfully written to SQL
   - `Failed` — Function has exhausted retries; includes `errorMessage`
3. `GET /api/v1/submissions/{id}/status` returns the current `SubmissionStatus` record:
   ```json
   {
     "submissionId": "abc123",
     "status": "Completed",
     "completedAt": "2026-03-01T10:00:05Z",
     "errorMessage": null
   }
   ```
4. Lambert implements polling in the Blazor Server web app: a brief polling loop (2s interval, max 30s) after a write operation, with a "processing" spinner UI state.
5. The `SubmissionStatus` schema and the 202 response are documented in the OpenAPI 3.1 spec before implementation (ADR-014).
6. Status records are purged after 30 days by the cleanup routine in `CfpExpiryJob`.

#### Confirmation

- All write endpoints return 202 Accepted with valid `Location` header (confirmed in API integration tests).
- Status transitions `Pending → Processing → Completed` confirmed in end-to-end tests.
- Status transitions `Pending → Processing → Failed` confirmed by simulating Function failure.
- `GET /api/v1/submissions/{id}/status` returns 404 after 30-day TTL cleanup.
- Blazor Server UI displays processing state during polling and updates on completion.

#### Stakeholders

- **Dallas (Lead & Architect):** Decision owner; defined async write API contract
- **Ripley (Backend):** Implements 202 response, `SubmissionStatus` entity, state machine, and status endpoint
- **Lambert (Frontend):** Implements polling UI in Blazor Server; shows processing state and handles completion/failure
- **Kane (Tester):** Tests all status transitions, edge cases (timeout, never-completed), and UI polling behaviour

## Pros and Cons of the Options

### HTTP 202 Accepted + Location Header + Status Polling

- Good, because RFC 7231 standard — semantically clear to any HTTP client.
- Good, because `Location` header provides polling target without out-of-band communication.
- Good, because status endpoint is lightweight — no SQL joins, just a record lookup by ID.
- Good, because failed status includes error detail — self-service diagnostics for callers.
- Good, because consistent across all write endpoints — uniform API behaviour.
- Good, because documentable in OpenAPI 3.1 as a standard async response pattern.
- Neutral, because polling is the client's responsibility — well-understood pattern for experienced API consumers.
- Bad, because Blazor Server UI requires a polling loop — slightly more complex than displaying an immediate result.
- Bad, because status records accumulate over time — TTL cleanup is required.

### HTTP 200 OK with Synchronous Write (Blocking on SQL)

- Good, because immediate consistency — response includes the persisted result.
- Good, because simplest API contract — no polling required.
- Bad, because 10-second SQL cold-start blocks the API caller — violates the core motivation for the event-driven write pattern.
- Bad, because tightly couples API availability to SQL availability — a cold database means a slow API response.
- Bad, because cannot be combined with the Service Bus event-driven write pattern.

### HTTP 200 OK with Optimistic Response (No Status Tracking)

- Good, because immediate response — caller receives 200 OK instantly.
- Good, because no status records or polling.
- Neutral, because easy to implement — just publish to Service Bus and return 200.
- Bad, because caller has no way to detect write failure — silent data loss if the Function fails.
- Bad, because violates the principle of honest API design — 200 OK implies the operation is complete.
- Bad, because dead-letter queue failures are invisible to callers — debugging becomes very difficult.

## More Information

RFC 7231 §6.3.3 — 202 Accepted: https://www.rfc-editor.org/rfc/rfc7231#section-6.3.3

The Microsoft REST API guidelines recommend exactly this pattern for long-running or async operations: return 202 Accepted with a `Location` (or `Operation-Location`) header pointing to a status endpoint. CFP Compass follows this convention.

The polling timeout for the Blazor Server web app is set to 30 seconds (15 polls at 2-second intervals). If the status is still `Pending` or `Processing` after 30 seconds, the UI shows a "This is taking longer than expected" message with a link to the status page. This handles edge cases where Service Bus or Functions experience transient delays.

## Follow-On Information

If third-party API consumers express difficulty implementing polling, a webhook/callback option can be added to the status endpoint — callers register a callback URL and receive a POST notification on completion. This does not change the existing 202 + polling pattern; it is an additive capability.

## Record History

* **Proposed**: 2026-03-01
* **Accepted**: 2026-03-01
* **Last Reviewed**: 2026-03-01
