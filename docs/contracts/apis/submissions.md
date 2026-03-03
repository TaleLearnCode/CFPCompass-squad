---
title: Submissions API Contract
description: Governed interface for anonymous CFP submission, editing, reconsideration, and status polling via the public-facing submission form workflow.
tags:
  - api-contract
  - architecture
  - submissions
  - moderation
  - governance
---

# Submissions API Contract

## Purpose and Scope

This contract defines the governed interface for the public CFP submission workflow — the pathway used by conference organizers or community members submitting CFPs through the public form, without requiring an authenticated account or APIM subscription key.

The submission endpoints are distinct from `POST /v1/cfps` (which requires an APIM read-write key). The submission workflow is designed for anonymous public use with bot protection enforced via Cloudflare Turnstile and a server-side honeypot field.

Covered endpoints:

- `POST /v1/submissions` — Submit a new CFP from the public form
- `GET /v1/submissions/{id}` — Retrieve a submission for editing (token-authenticated)
- `PUT /v1/submissions/{id}` — Edit a pending or rejected submission (token-authenticated)
- `POST /v1/submissions/{id}/reconsider` — Request admin reconsideration after rejection (token-authenticated)
- `GET /v1/submissions/{id}/status` — Poll async processing status (anonymous with submission ID)

Out of scope: admin moderation actions (see `admin.md`), the APIM API-key-authenticated submission path (`cfps.md`), and organizer claim verification (`claims.md`).

---

## API Responsibilities

- Accept new CFP submissions from the public form with Turnstile token verification and honeypot validation.
- Assign a unique submission ID and publish a `cfp-submission-created` event to Azure Service Bus.
- Return `202 Accepted` with a `Location` header pointing to the status polling endpoint.
- Return a submission record to authenticated token holders for in-place editing.
- Accept edits to submissions in `Pending` or `Rejected` status and publish a `cfp-submission-updated` event.
- Accept reconsideration requests for rejected submissions and publish a `cfp-submission-reconsideration-requested` event.
- Expose a status polling endpoint for callers to track asynchronous processing outcome.
- Enforce CFP submission lifecycle states: `OrganizerSubmitted` → `Pending` → `Approved` | `Rejected` → `Reconsidering` → `Approved` | `Rejected`.

The API does **not** moderate submissions, approve or reject CFPs, or send emails directly. Those are downstream responsibilities of the Azure Functions processors and email service.

---

## Request Model

### `POST /v1/submissions`

| Field                    | Type     | Required | Constraints |
|--------------------------|----------|:--------:|-------------|
| `eventName`              | string   | ✔️       | 1–200 characters. |
| `cfpUrl`                 | string   | ✔️       | Absolute HTTPS URL. Max 2000 characters. |
| `cfpOpenDate`            | date     | No       | ISO 8601 date. Must be ≤ `cfpCloseDate` if provided. |
| `cfpCloseDate`           | date     | ✔️       | ISO 8601 date. Must be a future date. |
| `eventStartDate`         | date     | No       | ISO 8601 date. |
| `eventEndDate`           | date     | No       | ISO 8601 date. Must be ≥ `eventStartDate` if both provided. |
| `eventFormat`            | string   | ✔️       | One of: `InPerson`, `Virtual`, `Hybrid`. |
| `countryCode`            | string   | No       | ISO 3166-1 alpha-2. Required when `eventFormat` is `InPerson` or `Hybrid`. |
| `subdivisionCode`        | string   | No       | ISO 3166-2. Must belong to `countryCode`. |
| `timeZone`               | string   | No       | IANA time zone identifier. |
| `eventDescription`       | string   | No       | Max 5000 characters. HTML sanitized. |
| `coverageDetails`        | string   | No       | Max 2000 characters. HTML sanitized. |
| `speakerBenefits`        | string   | No       | Max 1000 characters. |
| `travelCoverageDetails`  | string   | No       | Max 1000 characters. |
| `categoryIds`            | UUID[]   | No       | 1–5 Primary Domain category UUIDs. |
| `topicIds`               | UUID[]   | No       | 1–10 Secondary Tag topic UUIDs. |
| `contactEmail`           | string   | ✔️       | Valid email address. Max 320 characters. Used as the organizer contact and for submission notification emails. |
| `organizerIsSubmitter`   | boolean  | ✔️       | `true` if the submitter is the event organizer. |
| `turnstileToken`         | string   | ✔️       | Cloudflare Turnstile verification token from the browser challenge. Validated server-side against the Cloudflare API before any processing begins. |
| `honeypot`               | string   | No       | Hidden form field. **Must be empty string or absent.** Any non-empty value causes the request to be silently discarded (returns `202` to avoid informing bots). |
| `submitterEmail`         | string   | ✔️       | Email address of the person submitting the form. Used for edit/reconsider token delivery. May differ from `contactEmail` when `organizerIsSubmitter` is `false`. |

