---
title: "RSK-005: Azure Managed Redis Pricing at Scale"
description: Azure Managed Redis costs may escalate significantly at scale, threatening budget assumptions for the MVP.
tags:
  - risk
  - risk-register
  - azure-managed-redis
---

# Azure Managed Redis Pricing at Scale

**ID:** RSK-005

## Risk Statement

Azure Managed Redis C0 tier (~$16/month) is sufficient for MVP cache workloads (1 GB, no zone redundancy). As CFP Compass traffic grows, higher Redis tiers may become necessary to sustain cache hit rates and session throughput — increasing infrastructure cost. Additionally, Azure Managed Redis is a relatively new Azure service whose pricing structure may evolve as it matures and replaces Azure Cache for Redis.

## Root Cause / Trigger

- Azure Managed Redis C0 is the entry-level SKU: 1 GB memory, single node, no zone redundancy, no persistence.
- Cache eviction begins when stored data approaches the 1 GB limit, degrading cache hit rates and increasing SQL read pressure.
- Azure Managed Redis launched as a replacement for Azure Cache for Redis; its pricing model is subject to change as Microsoft completes the product transition.
- Traffic growth (more users, more cached CFP listings, more session state) is the intended outcome of the platform — successful growth triggers this risk.

## Impact Assessment

- **Cache eviction:** When Redis memory usage exceeds ~70% of the 1 GB C0 limit, cache evictions increase, degrading APIM cache hit rates and increasing Azure SQL read traffic. This amplifies cold start exposure (RSK-001) as more queries bypass the cache and hit SQL.
- **Session state degradation:** ASP.NET Core session state stored in Redis may be evicted under memory pressure, causing authenticated users to be unexpectedly logged out.
- **Cost impact:** Upgrading to C1 (6 GB) costs ~$48/month; C2 (13 GB) costs ~$96/month. These are manageable increases but represent a 3–6× cost multiple vs. MVP baseline.
- **Architecture risk:** If Microsoft materially changes Azure Managed Redis pricing or deprecates a SKU, the containerised Redis fallback (documented in ADR-005) would require a Terraform-only migration.

## Likelihood

**Medium**

Traffic growth is the goal of the platform. Some Redis tier increase is expected over the platform's lifetime. Pricing changes from Microsoft are uncertain but precedented with Azure Cache for Redis SKU transitions. Cache pressure is expected to manifest before C0 capacity is truly exhausted, as application-level memory cache (`IMemoryCache`) offloads reference data lookups.

## Severity

**Low**

The containerised Redis fallback (self-hosted Redis Container App) is explicitly documented in ADR-005 as a cost mitigation path that requires **no application code changes** — only Terraform configuration updates and a Key Vault connection string change. Application behaviour is identical between Azure Managed Redis and self-hosted Redis via the `Aspire.StackExchange.Redis` client. The risk is primarily financial and operational, not architectural.

## Mitigation Strategy

- **In-memory cache (`IMemoryCache`):** Reference data (taxonomy lists, ISO 3166 countries, IANA time zones, UN M.49 regions) is served from `IMemoryCache` on each Container App instance, bypassing Redis entirely for these high-frequency, low-volatility reads. This substantially reduces Redis memory pressure.
- **APIM-level caching:** APIM response caching (ADR-011) serves public read endpoints at the gateway layer, reducing the volume of requests that reach the API and Redis. Redis handles session state and distributed cache overflow, not primary read serving.
- **Proactive capacity monitoring:** Alert at 70% Redis memory usage; plan tier upgrade before eviction pressure begins. This provides a 30% buffer between alert and actual impact.
- **Containerised Redis fallback (ADR-005):** If Redis tier costs become unacceptable, a self-hosted Redis Container App (same Docker image, same StackExchange.Redis client, identical behaviour) is deployable via Terraform in under 30 minutes with zero application code changes.
- **Cache TTL tuning:** Review and tune cache TTLs if memory pressure emerges — shorter TTLs on high-churn data reduce steady-state Redis footprint.

## Detection Signals

- Azure Monitor alert: Redis `used_memory_rss` > 700 MB (70% of C0 1 GB limit) — triggers upgrade planning.
- Azure Monitor alert: Redis `evicted_keys` metric > 0 over any 5-minute window — indicates active eviction (severity: high, act immediately).
- Azure Monitor metric: Redis cache hit ratio < 80% — may indicate eviction or cache warming issues.
- Application Insights: Increase in SQL read query volume without corresponding increase in CFP listing requests (cache miss amplification signal).

## Contingency Plan

1. If `used_memory_rss` alert fires at 70%: review cache TTL settings; consider reducing TTL on large list caches.
2. If `evicted_keys` alert fires: immediately evaluate tier upgrade vs. containerised Redis migration.
   - **Option A (Tier upgrade):** Apply Terraform change `redis_sku_name = "C1"` — takes effect with minimal downtime (Azure Managed Redis supports in-place scaling on some SKUs).
   - **Option B (Containerised Redis):** Deploy Redis Container App via Terraform; update `REDIS_CONNECTION_STRING` in Key Vault; redeploy API and Web Container Apps. Zero application code changes. Estimated time: 20–30 minutes.
3. If Microsoft announces pricing changes to Azure Managed Redis: evaluate Option B (containerised) immediately as a cost hedge.

## Review Schedule

Review monthly for the first 6 months post-launch while Redis usage patterns are being established. Review quarterly thereafter. Trigger an unscheduled review any time the `used_memory_rss` alert fires or Microsoft publishes Azure Managed Redis pricing changes.
