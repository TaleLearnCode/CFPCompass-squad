---
title: Admin API Contract
description: Governed interface for CFP moderation, user management, API key request management, organizer claim assignment, and admin dashboard metrics. Requires the Admin role.
tags:
  - api-contract
  - architecture
  - admin
  - moderation
  - governance
---

# Admin API Contract

## Purpose and Scope

This contract defines the governed interface for all administrative operations in CFP Compass. These endpoints are restricted to users holding the `Admin` role, which is determined by matching the authenticated user's email against the `CFPCOMPASS_ADMIN_EMAILS` environment variable (sourced from Key Vault at runtime and evaluated on every login).

Admin endpoints are served directly by `CfpCompass.Api` over the internal Container Apps network and are **not** exposed through Azure API Management. They are consumed exclusively by the Blazor Server admin UI (`CfpCompass.Web`).

Covered endpoint groups:

- **Submission moderation**: list, approve, and reject pending/reconsidering CFP submissions
- **User management**: list, search, disable, and re-enable user accounts
- **API key requests**: list pending requests, approve, and reject
- **Organizer claims**: admin-assisted claim assignment for edge cases
- **Dashboard**: summary metrics for the admin overview page

All admin actions are logged to the `AuditLog` table in Azure SQL and to Azure Log Analytics for accountability and auditability.

Out of scope: public CFP browsing, anonymous submission handling, organizer claim initiation (those are in `cfps.md`, `submissions.md`, and `claims.md` respectively).

---

## API Responsibilities

- Present the moderation queue of CFP submissions in `Pending` and `Reconsidering` status for admin review.
- Record and apply admin decisions (approve/reject) on queued submissions, triggering downstream notifications and cache invalidation.
- Provide paginated user search and management (disable/enable accounts).
- List pending API key requests and allow approval (with notification email) or rejection.
- Provide an admin-assisted organizer claim assignment path for cases where email verification is not possible.
- Return a summary dashboard of system health metrics (pending queue depth, recent approvals, active users, etc.).
- Write all admin actions to the `AuditLog` table with `adminUserId`, `action`, `targetId`, and `reason` fields.
- Emit cache invalidation events after approval or rejection actions that affect publicly visible data.

The API does **not** allow admins to directly edit CFP content — edits must come through the submitter's edit token flow. Admin role does not bypass the FluentValidation layer for actions that accept a body.

---

## Request Model

### `GET /v1/admin/submissions`

| Parameter  | Type    | Required | Description |
|------------|---------|:--------:|-------------|
| `status`   | string  | No       | Filter by moderation status. Allowed: `Pending`, `Reconsidering`. Default: both. |
| `page`     | integer | No       | 1-based page number. Default: `1`. |
| `pageSize` | integer | No       | Default: `20`. Max: `100`. |
| `sortBy`   | string  | No       | One of: `submittedAt`, `cfpCloseDate`. Default: `submittedAt` ascending. |

### `POST /v1/admin/submissions/{id}/approve`

| Parameter | Type | Required | Description |
|-----------|------|:--------:|-------------|
| `id`      | UUID | ✔️       | Path parameter. The submission ID to approve. |

No request body required. The admin's identity is taken from the authenticated session.

### `POST /v1/admin/submissions/{id}/reject`

| Parameter | Type | Required | Description |
|-----------|------|:--------:|-------------|
| `id`      | UUID | ✔️       | Path parameter. The submission ID to reject. |

| Field    | Type   | Required | Constraints |
|----------|--------|:--------:|-------------|
| `reason` | string | ✔️       | Required rejection reason. Min 10 characters, max 1000 characters. Included in the rejection email to the submitter. |

### `GET /v1/admin/users`

| Parameter  | Type    | Required | Description |
|------------|---------|:--------:|-------------|
| `q`        | string  | No       | Search by email or display name. |
| `status`   | string  | No       | Filter by account status. Allowed: `Active`, `Disabled`. |
| `page`     | integer | No       | Default: `1`. |
| `pageSize` | integer | No       | Default: `20`. Max: `100`. |

