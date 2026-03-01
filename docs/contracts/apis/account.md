---
title: Account & User API Contract
description: Governed interface for speaker account lifecycle, session management, CFP tracking, and notification preference management. Internal to the web application — not exposed via APIM.
tags:
  - api-contract
  - architecture
  - account
  - identity
  - governance
---

# Account & User API Contract

## Purpose and Scope

This contract defines the governed interface for all account lifecycle, authentication, CFP tracking, and notification preference endpoints. These endpoints are **internal to the CFP Compass web application** (`CfpCompass.Web`) and are **not exposed through Azure API Management**. They are served directly by `CfpCompass.Api` and consumed only by the Blazor Server frontend over the internal Container Apps network.

Covered endpoint groups:

- **Account lifecycle**: register, login, logout, forgot password, reset password
- **CFP tracking**: view, create, update, and delete a speaker's tracked CFPs with 3-state workflow
- **Notification preferences**: view and update deadline reminder and weekly digest preferences

Authentication for these endpoints uses ASP.NET Core Identity session cookies (HttpOnly, Secure, SameSite=Strict, 14-day sliding expiration). Passkey (WebAuthn/FIDO2) login is supported via `Fido2NetLib`. Social login (Google, GitHub, Microsoft) creates or links a local Identity user.

Out of scope: admin moderation, API key management, organizer claim flows, and CFP submission (see `submissions.md`, `claims.md`, `admin.md`).

---

## API Responsibilities

- Create new speaker accounts via email/password registration with email confirmation.
- Authenticate speakers via email/password, passkey (WebAuthn/FIDO2), or OAuth social login.
- Issue and manage HttpOnly session cookies with 14-day sliding expiration.
- Terminate authenticated sessions on logout.
- Orchestrate password reset flows using single-use, 72-hour JWT tokens delivered by email.
- Return a speaker's list of tracked CFPs with their current tracking status.
- Create, update, and delete CFP tracking records in the 3-state workflow (Interested → Submitted → Accepted).
- Return and persist a speaker's notification preferences (deadline reminders, weekly digest).
- Enforce app-level rate limits on authentication and registration endpoints (distinct from APIM rate limits).

The API does **not** expose these endpoints through APIM, issue APIM subscription keys, or handle organizer-specific workflows.

---

## Request Model

### `POST /v1/account/register`

| Field           | Type   | Required | Constraints |
|-----------------|--------|:--------:|-------------|
| `email`         | string | ✔️       | Valid email, max 320 characters. Must not already exist. |
| `displayName`   | string | ✔️       | 2–100 characters. Trimmed. |
| `password`      | string | ✔️       | Min 12 characters; must include uppercase, lowercase, digit, and symbol. |

### `POST /v1/account/login`

| Field      | Type   | Required | Constraints |
|------------|--------|:--------:|-------------|
| `email`    | string | ✔️       | Registered email address. |
| `password` | string | No       | Required when `loginMethod` is `password`. |
| `loginMethod` | string | ✔️    | One of: `password`, `passkey`. |
| `passkeyResponse` | object | No | WebAuthn assertion response object. Required when `loginMethod` is `passkey`. |

### `POST /v1/account/logout`

No request body. Requires an authenticated session cookie.

### `POST /v1/account/forgot-password`

| Field   | Type   | Required | Constraints |
|---------|--------|:--------:|-------------|
| `email` | string | ✔️       | Email address for the account to reset. Response is always `200 OK` regardless of whether the email is registered (to prevent user enumeration). |

### `POST /v1/account/reset-password`

| Field       | Type   | Required | Constraints |
|-------------|--------|:--------:|-------------|
| `token`     | string | ✔️       | Single-use reset token from the reset email link. Valid for 72 hours. |
| `email`     | string | ✔️       | Email address of the account being reset. |
| `newPassword` | string | ✔️    | Min 12 characters; same complexity rules as registration. |

### `GET /v1/me/tracking`

No request body. Query parameters:

| Parameter | Type    | Required | Description |
|-----------|---------|:--------:|-------------|
| `status`  | string  | No       | Filter by tracking status. Allowed: `Interested`, `Submitted`, `Accepted`. |
| `page`    | integer | No       | 1-based page number. Default: `1`. |
| `pageSize`| integer | No       | Default: `20`. Max: `100`. |

### `POST /v1/me/tracking/{cfpId}`

| Field    | Type   | Required | Constraints |
|----------|--------|:--------:|-------------|
| `status` | string | ✔️       | One of: `Interested`, `Submitted`, `Accepted`. |
| `notes`  | string | No       | Optional personal notes. Max 500 characters. |

Path: `cfpId` (UUID) — must identify an existing Approved CFP.

### `PUT /v1/me/tracking/{cfpId}`

| Field    | Type   | Required | Constraints |
|----------|--------|:--------:|-------------|
| `status` | string | ✔️       | One of: `Interested`, `Submitted`, `Accepted`. |
| `notes`  | string | No       | Optional personal notes. Max 500 characters. |

### `DELETE /v1/me/tracking/{cfpId}`

No request body. Path: `cfpId` (UUID).

### `GET /v1/me/preferences`

