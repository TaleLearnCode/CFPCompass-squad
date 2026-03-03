---
title: "ADR-005: Azure Managed Redis over Azure Cache for Redis"
description: Supersedes the original Azure Cache for Redis selection with Azure Managed Redis (C0, Redis 7.x), Microsoft's designated long-term replacement, to eliminate retirement risk ahead of the Azure Cache for Redis end-of-life date of 30 September 2028.
tags:
  - adr
  - architecture-decision-record
  - azure-redis
  - redis
  - caching
status: accepted
---
# Azure Managed Redis over Azure Cache for Redis

- **Status:** Accepted
- **Date:** 2026-03-01 (revised)
- **Work Item:** [*arch-005* — distributed cache service selection]

## Context and Problem

CFP Compass requires a distributed cache for API response caching, session state, and reference data (ISO 3166 countries, IANA time zones, taxonomy). The cache must survive container restarts, support multiple Container App replicas, and provide sub-millisecond read latency for cached CFP listings. The original architecture decision (v1) selected Azure Cache for Redis. During architecture review on 2026-03-01, it was identified that Azure Cache for Redis is scheduled for retirement on **30 September 2028**. Microsoft's designated replacement is **Azure Managed Redis**, built on Redis 7.x with the same managed service experience. This ADR supersedes the original cache selection and formalises the switch to Azure Managed Redis.

## Decision Drivers

- Distributed cache that survives container restarts and supports horizontal scaling of Container App replicas
- Sub-millisecond read latency for cached APIM responses and session data
- No retirement risk — must be a service with a long-term Azure support commitment
- Consistent Redis protocol compatibility with StackExchange.Redis client library
- Minimal migration effort from the original Azure Cache for Redis selection
- Cost-appropriate for MVP (C0 tier: 1 GB, no replication)

## Considered Options

- Azure Managed Redis (C0) — Microsoft's replacement for Azure Cache for Redis
- Azure Cache for Redis (C0) — the retiring service
- Containerised Redis (self-hosted as a Container App sidecar or separate Container App)
- In-memory cache only (`IMemoryCache`) — no distributed cache

## Decision Outcome

Chosen option: **Azure Managed Redis (C0)**, because it is Microsoft's designated long-term replacement for Azure Cache for Redis, built on Redis 7.x, and provides the same managed service experience (no operational overhead) without retirement risk. Containerised Redis is documented as a viable fallback if Azure Managed Redis pricing becomes unacceptable at scale. In-memory cache is used as a supplementary layer for non-critical reference data.

#### Consequences

- Good, because Azure Managed Redis is built on Redis 7.x — the latest stable Redis version with improved performance and features.
- Good, because no retirement risk — Microsoft has committed to long-term support for Azure Managed Redis.
- Good, because the StackExchange.Redis client library is unchanged — no code changes required from the original Azure Cache for Redis selection.
- Good, because the .NET Aspire `Aspire.StackExchange.Redis` integration package works with both Azure Managed Redis and containerised Redis — local development is unaffected.
- Good, because distributed cache supports multiple Container App replicas — session state and cached data are shared across all instances.
- Bad, because Azure Managed Redis is a newer service and has less documented operational history than the well-established Azure Cache for Redis.
- Bad, because C0 tier provides 1 GB memory — if cache usage grows significantly, upgrade to C1 or higher adds cost.

#### Implementation

1. Parker updates the `infra/modules/redis/` Terraform module from `azurerm_redis_cache` (Azure Cache for Redis) to `azurerm_redis_enterprise_cluster` / `azurerm_redis_enterprise_database` (Azure Managed Redis) or the `azapi` provider if the resource type is not yet in azurerm.
2. The `Redis-ConnectionString` Key Vault secret is updated to the new Azure Managed Redis endpoint and access key after provisioning.
3. No application code changes are required — the StackExchange.Redis client and `IConnectionMultiplexer` abstraction are unchanged.
4. The `infra/modules/redis/` module outputs the connection string to Key Vault; Container Apps and Functions resolve it via managed identity Key Vault reference.
5. Local development uses containerised Redis via .NET Aspire `AddAzureRedis()` resource — no change to developer workflow.