### `PUT /v1/admin/users/{id}/disable`

| Parameter | Type | Required | Description |
|-----------|------|:--------:|-------------|
| `id`      | UUID | ✔️       | Path parameter. The user account ID to disable. |

No request body. Admins may optionally provide a reason in the future; not required for MVP.

### `PUT /v1/admin/users/{id}/enable`

| Parameter | Type | Required | Description |
|-----------|------|:--------:|-------------|
| `id`      | UUID | ✔️       | Path parameter. The user account ID to re-enable. |

No request body.

### `GET /v1/admin/api-requests`

| Parameter  | Type    | Required | Description |
|------------|---------|:--------:|-------------|
| `status`   | string  | No       | Filter by request status. Allowed: `Pending`, `Approved`, `Rejected`. Default: `Pending`. |
| `page`     | integer | No       | Default: `1`. |
| `pageSize` | integer | No       | Default: `20`. Max: `100`. |

### `POST /v1/admin/api-requests/{id}/approve`

| Parameter | Type | Required | Description |
|-----------|------|:--------:|-------------|
| `id`      | UUID | ✔️       | Path parameter. The API key request ID to approve. |

| Field       | Type   | Required | Constraints |
|-------------|--------|:--------:|-------------|
| `tier`      | string | ✔️       | APIM product to assign. One of: `cfp-compass-read`, `cfp-compass-readwrite`. |
| `rateLimit` | integer | No      | Custom rate limit override (req/min). If omitted, default product rate limit applies. |

### `POST /v1/admin/api-requests/{id}/reject`

| Field    | Type   | Required | Constraints |
|----------|--------|:--------:|-------------|
| `reason` | string | ✔️       | Required rejection reason. Min 10 characters, max 500 characters. |

### `POST /v1/admin/claims/{cfpId}/assign`

| Parameter | Type | Required | Description |
|-----------|------|:--------:|-------------|
| `cfpId`   | UUID | ✔️       | Path parameter. The CFP ID for which to assign organizer ownership. |

| Field       | Type   | Required | Constraints |
|-------------|--------|:--------:|-------------|
| `userId`    | UUID   | ✔️       | The ID of the authenticated user to assign as organizer. Must be an existing user account. |
| `reason`    | string | ✔️       | Admin's reason for manual assignment. Min 10 characters, max 500 characters. |

### `GET /v1/admin/dashboard`

No parameters. Returns aggregate system metrics.

---

## Field Semantics and Constraints

- **Rejection reason**: Included verbatim in the rejection notification email to the submitter. Admins should write reasons that are constructive and appropriate for external communication.
- **API key approval**: When approved, the API creates a new APIM subscription for the user via the APIM Management API, assigns it to the specified product, and sends an `ApiKeyApproved` notification email via `NotificationProcessor`.
- **Admin-assisted claim assignment**: Bypasses the email verification step. The assigned user immediately receives `OrganizerVerified` status for the CFP. This action is logged to `AuditLog` with the `reason` field for accountability.
- **Dashboard metrics** include: pending submissions count, reconsidering submissions count, submissions approved in the last 30 days, total active users, pending API key requests, and open organizer claims.

---

## Naming and Validation Rules

- All field names in JSON use `camelCase`.
- UUID path parameters are case-insensitive; normalized internally.
- `reason` fields are trimmed of leading/trailing whitespace before storage.

---

## Request Validation and Governance Rules

- All admin endpoints require an authenticated session cookie with the `Admin` claim. The `Admin` claim is issued at login when the user's email matches `CFPCOMPASS_ADMIN_EMAILS`. Requests without the Admin claim return `403 Forbidden`.
- `POST /v1/admin/submissions/{id}/approve` against a submission not in `Pending` or `Reconsidering` status returns `409 Conflict`.
- `POST /v1/admin/submissions/{id}/reject` requires a non-empty `reason`. Missing or too-short reason returns `400 Bad Request`.
- `PUT /v1/admin/users/{id}/disable` on the requesting admin's own account returns `400 Bad Request` (self-disable prevention).
- `POST /v1/admin/claims/{cfpId}/assign` validates that the target `userId` belongs to an existing, active user account.

