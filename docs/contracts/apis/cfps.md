---
title: CFPs API Contract
description: Governed interface for listing, retrieving, submitting, and updating Call for Papers (CFP) records via the CFP Compass public API.
tags:
  - api-contract
  - architecture
  - cfps
  - integration
  - governance
---

# CFPs API Contract

## Purpose and Scope

This contract defines the governed interface for all CFP-related REST endpoints exposed through Azure API Management under `/v1/cfps`. It covers the discovery and retrieval of approved CFPs, submission of new CFPs, update of existing CFPs, access to the historical archive, and retrieval of per-event CFP history.

The public API is consumed by third-party integrations, developer tooling, and community tools. The web application (`CfpCompass.Web`) interacts with the same API layer but with cookie-based authentication rather than APIM subscription keys.

Write operations (POST, PUT) follow the asynchronous event-driven pattern: the API publishes a Service Bus event and immediately returns `202 Accepted`. The caller polls the status endpoint for processing outcome. Read operations are cached at the APIM layer to offset Azure SQL serverless cold-start latency.

Out of scope: admin moderation actions, user account management, organizer claim flows, and submission-specific endpoints for anonymous organizers (see `submissions.md`).

---

## API Responsibilities

- Return paginated, filtered, and sorted lists of **Approved** CFPs to authorized API consumers.
- Return the full detail record of a single Approved CFP by its unique identifier.
- Accept new CFP submissions from authorized read-write consumers and hand them off to the moderation pipeline.
- Accept updates to existing CFPs from authorized read-write consumers and re-enter them into the moderation pipeline.
- Expose a read-only archive of CFPs that have passed their submission deadline by more than 7 days.
- Expose the ordered moderation history of a specific event's recurring CFP listings.
- Enforce APIM rate limits (100 req/min for read, 10 req/min for write) per subscription key.
- Return response-cached results for GET endpoints (5-minute TTL for listing, 1-minute TTL for detail).
- Emit cache invalidation events after successful write processing to keep cached responses consistent.

The API does **not** moderate submissions, manage organizer claims, authenticate users, or send emails directly — those responsibilities belong to downstream processors and other API surfaces.

---

## Request Model

### `GET /v1/cfps` — Query Parameters

| Parameter    | Type    | Required | Description |
|--------------|---------|:--------:|-------------|
| `page`       | integer | No       | 1-based page number. Default: `1`. |
| `pageSize`   | integer | No       | Results per page. Default: `20`. Max: `100`. |
| `sortBy`     | string  | No       | Sort field. Allowed: `deadline`, `createdAt`, `eventName`. Default: `deadline`. |
| `sortDir`    | string  | No       | Sort direction. Allowed: `asc`, `desc`. Default: `asc`. |
| `category`   | string  | No       | Filter by Primary Domain category ID (UUID). Repeatable. |
| `topic`      | string  | No       | Filter by Secondary Tag topic ID (UUID). Repeatable. |
| `country`    | string  | No       | Filter by ISO 3166-1 alpha-2 country code. Repeatable. |
| `region`     | string  | No       | Filter by UN M.49 world region code. |
| `format`     | string  | No       | Filter by event format. Allowed: `InPerson`, `Virtual`, `Hybrid`. |
| `openAfter`  | date    | No       | Return CFPs whose `cfpOpenDate` is on or after this date (ISO 8601 date, e.g. `2026-01-01`). |
| `closeBefore`| date    | No       | Return CFPs whose `cfpCloseDate` is on or before this date. |
| `q`          | string  | No       | Full-text search across event name, description, and coverage details. Max 200 characters. |

### `GET /v1/cfps/{id}` — Path Parameters

| Parameter | Type   | Required | Description |
|-----------|--------|:--------:|-------------|
| `id`      | UUID   | ✔️       | The unique identifier of the CFP record. |

### `POST /v1/cfps` — Request Body

