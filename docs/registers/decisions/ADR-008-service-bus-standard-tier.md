---
title: "ADR-008: Azure Service Bus Standard Tier"
description: Azure Service Bus Standard tier is selected as the minimum tier providing topics, subscriptions, and dead-letter queues required for the event-driven write pattern at MVP cost.
tags:
  - adr
  - architecture-decision-record
  - azure-service-bus
status: accepted
---

# Azure Service Bus Standard Tier

- **Status:** Accepted
- **Date:** 2026-03-01
- **Work Item:** [*arch-008* — message broker tier selection]

## Context and Problem

The event-driven write pattern (ADR-007) requires a message broker that supports topics and subscriptions for fan-out (one write event triggering multiple subscribers: SQL write, cache invalidation, and notifications). The broker must also provide dead-letter queues to capture failed messages for monitoring and replay. Three Azure Service Bus tiers are available: Basic (queues only), Standard (topics + subscriptions + dead-letter, shared infrastructure), and Premium (dedicated compute, higher throughput). A tier must be selected that meets the functional requirements at MVP cost.

## Decision Drivers

- Topics and subscriptions for fan-out to multiple subscribers from a single published event
- Dead-letter queues to capture and monitor failed message processing
- Adequate throughput for MVP write volume (low-frequency CFP submissions and moderation actions)
- Cost-appropriate for MVP (~$10/month target)
- Standard .NET SDK compatibility (Azure.Messaging.ServiceBus)

## Considered Options

- Azure Service Bus Standard tier
- Azure Service Bus Basic tier
- Azure Service Bus Premium tier

## Decision Outcome

Chosen option: **Azure Service Bus Standard tier**, because it is the minimum tier that provides topics and subscriptions (required for fan-out) and dead-letter queues (required for failure handling). The Standard tier's ~$10/month cost is appropriate for MVP volume, and the shared infrastructure model is acceptable given the low message throughput of CFP submission and moderation workflows.

#### Consequences

- Good, because topics and subscriptions enable fan-out: a single `cfp-submission-created` event can be consumed by both the SQL write Function and the cache invalidation Function independently.
- Good, because dead-letter queues capture failed messages after maximum retries — Application Insights alerts monitor dead-letter queue depth.
- Good, because ~$10/month is cost-effective for MVP message volume.
- Good, because the Azure.Messaging.ServiceBus SDK is used consistently — no tier-specific SDK changes.
- Good, because .NET Aspire's `Aspire.Azure.Messaging.ServiceBus` integration package works with Standard tier.
- Bad, because shared infrastructure (not dedicated) — acceptable for MVP but could become a concern under unexpectedly high load.
- Bad, because Standard tier has a maximum message size of 256 KB — sufficient for CFP event payloads but must be monitored.

#### Implementation

1. Parker provisions the `infra/modules/service-bus/` Terraform module with `sku = "Standard"`.
2. Topics provisioned in Terraform:
   - `cfp-submission-created`
   - `cfp-submission-updated`
   - `cfp-submission-approved`
   - `cfp-submission-rejected`
   - `cfp-submission-reconsideration`
   - `organizer-claim-requested`
3. Each topic has two subscriptions:
   - `sql-write` — processed by the SQL write Function
   - `cache-invalidation` — processed by the CacheInvalidationProcessor Function
4. Dead-letter queue monitoring: Application Insights alert fires when dead-letter queue depth exceeds 10 messages.
5. `ServiceBus-ConnectionString` stored in Key Vault; Container Apps (API) and Functions resolve via managed identity.

#### Confirmation

- Fan-out confirmed: a single published event is received by both `sql-write` and `cache-invalidation` subscriptions independently.
- Dead-letter queue receives message after simulated permanent Function failure (confirmed in integration test).
- Application Insights alert fires when dead-letter queue depth > 10 in dev environment.
- Message throughput under load test (50 concurrent submissions) remains within Standard tier limits.

#### Stakeholders

- **Dallas (Lead & Architect):** Decision owner; defined fan-out and dead-letter requirements
- **Parker (DevOps):** Provisions Service Bus namespace, topics, and subscriptions via Terraform
- **Ripley (Backend):** Implements Service Bus publisher in API; implements Function consumers
- **Kane (Tester):** Tests fan-out behaviour, dead-letter queue behaviour, and alert thresholds

## Pros and Cons of the Options

### Azure Service Bus Standard Tier

- Good, because topics and subscriptions enable multi-subscriber fan-out — the only tier that supports this.
- Good, because dead-letter queues are built in — failed messages are automatically captured without code.
- Good, because ~$10/month for MVP volume — predictable cost.
- Good, because Standard tier message ordering and duplicate detection features available.
- Neutral, because shared infrastructure — adequate for MVP but not isolated.
- Bad, because maximum message size 256 KB — sufficient for current payloads but may require chunking for large event schemas in future.

### Azure Service Bus Basic Tier

- Good, because cheapest tier (~$0.05/million operations).
- Good, because simple queue model for basic use cases.
- Bad, because queues only — no topics or subscriptions. Fan-out would require publishing to multiple queues manually — violates the single-publish pattern.
- Bad, because no dead-letter queue — failed messages require custom poison-message handling.
- Bad, because does not meet functional requirements for the event-driven write pattern as designed.

### Azure Service Bus Premium Tier

- Good, because dedicated compute — predictable latency and throughput.
- Good, because supports VNet integration for isolated namespace.
- Good, because higher message size limit (100 MB).
- Good, because geo-disaster recovery built in.
- Neutral, because same SDK and API as Standard tier — no code changes.
- Bad, because ~$677/month (minimum 1 Messaging Unit) — wildly over-engineered for MVP volume.
- Bad, because cost increase cannot be justified until write throughput demands dedicated capacity.

## More Information

Azure Service Bus tier comparison: https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-premium-messaging

Service Bus topic-per-aggregate pattern: each domain aggregate (CfpSubmission, OrganizerClaim) has its own topic. This prevents consumer interference between unrelated aggregates and makes it easy to add new consumers for a specific aggregate without affecting others.

The AsyncAPI 3.0.0 specifications for each topic are located in `docs/api/asyncapi/`. All topic schemas must be defined in an approved AsyncAPI spec before implementation (ADR-014).

**Upgrade path:** Standard → Premium when any of the following occurs:
- Message throughput exceeds Standard tier shared capacity limits (visible via Service Bus metrics)
- VNet isolation for the Service Bus namespace is required for compliance
- Message size requirements exceed 256 KB

## Follow-On Information

No near-term changes anticipated. Monitor dead-letter queue depth and message processing latency via Application Insights. If dead-letter depth persistently exceeds threshold, investigate Function processing failures before considering a tier upgrade.

## Record History

* **Proposed**: 2026-03-01
* **Accepted**: 2026-03-01
* **Last Reviewed**: 2026-03-01
