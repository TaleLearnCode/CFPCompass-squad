---
title: Claim Data Model
description: ClaimRequest entity managing the organizer claim verification flow for community-submitted CFP listings.
tags:
  - data-model
  - architecture
  - claim
  - organizer
  - verification
---

# Claim Data Model

## Purpose

The `ClaimRequest` entity is the system-of-record for organizer claim verification — the process by which a CFP listing submitted by a community contributor is linked to its verified event organizer. When a CFP is submitted by someone who is not the event organizer (`IsSubmitterOrganizer = false`), the listing is published as "Unverified — Awaiting Organizer Claim." A claim invitation is sent to the organizer's contact email, and the claim lifecycle is tracked through this entity.

This model is authoritative. All claim records are created by the `NotificationProcessor` Azure Function following a CFP approval event and resolved through either the organizer's verification action (email token) or an admin override.

The purpose of this model is to provide accountability for CFP listings — ensuring that published listings have a path to organizer ownership — while not blocking publication on community-contributed CFPs.

## Schema Definition

### ER Diagram

```mermaid
erDiagram
    CLAIM_REQUEST {
        uuid Id PK
        uuid CfpId FK
        uuid ClaimantId FK
        string OrganizerContactEmail
        string TokenHash
        datetime TokenExpiry
        string Status
        datetime RequestedAt
        datetime VerifiedAt
    }

    CFP {
        uuid Id PK
        string EventName
        string ClaimStatus
        uuid OrganizerId FK
    }

    USER {
        uuid Id PK
        string Email
        string DisplayName
    }

    AUDIT_LOG {
        uuid Id PK
        string Action
        string TargetEntityType
        string TargetEntityId
    }

    CFP ||--o{ CLAIM_REQUEST : "claim history"
    USER ||--o{ CLAIM_REQUEST : "ClaimantId"
    CLAIM_REQUEST ..o{ AUDIT_LOG : "audit events"
```

### Fields

| Field | Type | Nullable | Description |
|---|---|---|---|
| `Id` | `uuid` | No | Primary key. GUID generated when the claim invitation is created. |
| `CfpId` | `uuid` | No | FK to `Cfp.Id`. The CFP listing that this claim is for. Indexed. |
| `ClaimantId` | `uuid` | Yes | FK to `User.Id`. Set when an organizer verifies their identity by clicking the email link and authenticating (or creating an account). Null until verification is complete. |
| `OrganizerContactEmail` | `nvarchar(320)` | No | The email address to which the claim invitation was sent. Sourced from `Cfp.OrganizerContactEmail` at the time the claim is created. Stored for reference in case the CFP field is later updated. |
| `TokenHash` | `nvarchar(500)` | No | SHA-256 hash of the single-use verification token embedded in the claim invitation email link. The plaintext token is never stored; only the hash is persisted. |
| `TokenExpiry` | `datetimeoffset` | No | Expiry timestamp for the verification token. Set to 7 days from `RequestedAt`. After this timestamp, the token is invalid and a new claim must be initiated. |
| `Status` | `nvarchar(50)` | No | Enum stored as string. See status values below. |
| `RequestedAt` | `datetimeoffset` | No | Timestamp when the claim invitation was created and the email was dispatched. |
| `VerifiedAt` | `datetimeoffset` | Yes | Timestamp when the claim was resolved (either verified by the organizer or assigned by an admin). Null until resolution. |

### Claim Status Enum Values

| Value | Meaning |
|---|---|
| `Pending` | Claim invitation email has been sent. Awaiting organizer action. Token is valid. |
| `Verified` | Organizer clicked the email link, confirmed their identity, and the claim is accepted. `ClaimantId` is set. `Cfp.OrganizerId` is updated. |
| `AdminAssigned` | Admin manually assigned an organizer to the CFP via the admin dashboard (fallback path). `ClaimantId` is set to the admin-selected user. |
| `Expired` | The token expiry date has passed without organizer verification. A new claim invitation may be re-sent by admin action. |

### CFP Claim Status Field (Cross-Reference)

The `Cfp.ClaimStatus` field mirrors the resolved state for quick listing queries and display. It is updated in the same transaction as the `ClaimRequest.Status`:

