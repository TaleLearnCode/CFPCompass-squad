---
title: Process Flows
description: Index of all CFP Compass process flow documents covering submission, moderation, speaker tracking, organizer claims, and the asynchronous write pattern.
tags:
  - process-flow
  - architecture
  - index
---

# CFP Compass — Process Flows

Process flow documents describe the end-to-end behavior of key business and technical processes in CFP Compass. Each document includes sequence diagrams (Mermaid), actor/system tables, numbered step-by-step descriptions, and coverage of happy paths, primary alternatives, and error/exception flows.

---

## Documents

| Document | Title | Description |
|---|---|---|
| [cfp-submission.md](cfp-submission.md) | CFP Submission Process Flow | Public CFP submission from form fill through Cloudflare Turnstile bot protection, FluentValidation, Service Bus event publishing, async Azure Function processing, and confirmation email. Covers community contributor and edit-submission alternatives, plus Turnstile failure, validation failure, and Service Bus unavailability error flows. |
| [cfp-moderation.md](cfp-moderation.md) | CFP Moderation Process Flow | Admin review queue for pending submissions, with approval (cache invalidation + notification email), rejection (reason + reconsideration link), and the reconsideration request flow. Covers duplicate detection flag handling as an exception flow. |
| [speaker-cfp-tracking.md](speaker-cfp-tracking.md) | Speaker CFP Tracking Process Flow | Three-state speaker engagement workflow (Interested → Submitted → Accepted), dashboard filtering, daily deadline reminder emails, and weekly digest emails. Covers unauthenticated access and duplicate tracking attempt error flows. |
| [organizer-claim.md](organizer-claim.md) | Organizer Claim Verification Process Flow | Email-token-based organizer ownership verification for community-submitted CFPs. Covers the claim invitation (post-approval), organizer email verification, admin fallback assignment, re-send invitation, and expired/already-claimed token error flows. |
| [api-write-pattern.md](api-write-pattern.md) | Asynchronous Write Pattern (Event-Driven) | Generic pattern used by all POST/PUT write operations via APIM. Documents APIM subscription key validation, rate limiting, Service Bus event publishing, async Azure Function processing, status polling, and idempotency semantics. Covers validation failure, rate limit exceeded, and dead-letter error flows. |

---

## Pattern Summary

All write operations (POST/PUT via APIM) use the asynchronous write pattern documented in `api-write-pattern.md`. The specific business flows (submission, moderation, tracking, claim) use this pattern and layer their domain logic on top of it.

```
Consumer → APIM → API (validate + publish) → Service Bus → Function Processor → Azure SQL
                                ↓
                     202 Accepted + statusUrl
                                ↓
              Consumer polls GET statusUrl → Pending → Completed
```

Read operations (GET) are synchronous and served from APIM response cache (5-minute TTL for listings, 1-minute for detail) backed by Azure SQL. Cache invalidation is triggered by Service Bus events after successful write processing.

---

## Related Documents

- [Data Models README](../data-models/README.md) — Index of all data model documents
- [Architecture Document](./../.squad/architecture.md) — Full system architecture reference
