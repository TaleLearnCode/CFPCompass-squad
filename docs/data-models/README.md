---
title: Data Models
description: Index of all CFP Compass data model documents covering the core relational schema backed by Azure SQL Database with EF Core 10.
tags:
  - data-model
  - architecture
  - index
---

# CFP Compass — Data Models

All entities use EF Core 10 with Azure SQL Database (Serverless). Common patterns applied across all entities:

- **Value converters** — enums persisted as strings for readability and migration safety
- **Interceptors** — `CreatedAt` / `UpdatedAt` auto-stamped on every save
- **Global query filters** — `IsArchived == false` applied by default; archive queries use `IgnoreQueryFilters()`
- **Repository pattern** — thin wrappers over `DbContext` for testability
- **Specification pattern** — complex query composition for filtered listing queries

---

## Documents

| Document | Entity / Entities | Description |
|---|---|---|
| [cfp.md](cfp.md) | `Cfp` | Core CFP listing entity with 30+ fields covering event details, scheduling, geographic classification, speaker coverage, and the full moderation lifecycle. Includes many-to-many relationships to Category and Topic via junction tables. |
| [user.md](user.md) | `User`, `UserPasskeys`, `NotificationPreference` | User identity entities extending ASP.NET Core Identity. Covers passkey (FIDO2) credential storage, notification preferences, and admin identification via environment-variable email matching. |
| [taxonomy.md](taxonomy.md) | `Category`, `Topic`, `CfpListingCategory`, `CfpTopic` | Controlled vocabulary for CFP classification. 10 primary domain categories and 10 secondary tag groups with ~100 tags, seeded via EF Core `HasData()`. Admin-extensible. Junction tables support OR-logic filtering on listing pages. |
| [cfp-tracking.md](cfp-tracking.md) | `UserCfpTracking` | Speaker engagement workflow entity. Records a speaker's three-state progression (Interested → Submitted → Accepted) for each tracked CFP. Drives deadline reminder and weekly digest email jobs. |
| [moderation.md](moderation.md) | `ModerationAction`, `AuditLog` | Append-only audit and compliance entities. Every admin moderation decision (approve, reject, reconsider, duplicate-flag) is recorded in `ModerationAction`; all admin actions across the platform are written to `AuditLog` in the same transaction. |
| [claim.md](claim.md) | `ClaimRequest` | Organizer claim verification entity. Manages the lifecycle of claim invitations (single-use hashed tokens, 7-day expiry) for community-submitted CFPs awaiting organizer ownership. Supports admin fallback assignment. |
| [reference-data.md](reference-data.md) | `Country`, `Subdivision`, `WorldRegion`, `ApiKeyRequest`, `EmailLog` | ISO 3166-1/3166-2 and UN M.49 geographic reference data seeded from standards. API key request lifecycle management via APIM integration. Append-only email delivery log for operational tracking and audit. |

---

## Entity Relationship Summary

```
User ──────────────────────────────────────────────────────────┐
  │                                                            │
  │ (SubmitterId / OrganizerId)                               │
  ▼                                                           │
 Cfp ──── CfpListingCategory ──── Category                   │
  │  └─── CfpTopic ──────────── Topic                        │
  │                                                           │
  ├── ModerationAction ◄── User (AdminUserId)                │
  ├── ClaimRequest ◄──── User (ClaimantId)                   │
  ├── UserCfpTracking ◄── User (UserId) ─────────────────────┘
  │
  ├── Country ──► Subdivision
  └── WorldRegion (auto-assigned from Country)

User ─── UserPasskeys
User ─── NotificationPreference
User ─── ApiKeyRequest
User ─── EmailLog (nullable)

ModerationAction ───► AuditLog (companion write, same transaction)
```

---

## Key Design Decisions

| Decision | Rationale |
|---|---|
| Azure SQL Database (Serverless) | Relational data model with FK constraints; EF Core maturity; auto-pause for cost savings; familiar to .NET contributors |
| EF Core 10 code-first | Version-controlled schema evolution; LINQ querying; change tracking for audit |
| Enums as strings | Human-readable in SQL queries; migration-safe (no integer mapping concerns) |
| GUIDs for entity PKs | Non-enumerable IDs in API paths; safe for distributed insertion by Azure Function processors |
| Integer PKs for taxonomy | Compact FK size on high-frequency junction table joins |
| ISO natural keys for Country/Subdivision | Self-documenting FK columns; no join needed to read country code on CFP records |
| Soft-delete (IsArchived) | Preserves referential integrity; supports CFP history feature; audit compliance |
| Append-only for ModerationAction and AuditLog | Immutable audit trail; no retrospective modification of compliance records |