No request body. Returns the authenticated user's current notification preferences.

### `PUT /v1/me/preferences`

| Field               | Type    | Required | Constraints |
|---------------------|---------|:--------:|-------------|
| `deadlineReminders` | boolean | ✔️       | Enable/disable deadline reminder emails (7, 3, 1 day before CFP close date). |
| `weeklyDigest`      | boolean | ✔️       | Enable/disable weekly digest emails (Sunday 8 AM UTC). |

---

## Field Semantics and Constraints

- **Tracking status** follows a 3-state workflow: `Interested` (expressing initial interest), `Submitted` (submission has been sent to the conference), `Accepted` (talk has been accepted). Transitions in any direction are allowed — there is no enforced state machine for speaker tracking.
- **Deadline reminders** trigger emails from the `DeadlineReminderJob` (runs daily 6 AM UTC) for tracked CFPs at 7, 3, and 1 day before `cfpCloseDate`.
- **Weekly digest** includes new CFPs added in the past 7 days and CFPs closing within the next 7 days, sent Sunday 8 AM UTC.
- **Password reset token** is a signed JWT (`Jwt-SigningKey` from Key Vault). It is single-use — once consumed, the token is invalidated and subsequent attempts with the same token return `400`.
- **Session cookie** is `HttpOnly`, `Secure`, and `SameSite=Strict`. The 14-day sliding expiration resets on every authenticated request.
- **Passkey response** conforms to the WebAuthn PublicKeyCredential JSON serialization spec. The `Fido2NetLib` library validates the assertion server-side.

---

## Naming and Validation Rules

- Email addresses are normalized to lowercase before storage and lookup.
- Display names are trimmed of leading/trailing whitespace.
- Password validation follows ASP.NET Core Identity's `PasswordOptions` (configured to require min 12 chars, uppercase, lowercase, digit, symbol).
- All field names in JSON payloads use `camelCase`.
- Boolean preference fields default to `true` for new accounts (opt-out model).

---

## Request Validation and Governance Rules

- **Account creation** checks for duplicate email before creating the Identity user. Duplicate email returns `409 Conflict`.
- **Login lockout**: After 5 consecutive failed password login attempts for an account, the account is locked for 15 minutes. Lockout status is returned in the `401` response as `{ "lockedOut": true, "retryAfter": "..." }`.
- **App-level rate limits** (ASP.NET Core Rate Limiting middleware, per IP):
  - `POST /v1/account/login`: 10 attempts per 15 minutes
  - `POST /v1/account/register`: 5 per hour
  - `POST /v1/account/forgot-password`: 3 per hour per email (computed server-side, not by IP)
- **Password reset token** validation: expired tokens return `400` with `{ "error": "token_expired" }`. Already-used tokens return `400` with `{ "error": "token_used" }`.
- Tracking a CFP that the user is already tracking returns `409 Conflict` (use PUT to update).
- Tracking an archived or non-existent CFP returns `404 Not Found`.
- `DELETE /v1/me/tracking/{cfpId}` on a tracking record that does not exist returns `404 Not Found`.

---

## Execution Semantics

### Account Registration

1. Backend validates request body (FluentValidation).
2. Checks for duplicate email via Identity store.
3. Creates the Identity user record in Azure SQL.
4. Creates a default `NotificationPreference` record (both preferences defaulting to `true`).
5. Publishes a `user-account-created` event to the `user-accounts` Service Bus topic.
6. The `NotificationProcessor` sends a Welcome Email via Azure Communication Services.
7. Returns `201 Created` with the new user's public profile.

### Login

1. Backend validates request body.
2. For `password` login: `SignInManager.PasswordSignInAsync()` — validates credentials, checks lockout, issues cookie.
3. For `passkey` login: `Fido2NetLib` validates the WebAuthn assertion, `SignInManager` issues cookie on success.
4. For OAuth: redirect-based flow handled by ASP.NET Core OAuth middleware; cookie issued on callback.
5. Admin email check runs on every login to assign/remove the `Admin` claim.
6. Returns `200 OK` with the user's public profile and a `Set-Cookie` header.

### CFP Tracking

Tracking operations are synchronous writes directly to Azure SQL (not via Service Bus). The `UserCfpTracking` table has a unique composite index on `(UserId, CfpId)` enforcing single-tracking-per-user-per-CFP.

### Preferences

Preferences are synchronous reads and writes directly to the `NotificationPreference` table via the `NotificationPreferenceService`.

---

## Response Model

### `POST /v1/account/register` — Success (`201 Created`)

```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "email": "speaker@example.com",
  "displayName": "Alex Speaker"
}
```

### `POST /v1/account/login` — Success (`200 OK`)

```json
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "email": "speaker@example.com",
  "displayName": "Alex Speaker",
  "isAdmin": false
}
```

`Set-Cookie: .AspNetCore.Identity.Application=...; HttpOnly; Secure; SameSite=Strict; Max-Age=1209600`

### `GET /v1/me/tracking` — Success (`200 OK`)

