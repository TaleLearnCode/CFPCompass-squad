---
updated_at: 2026-03-01T12:00:00.000Z
focus_area: Architecture v2 complete — implementation ready
active_issues: []
---

# What We're Focused On

**Architecture v2 complete.** Dallas has updated the system architecture document (`.squad/architecture.md`) to v2.0 incorporating Chad Green's direction. Key changes: Azure Managed Redis (replacing retired Azure Cache for Redis), APIM Developer tier (replacing Consumption — no cold start, VNet integration), event-driven write pattern via Azure Service Bus + Azure Functions (202 Accepted responses), APIM response caching for reads, multi-select taxonomy with junction tables, and resolved open questions (domain: `cfpcompass.com`, email: `noreply@cfpcompass.com`, taxonomy seeded). Bot protection decision still pending Chad's review. Six new ADRs added (ADR-007 through ADR-011, ADR-005/006 revised). Team is ready to begin implementation — new `CFPCompass.Functions` project added to solution structure.