| Cfp.ClaimStatus | Meaning |
|---|---|
| `Unclaimed` | Community-submitted CFP; no claim invitation sent yet (or organizer email not provided) |
| `PendingVerification` | Claim invitation sent; awaiting organizer response |
| `OrganizerVerified` | Claim verified by organizer via email token |
| `AdminAssigned` | Organizer assigned by admin override |

## Partitioning and Identifier Strategy

**Primary Key:** `Id` — GUID. Generated at claim invitation creation time.

**Indexed Columns:**
- `CfpId` — retrieve all claim requests for a given CFP (supports `GetClaimByCfpId`)
- `Status` — admin pending claims queue (`GetPendingClaims`)
- `TokenExpiry` — identify and mark expired claims in the `CfpExpiryJob` or a dedicated clean-up pass

**Token Security:** The verification token is a cryptographically random value generated server-side (e.g., 32 bytes from `RandomNumberGenerator`). The token is embedded in the email link URL and never returned in any API response. Only the SHA-256 hash is persisted in `TokenHash`. On verification, the submitted token is hashed and compared to `TokenHash`. This prevents token exposure if the database is compromised.

**Single active claim per CFP:** A CFP should have at most one active (`Pending`) claim request at a time. The application enforces this in the claim creation logic — if a `Pending` claim exists, a new one is not created. A new claim may be initiated after the previous one expires or is invalidated.

## Data Source and Lifecycle

### Authoritative Source

CFP Compass is the system of record for all `ClaimRequest` data. Records are created by the `NotificationProcessor` Azure Function in response to `cfp-submission-approved` events where `Cfp.IsSubmitterOrganizer = false` and `Cfp.OrganizerContactEmail` is not null.

### Ingestion Flow

```
cfp-submission-approved event consumed (community-submitted CFP)
    │
    └── IsSubmitterOrganizer = false AND OrganizerContactEmail present?
        │
        ├── Yes:
        │   ├── Generate random token
        │   ├── Hash token → TokenHash
        │   ├── Insert ClaimRequest { Status = 'Pending', TokenExpiry = now + 7 days }
        │   ├── Update Cfp.ClaimStatus = 'PendingVerification'
        │   └── Send claim invitation email to OrganizerContactEmail
        │       (link: /claim/{cfpId}?token={plaintext-token})
        │
        └── No (OrganizerContactEmail absent):
            ├── Insert ClaimRequest { Status = 'Pending' }
            └── Update Cfp.ClaimStatus = 'Unclaimed'

Organizer clicks verification link
    │
    ▼
POST /api/v1/claims/{cfpId}/verify?token={plaintext-token}
    │
    ├── Hash submitted token → compare to ClaimRequest.TokenHash
    ├── Check: TokenExpiry > now
    ├── Check: Status = 'Pending'
    ├── Organizer authenticated? (require login or account creation)
    ├── Update ClaimRequest { Status = 'Verified', ClaimantId = userId, VerifiedAt = now }
    ├── Update Cfp { OrganizerId = userId, ClaimStatus = 'OrganizerVerified' }
    └── Write AuditLog { Action = 'ClaimVerified' }

Token expired — Admin fallback
    │
    ▼
Admin navigates to /admin/manage-claims
    │
    ├── Admin selects organizer user from lookup
    └── POST /api/v1/admin/claims/{cfpId}/assign { "userId": "{id}" }
        ├── Update ClaimRequest { Status = 'AdminAssigned', ClaimantId = userId, VerifiedAt = now }
        ├── Update Cfp { OrganizerId = userId, ClaimStatus = 'AdminAssigned' }
        └── Write AuditLog { Action = 'ClaimAssigned' }
```

### Lifecycle Management