### `GET /v1/submissions/{id}`

| Parameter | Type   | Required | Description |
|-----------|--------|:--------:|-------------|
| `id`      | UUID   | ✔️       | Submission ID from the submission confirmation email. |
| `token`   | string | ✔️       | Query parameter. Single-use JWT edit token delivered in the submission confirmation email. Valid for 72 hours. |

### `PUT /v1/submissions/{id}`

Path: `id` (UUID, required).  
Header/query: `token` (JWT edit token, required).  
Body: same fields as `POST /v1/submissions`, excluding `turnstileToken` and `honeypot` (bot protection not required for token-authenticated edits). The `cfpUrl` must not change from the original submission.

### `POST /v1/submissions/{id}/reconsider`

Path: `id` (UUID, required).  
Header/query: `token` (JWT reconsideration token from rejection email, required).

| Field     | Type   | Required | Constraints |
|-----------|--------|:--------:|-------------|
| `message` | string | No       | Optional message to the admin reviewing the reconsideration. Max 1000 characters. |

### `GET /v1/submissions/{id}/status`

| Parameter | Type | Required | Description |
|-----------|------|:--------:|-------------|
| `id`      | UUID | ✔️       | Submission ID. No token required — the ID itself is the access control. |

---

## Field Semantics and Constraints

- **`turnstileToken`**: The Cloudflare Turnstile invisible challenge token generated client-side and submitted with the form. The API calls the Cloudflare siteverify endpoint with the `Turnstile-SecretKey` (from Key Vault) before validating any other fields. A failed Turnstile validation returns `422 Unprocessable Entity` with `{ "error": "bot_protection_failed" }`.
- **`honeypot`**: A hidden form field (`display: none` via CSS, not `type=hidden`) that legitimate users never fill. If the honeypot field contains any non-empty value, the API returns `202 Accepted` (to avoid informing the bot that it was detected) but discards the submission without publishing a Service Bus event.
- **`organizerIsSubmitter`**: When `false`, the published CFP enters the organizer claim flow upon approval — it is listed as "Unverified — Awaiting Organizer Claim" until the organizer completes the claim verification (see `claims.md`).
- **CFP status lifecycle**:
  - `OrganizerSubmitted`: Set immediately when `organizerIsSubmitter = true` at submission time.
  - `Pending`: Set by `CfpSubmissionProcessor` after successful processing.
  - `Approved`: Set by admin via `POST /v1/admin/submissions/{id}/approve`.
  - `Rejected`: Set by admin via `POST /v1/admin/submissions/{id}/reject`.
  - `Reconsidering`: Set when `POST /v1/submissions/{id}/reconsider` is successfully processed; returns the submission to the admin moderation queue.
- **Edit token**: A signed JWT valid for 72 hours, single-use. Delivered in the submission confirmation email. Once used (GET retrieves the form), the token is invalidated. A new token is issued in the rejection notification email if the submission is rejected.
- **Reconsideration token**: A new single-use token delivered in the rejection email. Used only for `POST /v1/submissions/{id}/reconsider`. Separate from the edit token.

---

## Naming and Validation Rules

- Field names use `camelCase` in JSON payloads.
- Date fields use ISO 8601 date format (`YYYY-MM-DD`).
- Token is passed as a query parameter `?token=` on authenticated submission endpoints (not in the Authorization header, to match the email link pattern).
- String fields are trimmed of leading/trailing whitespace before processing.
- HTML fields are sanitized using `HtmlSanitizer` before storage.

---

## Request Validation and Governance Rules