| Field                  | Type     | Required | Constraints |
|------------------------|----------|:--------:|-------------|
| `eventName`            | string   | ✔️       | 1–200 characters. |
| `cfpUrl`               | string   | ✔️       | Absolute HTTPS URL. Max 2000 characters. |
| `cfpOpenDate`          | date     | No       | ISO 8601 date. Must be ≤ `cfpCloseDate` if both provided. |
| `cfpCloseDate`         | date     | ✔️       | ISO 8601 date. Must be in the future at submission time. |
| `eventStartDate`       | date     | No       | ISO 8601 date. |
| `eventEndDate`         | date     | No       | ISO 8601 date. Must be ≥ `eventStartDate` if both provided. |
| `eventFormat`          | string   | ✔️       | One of: `InPerson`, `Virtual`, `Hybrid`. |
| `countryCode`          | string   | No       | ISO 3166-1 alpha-2. Required when `eventFormat` is `InPerson` or `Hybrid`. |
| `subdivisionCode`      | string   | No       | ISO 3166-2. Must be a valid subdivision of the given `countryCode`. |
| `timeZone`             | string   | No       | IANA time zone identifier (e.g., `America/Chicago`). |
| `eventDescription`     | string   | No       | Max 5000 characters. HTML sanitized. |
| `coverageDetails`      | string   | No       | Max 2000 characters. HTML sanitized. |
| `speakerBenefits`      | string   | No       | Max 1000 characters. |
| `travelCoverageDetails`| string   | No       | Max 1000 characters. |
| `categoryIds`          | UUID[]   | No       | 1–5 Primary Domain category UUIDs. |
| `topicIds`             | UUID[]   | No       | 1–10 Secondary Tag topic UUIDs. |
| `contactEmail`         | string   | ✔️       | Valid email address. Max 320 characters. |
| `organizerIsSubmitter` | boolean  | ✔️       | `true` if submitter is the event organizer. |
| `logoUrl`              | string   | No       | Absolute HTTPS URL to logo. Max 2000 characters. Must point to PNG, JPG, or WebP. |

### `PUT /v1/cfps/{id}` — Path Parameters and Request Body

Path: `id` (UUID, required) — must identify an existing CFP owned by the requester's subscription or a CFP in `PendingOrganizer` status.

Body: same fields as `POST /v1/cfps`. All fields are treated as full replacement (not partial patch). `cfpUrl` must remain the same as the original submission.

### `GET /v1/cfps/archive` — Query Parameters

Same filtering and pagination parameters as `GET /v1/cfps`. Archive endpoint returns CFPs where the submission deadline expired more than 7 days ago.

### `GET /v1/cfps/{id}/history` — Path Parameters

| Parameter | Type | Required | Description |
|-----------|------|:--------:|-------------|
| `id`      | UUID | ✔️       | The unique identifier of the CFP record. Returns all moderation-approved CFP records sharing the same canonical event URL. |

---

## Field Semantics and Constraints

- **`cfpUrl`** is the canonical deduplication key. Submissions with a `cfpUrl` already present in the system are flagged for duplicate review before approval.
- **`organizerIsSubmitter`** controls the post-approval claim flow. If `false`, an organizer claim invitation email is sent to `contactEmail` upon approval, placing the listing in `UnverifiedAwaitingClaim` status until verified.
- **`categoryIds`** and **`topicIds`** reference seeded reference data. Invalid IDs result in a `400 Bad Request`. Both are multi-select; filter queries use `EXISTS` against junction tables.
- **`countryCode`** and **`subdivisionCode`** are validated against the ISO 3166 data seeded in the database. `subdivisionCode` must belong to the given `countryCode`.
- **`timeZone`** must be a valid IANA time zone identifier.
- **`cfpCloseDate`** must be a future date at the time of submission. The system archives CFPs automatically 7 days after this date via the `CfpExpiryJob`.
- **`logoUrl`** accepts externally hosted images. The API does not proxy or re-host logos.

---

## Naming and Validation Rules

- All date fields use ISO 8601 date format (`YYYY-MM-DD`). Date-time fields use ISO 8601 with UTC offset.
- Field names use `camelCase` in JSON payloads.
- String fields are trimmed of leading/trailing whitespace server-side before processing.
- HTML fields (`eventDescription`, `coverageDetails`) are sanitized using `HtmlSanitizer` to strip disallowed tags and attributes before storage.
- URL fields must use the `https://` scheme. HTTP-only URLs are rejected with `400 Bad Request`.
- Enum fields (`eventFormat`) are case-insensitive in parsing but normalized to `PascalCase` in storage and responses.

---

## Request Validation and Governance Rules

- The APIM subscription key is validated by APIM before the request reaches the backend. Missing or invalid keys return `401 Unauthorized` at the APIM layer.
- Write endpoints (`POST`, `PUT`) require a subscription belonging to the `cfp-compass-readwrite` APIM product. Read-only keys return `403 Forbidden`.
- Request body size is limited to 1 MB by APIM inbound policy. Oversized requests return `413 Request Entity Too Large`.
- FluentValidation is applied at the Application layer boundary before any business logic executes. Validation errors return `400 Bad Request` with a `errors` array.
- A `PUT /v1/cfps/{id}` request against a CFP not in a mutable state (`Approved`, `Rejected`) returns `409 Conflict`.
- Duplicate detection: if the submitted `cfpUrl` matches an existing Approved or Pending CFP, the submission is accepted and processed but flagged for admin review. It does not fail immediately.
- All write requests receive an idempotency-safe `submissionId` in the 202 response. Retrying a POST with the same `cfpUrl` within a short window (deduplicated by Service Bus message ID) does not create duplicate processing jobs.

