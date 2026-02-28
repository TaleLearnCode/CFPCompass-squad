# Architecture v2 Revisions — ADR Summaries

**Date:** 2026-03-01  
**Author:** Dallas (Lead & Architect)  
**Requested by:** Chad Green  
**Status:** Active — decisions finalized, integrated into `architecture.md` v2.0

---

## ADR-005 (Revised): Azure Managed Redis over Azure Cache for Redis

**Decision:** Azure Managed Redis (C0) as default distributed cache. Containerized Redis as documented fallback.

**Rationale:** Azure Cache for Redis is retiring September 30, 2028. Azure Managed Redis is Microsoft's replacement — built on Redis 7.x, same managed experience, no retirement risk. Containerized Redis (self-hosted as Container App) is a viable fallback with zero vendor lock-in and no additional Azure service cost, but adds operational responsibility.

**Impact:** Parker updates Terraform `redis/` module to provision Azure Managed Redis. Ripley — no code changes (connection string is the same pattern).

---

## ADR-006 (Revised): APIM Developer Tier

**Decision:** Azure API Management Developer tier for MVP. Upgrade path: Developer → Standard V2.

**Rationale:** Developer tier provides dedicated capacity (no cold start), VNet integration (internal mode), and built-in developer portal. Consumption tier's cold start (~1-2s) and lack of VNet were identified risks. Fixed cost (~$50/month) is justified by the capability gains.

**Risk note:** Developer tier is NOT suitable for high-availability production — no SLA beyond 99.9%, no zone redundancy. Upgrade to Standard V2 (not Premium) when traffic demands it.

**Impact:** Parker updates Terraform `apim/` module for Developer SKU + VNet config. Removes Consumption cold-start workarounds.

---

## ADR-007: Event-Driven Write Pattern (Service Bus + Azure Functions + 202 Accepted)

**Decision:** POST/PUT operations publish events to Azure Service Bus. API returns HTTP 202 Accepted. Azure Functions process writes asynchronously.

**Rationale:** Decouples API responsiveness from Azure SQL cold starts. Service Bus buffers events during DB wake-up. Dead-letter queues provide automatic failure handling. Independent scaling of read and write paths.

**Write path:** API → validate → publish to Service Bus topic → return 202 + Location header → Function subscribes → writes to SQL → updates status

**Impact:** Ripley implements Service Bus publishing in API controllers. New `CFPCompass.Functions` project for Service Bus processors. Status tracking table added to schema.

---

## ADR-008: Azure Service Bus Standard Tier

**Decision:** Service Bus Standard tier with topic-per-aggregate pattern.

**Rationale:** Topics + subscriptions enable fan-out (write → cache invalidation + notification). Dead-letter queues for failed messages. ~$10/month — cost-effective for MVP.

---

## ADR-009: HTTP 202 Accepted Response Pattern

**Decision:** Write endpoints return 202 Accepted with `Location` header pointing to status-check endpoint.

**Rationale:** Async consistency — callers poll `GET /api/v1/submissions/{id}/status` for processing state (Pending → Processing → Completed | Failed). Clear API contract for async operations.

---

## ADR-010: Multi-Select Taxonomy with Junction Tables

**Decision:** Many-to-many relationships via `CfpListingCategory` and `CfpTopic` junction tables. Both Category and Topic are multi-select on submission form.

**Rationale:** CFPs span multiple domains and topics. Richer filtering for speakers. 10 Primary Domains and 10 Secondary Tag groups seeded in DB migration; admin-extensible.

**Impact:** Ripley updates EF Core schema — removes `CategoryId` FK from `Cfp`, adds junction tables. Lambert updates submission form for multi-select. Kane tests junction table queries.

---

## ADR-011: APIM Response Caching for Read Path

**Decision:** APIM response caching on public GET endpoints. TTL: 5 minutes (listings), 1 minute (detail). Cache invalidation via Service Bus events.

**Rationale:** Offsets Azure SQL serverless cold starts for read operations. Reduces SQL load. Event-driven invalidation ensures data freshness within minutes.

---

## Resolved Open Questions

| Question | Answer | Impact |
|----------|--------|--------|
| Q1: Production domain | `cfpcompass.com` | CORS, APIM custom domain, ACS sender domain, Front Door |
| Q2: Bot protection | Pending — Chad reviewing | Blocks submission form |
| Q3: Taxonomy | Full taxonomy seeded (10 Primary Domains, 10 Secondary Tag groups); multi-select; admin-extensible | DB migration, submission form, filter queries |
| Q4: Email sender | `noreply@cfpcompass.com` | ACS domain verification, email templates |
