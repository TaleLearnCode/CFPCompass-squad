---
title: "ADR-011: APIM Response Caching for Read Path"
description: Azure API Management built-in response caching with event-driven cache invalidation is used to serve public CFP listing endpoints at sub-second latency without hitting SQL on every request.
tags:
  - adr
  - architecture-decision-record
  - azure-api-management
  - caching
status: accepted
---

# APIM Response Caching for Read Path

- **Status:** Accepted
- **Date:** 2026-03-01
- **Work Item:** [*arch-011* — read path performance strategy]

## Context and Problem

Azure SQL Database in Serverless mode auto-pauses after idle periods and takes approximately 10 seconds to cold-start on the first query. Public CFP listing and browse pages are the highest-traffic endpoints in CFP Compass and are read-heavy — the data changes only when a CFP is approved, modified, or expires, not on every request. Without caching, every public listing page load either suffers a cold-start delay or keeps the serverless database permanently warm (eliminating the cost benefit of serverless). A caching strategy is needed that serves largely static read data at low latency while ensuring data freshness when CFPs are updated.

## Decision Drivers

- Sub-second response times for public CFP listing, browse, and search pages
- Reduction of Azure SQL query load and associated cost
- Cache data freshness — updates should be visible within a short, defined window (minutes, not hours)
- Cache invalidation must be event-driven, not time-only, to reflect write operations promptly
- Caching solution must be co-located with the API gateway (APIM) to avoid double-hop latency
- Different TTLs appropriate for different endpoint categories (listing data changes more often than reference data)

## Considered Options

- APIM response caching (built-in APIM caching policy)
- Redis distributed cache in the API layer (application-level caching)
- No caching (keep SQL warm permanently with heartbeat pings)

## Decision Outcome