#### Confirmation

- `IConnectionMultiplexer.IsConnected` returns true after startup in all environments.
- Redis `PING` command confirms sub-millisecond latency from Container App to Azure Managed Redis.
- Session state persists across Container App restarts (confirmed by logging out and back in after forcing a container restart).
- Azure Managed Redis `INFO server` confirms Redis 7.x version.

#### Stakeholders

- **Dallas (Lead & Architect):** Identified Azure Cache for Redis retirement risk; drove switch to Azure Managed Redis
- **Parker (DevOps):** Updates Terraform `redis/` module; no application code changes needed
- **Ripley (Backend):** Confirms StackExchange.Redis client is compatible; no code changes anticipated
- **Kane (Tester):** Validates cache behaviour in integration tests; confirms session persistence across restarts

## Pros and Cons of the Options

### Azure Managed Redis (C0)

- Good, because Microsoft's long-term replacement for Azure Cache for Redis — no retirement risk.
- Good, because Redis 7.x — latest stable version with performance improvements.
- Good, because fully managed — patching, HA, and monitoring handled by Azure.
- Good, because StackExchange.Redis client is unchanged — zero code migration effort.
- Good, because .NET Aspire integration package works transparently.
- Neutral, because C0 tier is 1 GB — adequate for MVP; upgrade path to C1+ is straightforward.
- Bad, because newer service — less operational documentation and community knowledge than Azure Cache for Redis.

### Azure Cache for Redis (C0) — Original Selection

- Good, because well-established, extensively documented service.
- Good, because StackExchange.Redis client is the standard .NET Redis client.
- Neutral, because feature-equivalent to Azure Managed Redis for MVP usage.
- Bad, because retiring 30 September 2028 — migrating mid-project or post-launch adds future operational risk.
- Bad, because choosing a retiring service creates unnecessary technical debt for a new project.

### Containerised Redis (Self-Hosted Container App)

- Good, because zero vendor lock-in — standard open-source Redis.
- Good, because no additional Azure service cost beyond Container App compute.
- Good, because full control over Redis version and configuration.
- Neutral, because same StackExchange.Redis client is used.
- Bad, because adds operational responsibility: monitoring Redis memory, persistence configuration, upgrade cycle.
- Bad, because production Redis requires persistent volume for durability — adds Terraform complexity.
- Bad, because data loss risk on container restart without carefully configured persistence.

### In-Memory Cache Only (IMemoryCache)

- Good, because zero additional infrastructure or cost.
- Good, because simplest implementation.
- Neutral, because adequate for single-replica deployments.
- Bad, because does not survive container restarts — session state is lost on every deployment.
- Bad, because not shared across Container App replicas — each instance has its own cache, causing inconsistent reads.
- Bad, because cannot serve as the backing store for distributed session state.

## More Information

Azure Cache for Redis retirement announcement: https://azure.microsoft.com/en-us/updates/azure-cache-for-redis-basic-standard-and-premium-tier-will-be-retired-on-30-september-2028/

Azure Managed Redis documentation: https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/managed-redis/managed-redis-overview

Containerised Redis is documented as a fallback option in the architecture. If Azure Managed Redis pricing at higher tiers becomes unacceptable at post-MVP scale, the containerised approach can be adopted without changing any application code — only the Terraform module and connection string need to change.

This decision supersedes the original v1 cache selection (Azure Cache for Redis C0) from architecture v1.0 (2026-02-28).

## Follow-On Information

No further immediate action required. Parker should monitor Azure Managed Redis GA status and Terraform provider support to confirm `azurerm` provider support before `infra/modules/redis/` is implemented. If `azurerm` provider does not yet support Azure Managed Redis, use the `azapi` provider as an interim measure.

## Record History

* **Proposed**: 2026-02-28 (as Azure Cache for Redis C0)
* **Accepted**: 2026-02-28 (original — Azure Cache for Redis)
* **Last Reviewed**: 2026-03-01
* **Superseded by**: ADR-005 (this document — revised to Azure Managed Redis)
* **Date Superseded**: 2026-03-01