---

## Execution Semantics

### Approve Submission

1. Admin sends `POST /v1/admin/submissions/{id}/approve`.
2. API validates submission is in `Pending` or `Reconsidering` status.
3. CFP record is updated to `Approved` in Azure SQL (synchronous write — approval is a high-value state change).
4. `ModerationAction` record is created with `Action = Approved`, `AdminUserId`, and `CreatedAt`.
5. `AuditLog` record is written.
6. A `cfp-submission-approved` event is published to the `cfp-submissions` Service Bus topic.
7. `200 OK` is returned.
8. Downstream: `NotificationProcessor` sends the approval email; `CacheInvalidationProcessor` purges APIM and Redis caches; if `organizerIsSubmitter = false`, the `NotificationProcessor` also sends the organizer claim invitation email.

### Reject Submission

1. Admin sends `POST /v1/admin/submissions/{id}/reject` with a reason.
2. API validates submission is in `Pending` or `Reconsidering` status.
3. CFP record is updated to `Rejected` in Azure SQL.
4. A reconsideration token (single-use, 72-hour JWT) is generated and stored.
5. `ModerationAction` record and `AuditLog` record are created.
6. A `cfp-submission-rejected` event is published to the `cfp-submissions` Service Bus topic.
7. `200 OK` is returned.
8. Downstream: `NotificationProcessor` sends the rejection email with the reason and reconsideration link.

### Disable / Enable User

Synchronous write to `AspNetUsers.LockoutEnabled` and `LockoutEnd` (ASP.NET Core Identity lockout mechanism). Existing sessions for the disabled user are invalidated on next request via Identity's security stamp validation. An `AuditLog` record is written.

### Approve API Key Request

1. The APIM Management API is called to create a new subscription under the requester's user identity, assigned to the specified product tier.
2. The `ApiKeyRequest` record status is updated to `Approved`.
3. An `AuditLog` record is written.
4. A `api-key-approved` notification event is published; `NotificationProcessor` sends the `ApiKeyApproved` email with the API key and onboarding instructions.

---

## Response Model

### `GET /v1/admin/submissions` — Success (`200 OK`)

```json
{
  "items": [
    {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "eventName": "TechConf 2026",
      "cfpUrl": "https://techconf.example.com/cfp",
      "cfpCloseDate": "2026-03-31",
      "submitterEmail": "organizer@example.com",
      "organizerIsSubmitter": true,
      "status": "Pending",
      "flaggedDuplicate": false,
      "submittedAt": "2026-01-10T09:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 7,
    "totalPages": 1
  }
}
```

### `POST /v1/admin/submissions/{id}/approve` — Success (`200 OK`)

```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "status": "Approved",
  "approvedAt": "2026-01-12T14:00:00Z"
}
```

### `POST /v1/admin/submissions/{id}/reject` — Success (`200 OK`)

```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "status": "Rejected",
  "rejectedAt": "2026-01-12T14:05:00Z"
}
```

### `GET /v1/admin/dashboard` — Success (`200 OK`)

```json
{
  "pendingSubmissions": 4,
  "reconsideringSubmissions": 1,
  "approvedLast30Days": 23,
  "totalActiveUsers": 312,
  "pendingApiKeyRequests": 2,
  "openOrganizerClaims": 3,
  "generatedAt": "2026-01-15T08:00:00Z"
}
```

### Error Response

```json
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.5.10",
  "title": "Conflict",
  "status": 409,
  "detail": "Submission '3fa85f64-...' is in 'Approved' status and cannot be rejected.",
  "traceId": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
}
```

---

## Status and Observability

Approve and reject actions are synchronous writes. No polling is required for the action itself. Downstream notifications (email, cache invalidation) are asynchronous via Service Bus.

All admin actions are written to the `AuditLog` table with `adminUserId`, `action`, `targetId`, `reason`, `ipAddress`, and `timestamp`. Logs are also streamed to Azure Log Analytics via Serilog for centralized querying and alerting.

