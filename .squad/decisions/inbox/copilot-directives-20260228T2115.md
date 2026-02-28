### 2026-02-28T21:15: User directives — architecture revisions
**By:** Chad Green (via Copilot)

**Directive 1 — Redis: Do NOT use Azure Cache for Redis**
Azure Cache for Redis is being retired on September 30, 2028. Use Azure Managed Redis (preferred) or a self-hosted containerized Redis instance instead.

**Directive 2 — APIM: Use Developer tier for MVP**
Do not use Consumption tier. Use APIM Developer tier for MVP. Upgrade path: Developer → Standard V2 (when financially justified).

**Directive 3 — Event-driven architecture for writes**
POST and PUT operations should submit an event to Azure Service Bus. An Azure Function processes the message asynchronously. The API responds with HTTP 202 Accepted. Lean on APIM response caching for read (GET) endpoints to offset Azure SQL serverless cold-start impact.

**Why:** User request — captured for team memory.