```json
{
  "items": [
    {
      "cfpId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "eventName": "TechConf 2026",
      "cfpCloseDate": "2026-03-31",
      "status": "Submitted",
      "notes": "Talk: Event-Driven Architectures in .NET 10",
      "trackedAt": "2026-01-15T10:00:00Z",
      "updatedAt": "2026-02-01T08:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "pageSize": 20,
    "totalItems": 5,
    "totalPages": 1
  }
}
```

### `GET /v1/me/preferences` — Success (`200 OK`)

```json
{
  "deadlineReminders": true,
  "weeklyDigest": false
}
```

### `POST /v1/account/forgot-password` — Always Success (`200 OK`)

```json
{
  "message": "If that email is registered, a password reset link has been sent."
}
```

### Error Response

```json
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.5.1",
  "title": "Validation failed",
  "status": 400,
  "errors": {
    "password": ["Password must be at least 12 characters and include uppercase, lowercase, digit, and symbol."]
  },
  "traceId": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
}
```

---

## Status and Observability

Account and tracking endpoints are synchronous — no polling is required. All operations return the final result immediately.

Authentication events (success, failure, lockout) are logged via Serilog to Azure Log Analytics with `userId`, `loginMethod`, `ipAddress`, and `outcome` fields for security auditing.

---

## Error Handling

| HTTP Status | Condition |
|-------------|-----------|
| `400 Bad Request` | Validation failure, expired/used token. |
| `401 Unauthorized` | Invalid credentials; missing session cookie on authenticated endpoint. `lockedOut` flag included when applicable. |
| `404 Not Found` | CFP not found, tracking record not found. |
| `409 Conflict` | Duplicate email on registration; attempting to create a tracking record that already exists. |
| `429 Too Many Requests` | App-level rate limit exceeded. `Retry-After` header included. |
| `500 Internal Server Error` | Unhandled exception. Correlation ID included. |

---

## Security and Access Control

### Authentication

- **Session cookie** (HttpOnly, Secure, SameSite=Strict): Issued by ASP.NET Core Identity on successful login. Valid for 14 days with sliding expiration.
- **Passkey (WebAuthn/FIDO2)**: Assertion ceremony orchestrated by `Fido2NetLib`. Credential public keys stored in the `UserPasskeys` table.
- **Social login (OAuth)**: Google, GitHub, and Microsoft via `Microsoft.AspNetCore.Authentication.{Provider}` packages. Creates or links a local Identity user on first OAuth use.
- **Password reset JWT**: Single-use, 72-hour, signed with `Jwt-SigningKey` from Key Vault.

### Authorization

- `/v1/account/register`, `/v1/account/login`, `/v1/account/forgot-password`, `/v1/account/reset-password`: Anonymous. No authentication required.
- `/v1/account/logout`, `/v1/me/*`: Require a valid authenticated session cookie. Unauthenticated requests return `401 Unauthorized`.
- `isAdmin` flag in login response is set when the user's email appears in the `CFPCOMPASS_ADMIN_EMAILS` environment variable (sourced from Key Vault at runtime). Admin status is evaluated on every login.

### Consumer Identity Trust Model

These endpoints are exclusively for the Blazor Server web application. They are served on the internal Container Apps network and are not routed through APIM. There is no APIM subscription key requirement. The ASP.NET Core Identity middleware enforces authentication on all `/v1/me/*` routes via the `[Authorize]` attribute.

---

## Relationship to Other Artifacts

| Artifact | Relationship |
|----------|-------------|
| `docs/contracts/apis/admin.md` | Admin endpoints for user management (disable/enable accounts). |
| `docs/contracts/apis/submissions.md` | Anonymous submission flow for speakers who are also event organizers. |
| Architecture §5 (Authentication & Identity) | Full identity system design: ASP.NET Core Identity, passkeys, social login, session strategy. |
| Architecture §13 (Security Considerations) | Rate limiting, lockout policy, credential stuffing mitigations. |
| ADR-014 — Contract-first design | Spec-first requirement applies to these internal endpoints as well. |

---

## Notes and Comments

- The `forgot-password` endpoint always returns `200 OK` regardless of whether the email is registered. This prevents user enumeration by timing or response content.
- Passkey registration (adding a passkey to an existing account) is handled through the `/account/settings` page in the web UI, not through this API surface. It follows the WebAuthn attestation ceremony via a separate `/v1/account/passkey/register` flow (not listed here as it is a UI-driven interaction).
- Social login callback routes are not documented here because they are part of the ASP.NET Core OAuth middleware redirect flow. The callback endpoint (`/v1/account/{provider}/callback`) is an implementation detail, not a consumer-facing contract.
- Unsubscribe links in emails use a separate token-authenticated route (`/account/settings?unsubscribe={type}&token={jwt}`) that is processed by the Blazor Server page, not this API surface.

---

## References

- Architecture §5 — Authentication & Identity
- Architecture §8 — Email Architecture (welcome email, password reset email flows)
- Architecture §13 — Security Considerations (rate limiting, lockout)
- `Fido2NetLib` — FIDO2/WebAuthn .NET library
- RFC 8058 — List-Unsubscribe header specification
- ASP.NET Core Identity documentation
- WebAuthn Level 3 specification
