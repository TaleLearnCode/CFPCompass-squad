---
title: API Contracts — Index
description: Index of all CFP Compass REST API contract documents with descriptions and quick-reference endpoint tables.
tags:
  - api-contract
  - architecture
  - index
  - governance
---

# CFP Compass API Contracts

This directory contains the canonical API contract documents for all REST endpoints in `CfpCompass.Api`. Each contract document defines the governed interface, request/response models, validation rules, execution semantics, error handling, and security model for its endpoint group.

> **Design-first principle (ADR-014):** All REST endpoints must have an approved contract specification before implementation begins. OpenAPI 3.1 specs live in `docs/api/openapi/`. These contract documents are the prose complement to those machine-readable specs.

---

## Contract Documents

### [`cfps.md`](./cfps.md) — CFPs API Contract

Public read and write access to CFP listings via Azure API Management.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/v1/cfps` | API Key (read) | List approved CFPs with filtering, sorting, and pagination. 5-min APIM cache. |
| `GET` | `/v1/cfps/{id}` | API Key (read) | Get single approved CFP by ID. 1-min APIM cache. |
| `POST` | `/v1/cfps` | API Key (read-write) | Submit new CFP (enters moderation). Returns 202 Accepted. |
| `PUT` | `/v1/cfps/{id}` | API Key (read-write) | Update CFP (re-enters moderation). Returns 202 Accepted. |
| `GET` | `/v1/cfps/archive` | API Key (read) | List archived CFPs (>7 days past deadline). |
| `GET` | `/v1/cfps/{id}/history` | API Key (read) | Get moderation history for a recurring event's CFP. |

Rate limits: 100 req/min (read), 10 req/min (write).

---

### [`metadata.md`](./metadata.md) — Metadata API Contract

Reference data endpoints for taxonomy and geographic lookups. Heavily cached.

| Method | Path | Auth | Cache TTL |
|--------|------|------|-----------|
| `GET` | `/v1/topics` | API Key (read) | 60 min |
| `GET` | `/v1/categories` | API Key (read) | 60 min |
| `GET` | `/v1/countries` | API Key (read) | 24 h |
| `GET` | `/v1/countries/{code}/subdivisions` | API Key (read) | 24 h |
| `GET` | `/v1/regions` | API Key (read) | 24 h |

Reference data is seeded via EF Core migration. Categories and topics are admin-extensible.

---

### [`account.md`](./account.md) — Account & User API Contract

Speaker account lifecycle, session management, CFP tracking, and notification preferences. **Not exposed via APIM** — web application internal only.

| Method | Path | Auth |
|--------|------|------|
| `POST` | `/v1/account/register` | Anonymous |
| `POST` | `/v1/account/login` | Anonymous |
| `POST` | `/v1/account/logout` | Cookie session |
| `POST` | `/v1/account/forgot-password` | Anonymous |
| `POST` | `/v1/account/reset-password` | Anonymous (token) |
| `GET` | `/v1/me/tracking` | Cookie session |
| `POST` | `/v1/me/tracking/{cfpId}` | Cookie session |
| `PUT` | `/v1/me/tracking/{cfpId}` | Cookie session |
| `DELETE` | `/v1/me/tracking/{cfpId}` | Cookie session |
| `GET` | `/v1/me/preferences` | Cookie session |
| `PUT` | `/v1/me/preferences` | Cookie session |

Supports password login, passkey (WebAuthn via Fido2NetLib), and social login (Google, GitHub, Microsoft).

---

### [`submissions.md`](./submissions.md) — Submissions API Contract

Anonymous public CFP submission form workflow with Cloudflare Turnstile bot protection, token-authenticated editing, reconsideration, and async status polling. **Not exposed via APIM.**

| Method | Path | Auth |
|--------|------|------|
| `POST` | `/v1/submissions` | Anonymous (Turnstile) |
| `GET` | `/v1/submissions/{id}` | Token (72h, single-use) |
| `PUT` | `/v1/submissions/{id}` | Token (72h, single-use) |
| `POST` | `/v1/submissions/{id}/reconsider` | Token (72h, single-use) |
| `GET` | `/v1/submissions/{id}/status` | Anonymous |

CFP statuses: `OrganizerSubmitted` → `Pending` → `Approved` | `Rejected` → `Reconsidering`.

---

### [`claims.md`](./claims.md) — Organizer Claims API Contract

Organizer ownership claim flow for community-submitted CFP listings. **Not exposed via APIM.**

| Method | Path | Auth |
|--------|------|------|
| `POST` | `/v1/claims/{cfpId}` | Cookie session |
| `POST` | `/v1/claims/{cfpId}/verify` | Token (7d, single-use) |

Community submissions marked `organizerIsSubmitter = false` are published as "Unverified — Awaiting Organizer Claim." The organizer verifies via email token to achieve `OrganizerVerified` status.

---

### [`admin.md`](./admin.md) — Admin API Contract

Full moderation, user management, API key management, and admin dashboard. Requires `Admin` role (email match in `CFPCOMPASS_ADMIN_EMAILS`). **Not exposed via APIM.**

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/v1/admin/submissions` | Moderation queue (Pending + Reconsidering) |
| `POST` | `/v1/admin/submissions/{id}/approve` | Approve and publish CFP |
| `POST` | `/v1/admin/submissions/{id}/reject` | Reject with required reason |
| `GET` | `/v1/admin/users` | List users with search/filter |
| `PUT` | `/v1/admin/users/{id}/disable` | Disable user account |
| `PUT` | `/v1/admin/users/{id}/enable` | Re-enable user account |
| `GET` | `/v1/admin/api-requests` | Pending API key requests |
| `POST` | `/v1/admin/api-requests/{id}/approve` | Approve API key (sends email) |
| `POST` | `/v1/admin/api-requests/{id}/reject` | Reject API key request |
| `POST` | `/v1/admin/claims/{cfpId}/assign` | Admin-assisted claim assignment |
| `GET` | `/v1/admin/dashboard` | Summary metrics |

All admin actions logged to `AuditLog` table and Azure Log Analytics.

---

## Authentication Summary

| Mechanism | Used By |
|-----------|---------|
| APIM Subscription Key (`Ocp-Apim-Subscription-Key`) | External API consumers (CFPs, Metadata) |
| Cookie (HttpOnly, 14-day sliding) | Web app users (Account, Tracking, Admin) |
| JWT Token (email link, 72h) | Submission editing and reconsideration |
| JWT Token (email link, 7d) | Organizer claim verification |
| Cloudflare Turnstile | Anonymous public submission |

---

## Related Resources

| Resource | Purpose |
|----------|---------|
| `docs/api/openapi/cfp-compass-api-v1.yaml` | Machine-readable OpenAPI 3.1 spec (imported by APIM) |
| `docs/api/asyncapi/` | AsyncAPI 3.0 specs for Service Bus event contracts |
| `docs/contracts/events/` | Event contract documents (prose complement to AsyncAPI specs) |
| `docs/contracts/README.md` | Overview of the contracts section and contract-first approach |
| Architecture §4 | APIM topology, rate limits, caching strategy, async write pattern |
| Architecture §11 | Spec-first requirement and tooling (Spectral, oasdiff, AsyncAPI CLI) |
| ADR-014 | Contract-first API and event design decision record |