- Turnstile verification happens **before** FluentValidation. A failed Turnstile check short-circuits the pipeline.
- A honeypot-filled submission is silently discarded. The caller receives a valid `202 Accepted` response with a fake `submissionId` that will never resolve in the status endpoint.
- FluentValidation runs after bot protection checks.
- Token expiry or invalidity returns `401 Unauthorized` with `{ "error": "token_expired" }` or `{ "error": "token_invalid" }`.
- A `PUT` or `POST /reconsider` against a submission in a non-mutable state returns `409 Conflict` with the current status in the error body.
- App-level rate limit (ASP.NET Core Rate Limiting): `POST /v1/submissions` — 10 per hour per IP.

---

## Execution Semantics

### New Submission

1. Turnstile token is verified against Cloudflare API.
2. Honeypot field is checked server-side. If non-empty, a decoy `202` is returned and processing stops.
3. FluentValidation runs on the request body.
4. A `submissionId` UUID is assigned.
5. A `cfp-submission-created` event is published to the `cfp-submissions` Service Bus topic.
6. `202 Accepted` is returned with `Location: /v1/submissions/{submissionId}/status`.
7. `CfpSubmissionProcessor` dequeues the event, writes the CFP record to Azure SQL with status `Pending`, performs duplicate detection, and updates the processing status record.
8. `NotificationProcessor` dequeues a notification event and sends the submission confirmation email to `submitterEmail` with the edit token link.

### Editing a Submission

1. `GET /v1/submissions/{id}?token={token}` validates the token (expiry, signature, single-use). Returns submission data for form population.
2. `PUT /v1/submissions/{id}?token={token}` validates the token, validates the request body, publishes a `cfp-submission-updated` event, and returns `202 Accepted`.
3. `CfpSubmissionProcessor` sets the submission status back to `Pending` for re-review.

### Reconsideration Request

1. `POST /v1/submissions/{id}/reconsider?token={token}` validates the reconsideration token.
2. Validates the submission is in `Rejected` status.
3. Publishes a `cfp-submission-reconsideration-requested` event.
4. Returns `200 OK`.
5. `CfpSubmissionProcessor` sets the submission to `Reconsidering` in the admin queue.
6. `NotificationProcessor` sends a reconsideration confirmation email to the submitter.

---

## Response Model

### `POST /v1/submissions` — Accepted (`202 Accepted`)

```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "statusUrl": "/v1/submissions/3fa85f64-5717-4562-b3fc-2c963f66afa6/status"
}
```

`Location` header: `/v1/submissions/3fa85f64-5717-4562-b3fc-2c963f66afa6/status`

### `GET /v1/submissions/{id}` — Success (`200 OK`)

Returns the full submission record (same fields as the POST body, plus `status`, `createdAt`, `updatedAt`).

### `PUT /v1/submissions/{id}` — Accepted (`202 Accepted`)

```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "statusUrl": "/v1/submissions/3fa85f64-5717-4562-b3fc-2c963f66afa6/status"
}
```

### `POST /v1/submissions/{id}/reconsider` — Success (`200 OK`)

```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "status": "Reconsidering",
  "message": "Your reconsideration request has been received and will be reviewed by the moderation team."
}
```

### `GET /v1/submissions/{id}/status` — Success (`200 OK`)

```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "processingStatus": "Completed",
  "cfpStatus": "Pending",
  "message": "Your submission is queued for moderation review.",
  "submittedAt": "2026-01-10T09:00:00Z",
  "completedAt": "2026-01-10T09:00:45Z"
}
```

| Processing Status | Description |
|-------------------|-------------|
| `Pending`    | Published to Service Bus, awaiting processor pickup. |
| `Processing` | Processor has dequeued the event, writing to Azure SQL. |
| `Completed`  | Write succeeded. `cfpStatus` reflects the current moderation state. |
| `Failed`     | Processing failed permanently after retries. `message` contains details. |

### Error Response

```json
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.5.1",
  "title": "Validation failed",
  "status": 400,
  "errors": {
    "cfpCloseDate": ["CFP close date must be a future date."],
    "turnstileToken": ["Bot protection verification failed."]
  },
  "traceId": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
}
```

---

## Status and Observability

Callers poll `GET /v1/submissions/{id}/status` after receiving `202 Accepted`. Processing typically completes within seconds under normal load. The status record is created synchronously in Azure SQL by the API before publishing the Service Bus event, ensuring the polling endpoint is immediately queryable.

