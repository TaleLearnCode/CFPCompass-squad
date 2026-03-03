---
title: Event Contracts — Index
description: Index of all CFP Compass Service Bus event contract documents with descriptions and topic/consumer mappings.
tags:
  - event-contract
  - architecture
  - index
  - governance
  - service-bus
---

# CFP Compass Event Contracts

This directory contains the canonical event contract documents for all Azure Service Bus events in CFP Compass. Each contract defines the event overview, subscription details, message schema, processing rules, error handling, and governance for its event type.

> **Design-first principle (ADR-014):** All Service Bus topics and their message schemas must have an approved AsyncAPI 3.0.0 specification before any producer or consumer implementation begins. AsyncAPI specs live in `docs/api/asyncapi/`. These contract documents are the prose complement to those machine-readable specs.

---

## Service Bus Topology

| Service Bus Namespace | Tier | Pattern |
|-----------------------|------|---------|
| `sbns-cfpcompass.{env}` | Standard | Topic-per-aggregate |

| Topic | Aggregate | Description |
|-------|-----------|-------------|
| `cfp-submissions` | CFP Submission lifecycle | All events related to CFP submission creation, updates, approval, rejection, and reconsideration. |
| `organizer-claims` | Organizer ownership claims | Events for organizer claim initiation and verification. |

---

## Event Contract Documents

### `cfp-submissions` Topic

#### [`cfp-submission-created.md`](./cfp-submission-created.md)

Published when a new CFP submission passes validation and bot protection. Initiates the asynchronous write pipeline.

| Property | Value |
|----------|-------|
| **Topic** | `cfp-submissions` |
| **Producer** | `CfpCompass.Api` (`POST /api/v1/submissions`, `POST /api/v1/cfps`) |
| **Consumers** | `CfpSubmissionProcessor`, `StatusUpdateProcessor`, `NotificationProcessor` |
| **Triggers** | Write CFP to Azure SQL (Pending status), submission confirmation email with edit token link, duplicate detection |

---

#### [`cfp-submission-updated.md`](./cfp-submission-updated.md)

Published when a submitter edits a CFP in `Pending` or `Rejected` status using their edit token.

| Property | Value |
|----------|-------|
| **Topic** | `cfp-submissions` |
| **Producer** | `CfpCompass.Api` (`PUT /api/v1/submissions/{id}`, `PUT /api/v1/cfps/{id}`) |
| **Consumers** | `CfpSubmissionProcessor`, `StatusUpdateProcessor` |
| **Triggers** | Update CFP fields in Azure SQL, reset status to Pending for re-review |

---

#### [`cfp-submission-approved.md`](./cfp-submission-approved.md)

Published when an admin approves a CFP submission, making it publicly visible.

| Property | Value |
|----------|-------|
| **Topic** | `cfp-submissions` |
| **Producer** | `CfpCompass.Api` (`POST /api/v1/admin/submissions/{id}/approve`) |
| **Consumers** | `CfpSubmissionProcessor`, `NotificationProcessor`, `CacheInvalidationProcessor` |
| **Triggers** | Approval notification email, organizer claim invitation (if `organizerIsSubmitter = false`), APIM + Redis cache invalidation |

---

#### [`cfp-submission-rejected.md`](./cfp-submission-rejected.md)

Published when an admin rejects a CFP submission with a required reason.

| Property | Value |
|----------|-------|
| **Topic** | `cfp-submissions` |
| **Producer** | `CfpCompass.Api` (`POST /api/v1/admin/submissions/{id}/reject`) |
| **Consumers** | `CfpSubmissionProcessor`, `NotificationProcessor` |
| **Triggers** | Rejection notification email with reason and reconsideration link (72h token) |

---

#### [`cfp-submission-reconsideration-requested.md`](./cfp-submission-reconsideration-requested.md)

Published when a submitter requests reconsideration of a rejected submission using the token from the rejection email.