APIM analytics surface API key usage metrics per subscription in the APIM Developer Portal and Azure Monitor.

---

## Error Handling

| HTTP Status | Condition |
|-------------|-----------|
| `400 Bad Request` | Validation failure (missing reason, self-disable attempt). |
| `401 Unauthorized` | Missing or invalid session cookie. |
| `403 Forbidden` | Authenticated user does not hold the `Admin` claim. |
| `404 Not Found` | Submission, user, API request, or CFP ID not found. |
| `409 Conflict` | Action is not valid for the target's current state (e.g., approving an already-approved submission). |
| `500 Internal Server Error` | Unhandled exception. Correlation ID included. |

---

## Security and Access Control

### Authentication

All admin endpoints require a valid authenticated session cookie (ASP.NET Core Identity HttpOnly cookie, 14-day sliding expiry).

### Authorization

The `Admin` claim is required on all `/v1/admin/*` routes. This claim is issued at login by checking the authenticated user's email against `CFPCOMPASS_ADMIN_EMAILS` (Key Vault secret). The check is performed on every login — not cached to the session — so adding or removing admins takes effect immediately on next login.

The `[Authorize(Roles = "Admin")]` attribute protects all admin controller actions. Any request reaching the backend without the Admin claim is rejected with `403 Forbidden`.

### Consumer Identity Trust Model

Admin endpoints are only accessible from the internal Container Apps network (not through APIM). The web app's Blazor Server circuit shares the user's session cookie, which is validated by ASP.NET Core authentication middleware on every request. The admin UI does not store admin credentials separately — all authorization flows through the same Identity cookie.

---

## Relationship to Other Artifacts

| Artifact | Relationship |
|----------|-------------|
| `docs/contracts/apis/submissions.md` | Submissions enter the moderation queue handled by these admin endpoints. |
| `docs/contracts/apis/claims.md` | `POST /v1/admin/claims/{cfpId}/assign` is the admin fallback for the claim verification flow. |
| `docs/contracts/events/cfp-submission-approved.md` | Published by approve action; triggers notification + cache invalidation. |
| `docs/contracts/events/cfp-submission-rejected.md` | Published by reject action; triggers rejection notification email. |
| Architecture §4 (Admin Identity) | `CFPCOMPASS_ADMIN_EMAILS` env var approach; evaluated on every login. |
| Architecture §13 (Audit Logging) | `AuditLog` table and Azure Log Analytics for admin action accountability. |
| ADR-014 — Contract-first design | Spec-first requirement applies to admin endpoints. |

---

## Notes and Comments

- Admin emails are configured via the `CFPCOMPASS_ADMIN_EMAILS` environment variable, which is sourced from Key Vault at runtime. Adding an email to this list takes effect on the user's next login — no deployment required.
- The duplicate detection flag (`flaggedDuplicate`) on the submissions list is informational. Admins must make the final approval or rejection decision regardless of the flag. The flag signals that `CfpSubmissionProcessor` found an existing CFP with the same `cfpUrl`.
- `GET /v1/admin/dashboard` data is computed at query time (not materialized). For MVP, this is acceptable given the expected low volume. If query time becomes unacceptable, dashboard metrics can be pre-aggregated via a scheduled job or Redis cache.
- The `CFPCOMPASS_ADMIN_EMAILS` variable supports comma-separated values (e.g., `admin1@example.com,admin2@example.com`). There is no hard limit on the number of admins, but the list is not paginated — it is loaded into memory on startup.

---

## References

- Architecture §4 — API Design (admin endpoint table)
- Architecture §5 — Authentication & Identity (admin identity via CFPCOMPASS_ADMIN_EMAILS)
- Architecture §7 — Background Services (NotificationProcessor, CacheInvalidationProcessor)
- Architecture §13 — Security Considerations (audit logging, admin access escalation threat)
- ADR-014 — Contract-first API and event design
- APIM Management API documentation (for subscription provisioning on API key approval)