- **Token expiry:** The `CfpExpiryJob` (or a dedicated pass within it) checks for `ClaimRequest` records where `Status = 'Pending'` and `TokenExpiry < GETUTCDATE()`, updating them to `Status = 'Expired'` and `Cfp.ClaimStatus = 'Unclaimed'`. Admins are notified (via the manage-claims dashboard) that the claim has lapsed.
- **Re-invitation:** An admin may trigger a new claim invitation for an expired claim from the manage-claims dashboard. This creates a new `ClaimRequest` record (not updates the expired one) and re-sends the email.
- **Append semantics:** Expired claims are retained for audit purposes. A new `ClaimRequest` record is always created for a re-invitation rather than reusing or updating an expired record.

## Access Patterns

### Supported Patterns

| Pattern | Query Characteristics | Notes |
|---|---|---|
| `GetPendingClaims` | Filter `Status = 'Pending'`; include `Cfp` navigation; order by `RequestedAt ASC` | Admin manage-claims dashboard |
| `GetClaimByToken` | Hash submitted token; filter by `TokenHash`, `Status = 'Pending'`, `TokenExpiry > now` | Verification endpoint |
| `GetClaimByCfpId` | Filter by `CfpId`; order by `RequestedAt DESC` | CFP detail panel (admin) — shows claim history for the CFP |
| `GetExpiredPendingClaims` | Filter `Status = 'Pending'`, `TokenExpiry < now` | Expiry clean-up job |
| `GetClaimsByStatus` | Filter by `Status` | Admin reporting — count of claims by state |

### Unsupported Patterns

- **Token plaintext retrieval:** Tokens are never retrieved from the database in plaintext. The verification endpoint accepts a plaintext token from the URL, hashes it, and compares against `TokenHash`.
- **Claim transfer:** Once a claim is `Verified` or `AdminAssigned`, it cannot be transferred to a different user via the normal flow. Re-assignment requires a new admin override action, which produces a new `ClaimRequest` record and a new `AuditLog` entry.

## Governance and Retention

**Write access:**
- `ClaimRequest` records are created by the `NotificationProcessor` Azure Function
- Status transitions to `Verified` are performed by the claim verification endpoint
- Status transitions to `AdminAssigned` are performed by the admin claims endpoint
- Status transitions to `Expired` are performed by the `CfpExpiryJob`
- No user-facing endpoint creates claim records directly

**Read access:**
- Admin users may read all claim records (manage-claims dashboard)
- Organizers who have completed a claim may view their claim status on their organizer dashboard
- No public endpoint exposes claim data

**Schema evolution:** The `Status` enum is the primary evolution surface. New status values must be added to both the database migration and the application-layer enum validator. The `TokenHash` column uses SHA-256; if a hashing algorithm change is required, a migration must handle re-hashing or a grace period for old tokens.

**Retention:** Claim records are retained permanently for audit purposes, including expired and superseded records. This provides a complete history of all claim attempts for a given CFP, which is useful for investigating disputes over organizer ownership.

## Design Notes

**Why hash the token rather than store it encrypted?** Hashing is one-way — even if the database is compromised, the attacker cannot recover valid tokens to use against the verification endpoint. Encryption would require key management and introduces the risk of key exposure. For single-use verification tokens, a hash is the correct choice.

**Why 7-day token expiry?** Seven days balances responsiveness (the organizer should act promptly) with practicality (the organizer may be traveling, at a conference, or on leave). The admin fallback ensures that expiry does not permanently block a CFP from gaining an organizer. If the organizer does not act within 7 days, an admin can assist.

**Why create a new ClaimRequest on re-invitation rather than reuse the expired one?** Append semantics preserve the complete history of claim attempts. Reusing an expired record would erase the history of the first attempt. A new record with a new token hash ensures the previous token remains definitively invalid and the new one is clearly separate.

**Why update Cfp.ClaimStatus in the same transaction?** `Cfp.ClaimStatus` is a denormalized read-side field that enables the listing page and admin queue to display claim state without joining to `ClaimRequest`. Updating it in the same transaction as the `ClaimRequest` status change ensures consistency. If the transaction rolls back, neither field changes.

## Related Specifications

- [Architecture Document — Section 3: Data Architecture](./../.squad/architecture.md)
- [Organizer Claim Verification Process Flow](../process-flows/organizer-claim.md)
- [CFP Data Model](cfp.md)
- [User Data Model](user.md)
- [Moderation Data Model](moderation.md)