| Property | Value |
|----------|-------|
| **Topic** | `cfp-submissions` |
| **Producer** | `CfpCompass.Api` (`POST /api/v1/submissions/{id}/reconsider`) |
| **Consumers** | `CfpSubmissionProcessor`, `NotificationProcessor` |
| **Triggers** | Update CFP status to Reconsidering, reconsideration confirmation email to submitter |

---

### `organizer-claims` Topic

#### [`organizer-claim-requested.md`](./organizer-claim-requested.md)

Published when an authenticated speaker initiates an organizer ownership claim for an unverified CFP listing.

| Property | Value |
|----------|-------|
| **Topic** | `organizer-claims` |
| **Producer** | `CfpCompass.Api` (`POST /api/v1/claims/{cfpId}`) |
| **Consumers** | `CacheInvalidationProcessor`, `NotificationProcessor` |
| **Triggers** | Update CFP detail status to "Organizer Claim Pending," claim invitation email with verification token (7d) to `contactEmail` |

---

## Event Lifecycle Overview

### CFP Submission Lifecycle

```
POST /api/v1/submissions
        │
        ▼
cfp-submission-created ──► CfpSubmissionProcessor ──► CFP: Pending
                      └──► NotificationProcessor ──► Confirmation email
                      └──► StatusUpdateProcessor ──► ProcessingStatus: Completed
        │
        │ (Admin reviews)
        ├──► cfp-submission-approved ──► CFP: Approved
        │                          └──► Approval email
        │                          └──► Cache invalidation
        │                          └──► [if !organizerIsSubmitter] Claim invitation
        │
        └──► cfp-submission-rejected ──► CFP: Rejected
                                    └──► Rejection email (reason + reconsider link)
                                          │
                                          │ (Submitter requests reconsideration)
                                          ▼
                    cfp-submission-reconsideration-requested ──► CFP: Reconsidering
                                                            └──► Confirmation email
                                                                  │
                                                                  │ (Admin re-reviews)
                                                                  └──► approve/reject again
```

### Organizer Claim Lifecycle

```
[CFP Approved with organizerIsSubmitter = false]
        │
        │ CFP status: UnverifiedAwaitingClaim
        │
        ▼ (Speaker claims via POST /api/v1/claims/{cfpId})
organizer-claim-requested ──► CacheInvalidationProcessor ──► CFP detail: "Claim Pending"
                         └──► NotificationProcessor ──► Claim invitation email (7d token)
        │
        │ (Organizer verifies via POST /api/v1/claims/{cfpId}/verify)
        ▼
CFP status: OrganizerVerified (synchronous)
```

---

## Azure Functions Consumer Summary

| Function | Topics Subscribed | Responsibilities |
|----------|-------------------|-----------------|
| `CfpSubmissionProcessor` | `cfp-submissions` | Write CFP records, update status, duplicate detection, process reconsideration |
| `StatusUpdateProcessor` | `cfp-submissions` | Update `ProcessingStatus` records for caller polling |
| `NotificationProcessor` | `cfp-submissions`, `organizer-claims` | Send all transactional emails via Azure Communication Services |
| `CacheInvalidationProcessor` | `cfp-submissions`, `organizer-claims` | Purge APIM response cache and Redis keys on write events |

---

## Related Resources

| Resource | Purpose |
|----------|---------|
| `docs/api/asyncapi/cfp-submissions.asyncapi.yaml` | AsyncAPI 3.0 spec for the `cfp-submissions` topic |
| `docs/api/asyncapi/organizer-claims.asyncapi.yaml` | AsyncAPI 3.0 spec for the `organizer-claims` topic |
| `docs/contracts/apis/` | REST API contract documents |
| `docs/contracts/README.md` | Overview of the contract-first approach (ADR-014) |
| Architecture §7 | Service Bus processors, Azure Functions topology |
| Architecture §11 | AsyncAPI spec tooling and approval gates |
| ADR-007 | Event-driven async writes decision |
| ADR-014 | Contract-first API and event design |