---

## Execution Semantics

### Read Requests (GET)

1. APIM validates the subscription key.
2. APIM checks its response cache for the request signature (URL + query params). On cache hit, the cached response is returned without forwarding to the backend.
3. On cache miss, APIM forwards the request to the `CfpCompass.Api` backend Container App.
4. The API queries Azure SQL and returns the result. APIM caches the response per the configured TTL.

### Write Requests (POST/PUT)

1. APIM validates the subscription key and write product membership.
2. APIM forwards the request to the backend.
3. The backend validates the request body (FluentValidation).
4. On validation success, the API assigns a `submissionId`, publishes a `cfp-submission-created` or `cfp-submission-updated` event to Azure Service Bus (`cfp-submissions` topic), and returns `202 Accepted`.
5. The `CfpSubmissionProcessor` Azure Function picks up the event, writes to Azure SQL, performs duplicate detection, and updates the processing status record.
6. On successful processing, the `CacheInvalidationProcessor` purges the relevant APIM cache entries.
7. The caller can poll `GET /v1/submissions/{submissionId}/status` to track progress.

---

## Response Model

### `GET /v1/cfps` — Success Response (`200 OK`)

```json
{
  "items": [
    {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "eventName": "TechConf 2026",
      "cfpUrl": "https://techconf.example.com/cfp",
      "cfpOpenDate": "2026-01-15",
      "cfpCloseDate": "2026-03-31",
      "eventStartDate": "2026-06-10",
      "eventEndDate": "2026-06-12",
      "eventFormat": "InPerson",
      "countryCode": "US",
      "subdivisionCode": "US-TX",
      "timeZone": "America/Chicago",
      "categories": [
        { "id": "...", "name": "Cloud & Infrastructure" }
      ],
      "topics": [
        { "id": "...", "name": "Azure", "group": "Cloud Platforms" }
      ],
      "status": "Approved",
      "organizerVerified": true,
      "createdAt": "2026-01-10T09:00:00Z",
      "updatedAt": "2026-01-12T14:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 142,
    "totalPages": 8
  }
}
```

### `GET /v1/cfps/{id}` — Success Response (`200 OK`)

Returns a single CFP object with all fields including `eventDescription`, `coverageDetails`, `speakerBenefits`, `travelCoverageDetails`, and `contactEmail` (if organizer verified).

### `POST /v1/cfps` — Accepted Response (`202 Accepted`)

```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "statusUrl": "/v1/submissions/3fa85f64-5717-4562-b3fc-2c963f66afa6/status"
}
```

`Location` header: `/v1/submissions/3fa85f64-5717-4562-b3fc-2c963f66afa6/status`

### `PUT /v1/cfps/{id}` — Accepted Response (`202 Accepted`)

Same body shape as `POST`, using the existing CFP `id`.

### Error Response

```json
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.5.1",
  "title": "Validation failed",
  "status": 400,
  "errors": {
    "cfpCloseDate": ["CFP close date must be a future date."],
    "countryCode": ["Country code 'XX' is not a valid ISO 3166-1 alpha-2 code."]
  },
  "traceId": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
}
```

### Observability Endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /v1/submissions/{id}/status` | Poll processing status for async writes. Returns `Pending`, `Processing`, `Completed`, or `Failed`. |

---

## Status and Observability

After receiving a `202 Accepted` response, callers may poll `GET /v1/submissions/{id}/status`:

```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "status": "Completed",
  "cfpStatus": "Pending",
  "message": "Submission received and queued for moderation review.",
  "completedAt": "2026-01-10T09:00:45Z"
}
```

| Processing Status | Meaning |
|-------------------|---------|
| `Pending`    | Event published to Service Bus; not yet picked up by the processor. |
| `Processing` | Processor has dequeued the event and is writing to Azure SQL. |
| `Completed`  | Write succeeded. The CFP record exists in the database. `cfpStatus` reflects the moderation state. |
| `Failed`     | Processing failed permanently after retries. Details in `message`. |

All write operations are logged with distributed trace correlation IDs (W3C `traceparent`) in Azure Log Analytics for end-to-end observability.

---

## Error Handling