Submission processing outcomes are logged to Azure Log Analytics with submission ID, Cloudflare Turnstile result, and processing status as structured fields.

---

## Error Handling

| HTTP Status | Condition |
|-------------|-----------|
| `400 Bad Request` | FluentValidation failure on request body. |
| `401 Unauthorized` | Edit or reconsideration token is expired, invalid, or already used. |
| `404 Not Found` | Submission ID does not exist. |
| `409 Conflict` | PUT or reconsider requested on a submission in a non-mutable state. Includes current `cfpStatus` in response. |
| `422 Unprocessable Entity` | Turnstile verification failed (`"error": "bot_protection_failed"`). |
| `429 Too Many Requests` | IP-based rate limit exceeded on public submission endpoint. `Retry-After` header included. |
| `500 Internal Server Error` | Unhandled exception. Correlation ID included. |

---

## Security and Access Control

### Authentication

- `POST /v1/submissions`: Anonymous. Bot protection via Cloudflare Turnstile (server-side verification) and honeypot field.
- `GET /v1/submissions/{id}`, `PUT /v1/submissions/{id}`, `POST /v1/submissions/{id}/reconsider`: Token-authenticated. Single-use JWT (`Jwt-SigningKey` from Key Vault) with 72-hour expiry delivered via email link.
- `GET /v1/submissions/{id}/status`: Anonymous. The submission ID is a UUID that is not guessable; no additional token required for status polling.

### Authorization

These endpoints are not routed through APIM and do not require an APIM subscription key. They are served directly by `CfpCompass.Api` and accessible from the public web.

### Consumer Identity Trust Model

The Cloudflare Turnstile token is the primary trust signal for anonymous submissions. The honeypot field provides a secondary layer against automated form fill. Edit and reconsideration tokens establish identity by possession — the submitter must have access to the email inbox used at submission time.

---

## Relationship to Other Artifacts

| Artifact | Relationship |
|----------|-------------|
| `docs/contracts/apis/cfps.md` | Alternative authenticated submission path via APIM subscription key. |
| `docs/contracts/apis/admin.md` | Admin endpoints that act on submitted CFPs (approve, reject). |
| `docs/contracts/apis/claims.md` | Post-approval organizer claim flow triggered when `organizerIsSubmitter = false`. |
| `docs/contracts/events/cfp-submission-created.md` | Service Bus event published by `POST /v1/submissions`. |
| `docs/contracts/events/cfp-submission-updated.md` | Service Bus event published by `PUT /v1/submissions/{id}`. |
| `docs/contracts/events/cfp-submission-reconsideration-requested.md` | Service Bus event published by `POST /v1/submissions/{id}/reconsider`. |
| Architecture §4 (Bot Protection) | Cloudflare Turnstile and honeypot decision (ADR-012). |
| Architecture §5 (Token Strategy) | Short-lived JWT tokens for email-embedded links. |
| ADR-012 | Bot protection — Cloudflare Turnstile + honeypot rationale. |
| ADR-014 | Contract-first API and event design. |

---

## Notes and Comments

- The honeypot silent-discard pattern is intentional. Returning an error on honeypot detection would confirm to a bot that the field was inspected and allow it to adapt. Returning a fake `202` keeps the bot unaware.
- The `submitterEmail` and `contactEmail` fields may be the same (when `organizerIsSubmitter = true`) or different (community member submitting on behalf of an organizer). The edit token is always sent to `submitterEmail`. The organizer claim invitation is sent to `contactEmail` upon approval.
- Duplicate detection runs in `CfpSubmissionProcessor` by comparing `cfpUrl` against existing Approved and Pending records. Duplicates are flagged in the admin moderation queue but not automatically rejected — admin review is required.

---

## References

- Architecture §4 — API Design (async write pattern, bot protection)
- Architecture §5 — Authentication & Identity (token strategy for email links)
- Architecture §7 — Background Services (CfpSubmissionProcessor, NotificationProcessor)
- Architecture §8 — Email Architecture (submission confirmation, rejection, reconsideration emails)
- ADR-007 — Event-driven async writes via Service Bus
- ADR-012 — Bot protection (Cloudflare Turnstile)
- ADR-014 — Contract-first API and event design
- Cloudflare Turnstile documentation