Chosen option: **APIM response caching via built-in APIM cache policies**, because caching at the gateway level means cached responses never reach the API Container App or SQL — the lowest possible latency for repeated reads. Combined with event-driven cache invalidation (triggered by Service Bus write events via the `CacheInvalidationProcessor` Function), data freshness is ensured within minutes of a write operation completing. Redis is used as a supplementary layer for session state and non-public data (not for public read caching, which is APIM's responsibility).

#### Consequences

- Good, because APIM cache hits return in sub-10ms — SQL cold-start has zero impact on cached read responses.
- Good, because Azure SQL query load is dramatically reduced — only cache misses and writes reach SQL.
- Good, because event-driven cache invalidation ensures listing data is fresh within minutes after a CFP is approved, modified, or archived.
- Good, because different TTLs per endpoint category match the natural staleness tolerance for each data type.
- Good, because Redis remains available for session state and authenticated user data — two caching layers for different concerns.
- Bad, because stale data is possible for up to the TTL window (5 minutes for listings, 1 minute for detail) — acceptable for the CFP use case.
- Bad, because cache invalidation adds complexity to the write path (CacheInvalidationProcessor must know which APIM cache keys to purge).

#### Implementation

1. Parker configures APIM response caching policies per endpoint group in the `infra/modules/apim/` Terraform module:
   | Endpoint | Cache TTL | Cache Key |
   |----------|----------|-----------|
   | `GET /api/v1/cfps` (listing) | 5 minutes | URL + query string |
   | `GET /api/v1/cfps/{id}` (detail) | 1 minute | CFP ID |
   | `GET /api/v1/topics` | 60 minutes | URL |
   | `GET /api/v1/categories` | 60 minutes | URL |
   | `GET /api/v1/countries` | 24 hours | URL |
   | `GET /api/v1/regions` | 24 hours | URL |

2. APIM policy example for listing endpoint:
   ```xml
   <cache-lookup vary-by-developer="false" vary-by-developer-groups="false">
       <vary-by-query-parameter>page</vary-by-query-parameter>
       <vary-by-query-parameter>categories</vary-by-query-parameter>
       <vary-by-query-parameter>topics</vary-by-query-parameter>
   </cache-lookup>
   ```

3. Ripley implements `CacheInvalidationProcessor` Azure Function subscribed to all Service Bus topics. On receipt of any write event, the Function:
   - Purges the affected CFP detail cache key via APIM Management API: `DELETE /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.ApiManagement/service/{apim}/caches/default/values/{key}`
   - Invalidates the listing cache (all pages) by calling the APIM cache purge endpoint.
   - Removes the affected entry from Redis (for session-aware reads if cached there).

4. Admin endpoint `POST /api/v1/admin/cache/purge` manually purges all APIM caches — available to admins for emergency cache clear.

#### Confirmation

- Cache HIT confirmed: second request to `GET /api/v1/cfps` returns in < 20ms (no SQL hit).
- Cache MISS confirmed on first request after cache expiry or invalidation.
- Cache invalidation: after a CFP is approved (write event processed by Function), the next listing request reflects the new CFP within < 5 seconds.
- APIM analytics confirm cache hit ratio > 80% for public listing endpoints under normal load.
- SQL query volume drops by > 70% for read-only endpoints with caching enabled (confirmed via Log Analytics query metrics).

#### Stakeholders

- **Dallas (Lead & Architect):** Decision owner; designed read path caching strategy
- **Parker (DevOps):** Configures APIM cache policies in Terraform; provisions APIM Management API access for Function
- **Ripley (Backend):** Implements `CacheInvalidationProcessor` Function; wires Service Bus subscriptions to invalidation logic
- **Kane (Tester):** Tests cache hit/miss behaviour, invalidation timing, and manual cache purge

## Pros and Cons of the Options

### APIM Response Caching (Gateway-Level)

- Good, because cached responses never reach the API or SQL — lowest possible latency for repeated reads.
- Good, because cache invalidation is event-driven — data freshness is guaranteed within TTL window.
- Good, because different TTLs per endpoint match natural staleness tolerances.
- Good, because caching is transparent to the API implementation — no cache code in application layer.
- Good, because APIM analytics report cache hit rate — operationally visible.
- Neutral, because APIM cache keys must be maintained to align with URL/query string structure.
- Bad, because cache invalidation requires APIM Management API calls from the Function — APIM management API access must be configured.

### Redis Distributed Cache (Application-Level)

- Good, because application-level control over what is cached and how.
- Good, because sub-millisecond read latency for cache hits.
- Good, because supports complex cache key strategies (user-specific, role-specific).
- Neutral, because Redis is already provisioned for session state — no additional cost.
- Bad, because cached responses still go through the API Container App and network hop before hitting Redis — more latency than APIM cache for public reads.
- Bad, because invalidation logic is in application code — tightly coupled to the API layer.
- Bad, because Redis cache is not visible in APIM analytics — harder to measure cache effectiveness.

### No Caching (Keep SQL Warm)

- Good, because always-consistent read data — no staleness.
- Good, because simplest architecture — no cache logic or invalidation.
- Bad, because SQL must be kept permanently warm (heartbeat queries) — eliminates the serverless cost saving.
- Bad, because high SQL query load — every public listing request hits SQL.
- Bad, because slower response times under concurrent load — SQL becomes a bottleneck.

## More Information

APIM cache policies documentation: https://learn.microsoft.com/en-us/azure/api-management/api-management-caching-policies

The `CacheInvalidationProcessor` subscribes to all six Service Bus topics. Cache invalidation is best-effort — if the APIM Management API is temporarily unavailable, the TTL-based expiry ensures staleness is bounded. The admin manual purge endpoint provides an escape hatch for urgent cache clears.

The interaction between APIM caching and Redis: APIM caches public GET response bodies. Redis caches authenticated user session data, per-user tracking state, and reference data for in-process API use. The two caches serve different concerns and do not overlap.

## Follow-On Information

If APIM Management API calls for cache invalidation prove fragile (e.g., rate limits on management operations), consider switching to a Vary-by-header strategy where the API includes a `Cache-Version: {etag}` header that APIM uses as part of the cache key, and bumping the etag on write invalidates the cache without a Management API call.

## Record History

* **Proposed**: 2026-03-01
* **Accepted**: 2026-03-01
* **Last Reviewed**: 2026-03-01