| HTTP Status | Condition |
|-------------|-----------|
| `400 Bad Request` | FluentValidation failure — missing required fields, invalid enum values, invalid ISO codes, date order violations. |
| `401 Unauthorized` | Missing or invalid APIM subscription key (returned by APIM before reaching backend). |
| `403 Forbidden` | Read-only subscription key used on a write endpoint. |
| `404 Not Found` | CFP with the specified `id` does not exist or is not in `Approved` status. |
| `409 Conflict` | PUT requested on a CFP in a non-mutable state. |
| `413 Request Entity Too Large` | Request body exceeds 1 MB (APIM policy). |
| `429 Too Many Requests` | Rate limit exceeded. `Retry-After` header included. Read: 100/min; Write: 10/min. |
| `500 Internal Server Error` | Unhandled exception on the backend. Correlation ID included in response. |
| `503 Service Unavailable` | Backend health check failing (Azure SQL or Redis unavailable). |

Validation errors return an RFC 9110-compliant Problem Details response with a structured `errors` dictionary keyed by field name. All error responses include a `traceId` for support correlation.

---

## Security and Access Control

### Authentication

External API consumers authenticate via an APIM subscription key passed in the `Ocp-Apim-Subscription-Key` HTTP header. Subscription keys are provisioned through the APIM Developer Portal after request approval by an admin (`POST /v1/admin/api-requests/{id}/approve`).

Web application consumers (Blazor Server) authenticate via the ASP.NET Core Identity cookie session. The cookie is `HttpOnly`, `Secure`, and uses `SameSite=Strict` with a 14-day sliding expiration.

### Authorization

| APIM Product | Endpoints Accessible |
|---|---|
| `cfp-compass-read` | All GET endpoints |
| `cfp-compass-readwrite` | All GET endpoints + POST `/v1/cfps` + PUT `/v1/cfps/{id}` |

Write endpoints validate product membership in addition to key validity.

### Consumer Identity Trust Model

APIM subscription keys are the external consumer identity boundary. Keys are associated with a named application identity in the APIM Developer Portal. APIM logs all requests with subscription key ID for analytics and abuse tracking. The backend API trusts that APIM has validated the key before forwarding; it does not re-validate APIM keys.

Web application sessions are validated by ASP.NET Core's authentication middleware on every request. The session cookie is validated against the Identity server's data protection keys.

---

## Relationship to Other Artifacts

| Artifact | Relationship |
|----------|-------------|
| `docs/api/openapi/cfp-compass-api-v1.yaml` | Canonical OpenAPI 3.1 spec. APIM imports this spec directly. This contract doc is the prose complement. |
| `docs/contracts/apis/submissions.md` | Anonymous submission flow — used when the submitter is not an API consumer (public form). |
| `docs/contracts/events/cfp-submission-created.md` | Service Bus event published by `POST /v1/cfps`. |
| `docs/contracts/events/cfp-submission-updated.md` | Service Bus event published by `PUT /v1/cfps/{id}`. |
| `docs/contracts/events/cfp-submission-approved.md` | Event triggering cache invalidation after admin approval. |
| `docs/contracts/apis/metadata.md` | Reference data contract for `categoryIds`, `topicIds`, `countryCode`, `subdivisionCode`, and region values. |
| Architecture §4 (API Design) | APIM topology, rate limits, cache TTLs, and async write pattern. |
| ADR-007 | Decision to adopt event-driven async writes via Service Bus. |
| ADR-014 | Spec-first API design requirement. |

---

## Notes and Comments

- The `GET /v1/cfps/archive` endpoint is distinct from the main listing. Archived CFPs are those where `cfpCloseDate` is more than 7 days in the past. They are not included in the main `GET /v1/cfps` response regardless of filters.
- `GET /v1/cfps/{id}/history` returns all historical CFP records for a recurring event, identified by shared canonical `cfpUrl`. This allows community tooling to track how a conference's CFP has changed across years.
- The `organizerVerified` flag in the listing response reflects whether an organizer has completed the claim verification flow. Unverified listings show a "Unverified — Awaiting Organizer Claim" badge in the web UI.
- Cache invalidation is asynchronous. A small window exists after admin approval where the cached listing may not yet include the newly published CFP. The maximum staleness is bounded by the 5-minute APIM TTL.

---

## References

- Architecture §4 — API Design (APIM topology, rate limits, response caching, async write pattern)
- Architecture §11 — API & Event Contract Design (spec-first requirement, OpenAPI tooling)
- ADR-007 — Event-driven async writes via Azure Service Bus
- ADR-012 — Bot protection strategy (Cloudflare Turnstile; relevant to public submission form)
- ADR-014 — Contract-first API and event design
- RFC 9110 — HTTP Semantics (Problem Details error format)
- ISO 3166-1 / ISO 3166-2 — Country and subdivision codes
- UN M.49 — World region classification
- IANA Time Zone Database
