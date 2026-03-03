---
title: "ADR-006: Azure API Management Developer Tier"
description: Supersedes the original APIM Consumption tier selection with the Developer tier to eliminate cold-start latency that undermined response caching effectiveness and to enable VNet integration for secure private communication with the API Container App backend.
tags:
  - adr
  - architecture-decision-record
  - apim
  - azure-api-management
  - api-gateway
status: accepted
---
# Azure API Management Developer Tier

- **Status:** Accepted
- **Date:** 2026-03-01 (revised)
- **Work Item:** [*arch-006* — API gateway tier selection]

## Context and Problem

CFP Compass exposes a public REST API that requires rate limiting, subscription key management, response caching, and a developer portal for third-party integrators. Azure API Management (APIM) was selected as the API gateway in architecture v1. The initial selection was the **Consumption tier** due to its pay-per-call pricing and zero idle cost. During architecture review on 2026-03-01, the Consumption tier was identified as having two critical limitations: a cold start latency of 1–2 seconds per call (the tier has no dedicated compute), and no VNet integration support. Given that APIM response caching is a key read-path performance strategy (to offset Azure SQL cold starts), a cold-start APIM layer would undermine the entire caching benefit. This ADR supersedes the original Consumption tier selection.

## Decision Drivers

- No cold-start latency on API calls — APIM must be available instantly for cached read responses
- VNet integration (internal mode) to enable secure communication between APIM and the API Container App backend
- Built-in developer portal for API consumers to discover and test the public API
- Response caching support to offset Azure SQL serverless cold starts on read-heavy endpoints
- Rate limiting and subscription key management for public API access control
- Predictable fixed cost justifiable by the capability gains
- Clear upgrade path for future scaling requirements

## Considered Options

- Azure API Management — Developer tier
- Azure API Management — Consumption tier (original selection)
- Azure API Management — Standard V2 tier

## Decision Outcome

Chosen option: **Azure API Management — Developer tier**, because it provides dedicated compute (no cold start), VNet integration for secure backend connectivity, and the full built-in developer portal. The fixed monthly cost (~$50) is justified by eliminating cold-start latency that would undermine APIM response caching effectiveness, and by enabling VNet integration that improves the security posture of the API backend. The upgrade path from Developer is to **Standard V2** (not Premium) when traffic volume and financial justification demand higher availability and zone redundancy.

#### Consequences

- Good, because dedicated capacity eliminates cold-start latency — APIM responds instantly, making response caching effective.
- Good, because VNet integration (internal mode) enables the API Container App backend to communicate with APIM over a private network path.
- Good, because built-in developer portal allows API consumers to browse, test, and obtain subscription keys without additional tooling.
- Good, because built-in rate limiting (100 read/min, 10 write/min per subscription key) and response caching are configured via APIM policies.
- Good, because APIM imports the OpenAPI spec directly from `docs/api/openapi/cfp-compass-api-v1.yaml` — contract and gateway configuration stay in sync automatically.
- Bad, because fixed monthly cost (~$50) vs. Consumption's pay-per-call — a cost increase for low-traffic MVP periods.
- Bad, because Developer tier has no zone redundancy and no SLA beyond 99.9% — not suitable for high-availability production workloads.

#### Implementation

1. Parker updates the `infra/modules/apim/` Terraform module to use `sku_name = "Developer_1"` instead of `Consumption_0`.
2. APIM Developer tier VNet integration is configured in internal mode — the Container App API backend is accessible to APIM via the VNet.
3. APIM Products are configured: "Public" (rate-limited, no approval) and "Partner" (rate-limited, requires approval).
4. Rate limit policies applied at Product level: 100 calls/min (read), 10 calls/min (write) per subscription key.
5. Response caching policies configured per endpoint: 5 min (listings), 1 min (detail), 60 min (taxonomy), 24 h (reference data).
6. APIM imports the OpenAPI spec from `docs/api/openapi/cfp-compass-api-v1.yaml` during Terraform apply.
7. Developer portal is auto-provisioned by the Developer tier — accessible at `https://developer.cfpcompass.com` (custom domain via Front Door).

#### Confirmation

- APIM responds with sub-100ms latency on cache hits (confirmed via Application Insights APIM traces).
- No cold-start latency observed on first request after APIM idle period (dedicated compute confirmed).
- Developer portal accessible and functional at the configured URL.
- Rate limiting returns 429 on exceeding configured thresholds in load tests.
- VNet integration confirmed — Container App API backend is reachable from APIM without public ingress.

#### Stakeholders

- **Dallas (Lead & Architect):** Identified Consumption tier cold-start as a critical risk; drove revision to Developer tier
- **Parker (DevOps):** Updates Terraform `apim/` module; configures VNet integration, policies, and OpenAPI spec import
- **Ripley (Backend):** API implementation conforms to APIM rate limits; no code changes required for gateway change
- **Lambert (Frontend):** Web app does not use APIM directly (Blazor Server calls the API directly); no impact
- **Kane (Tester):** Tests rate limiting behaviour, response caching effectiveness, and developer portal functionality

## Pros and Cons of the Options

### Azure API Management — Developer Tier

- Good, because dedicated compute — no cold start latency, APIM is always responsive.
- Good, because VNet integration (internal mode) for secure API backend communication.
- Good, because full developer portal built in.
- Good, because built-in rate limiting, response caching, subscription key management.
- Good, because APIM policy engine supports cache invalidation via Service Bus events (CacheInvalidationProcessor).
- Neutral, because ~$50/month fixed cost — predictable, justified by capabilities.
- Bad, because no zone redundancy — upgrade to Standard V2 if HA is required.
- Bad, because Developer tier is intended for dev/test by Microsoft's own documentation; however, it is widely used for production workloads in cost-sensitive scenarios with the understanding of the SLA limitation.

### Azure API Management — Consumption Tier (Original Selection)

- Good, because pay-per-call pricing — very low cost for low traffic volumes.
- Good, because scales automatically with request volume.
- Neutral, because policies (rate limiting, caching) work the same as other tiers.
- Bad, because cold start latency (1–2 seconds per cold call) — undermines response caching effectiveness and degrades user experience.
- Bad, because no VNet integration support — API backend must have public ingress, reducing security posture.
- Bad, because no dedicated developer portal (limited portal via external-facing policies only).

### Azure API Management — Standard V2 Tier

- Good, because zone redundancy and higher SLA (99.95%) compared to Developer tier.
- Good, because VNet integration supported.
- Good, because full developer portal.
- Neutral, because all policy capabilities equivalent to Developer tier.
- Bad, because significantly higher cost (~$250/month) — not justified for MVP traffic volumes.
- Bad, because over-engineered for MVP; cost vs. capability trade-off is poor at this stage.

## More Information

Azure API Management tier comparison: https://learn.microsoft.com/en-us/azure/api-management/api-management-features

**Upgrade path:** Developer → Standard V2 (not Premium). Standard V2 adds zone redundancy and a higher SLA without the extreme cost of Premium tier. The Terraform `apim/` module should be structured to allow the SKU to be changed via a `terraform.tfvars` variable to facilitate this upgrade.

**Production suitability note:** The Developer tier's 99.9% SLA and single-unit capacity are known limitations. For MVP traffic with Azure Front Door caching static assets and APIM caching API responses, the Developer tier is acceptable. Once CFP Compass reaches sustained high traffic or requires an enterprise SLA, upgrade to Standard V2.

This decision supersedes the original v1 APIM selection (Consumption tier) from architecture v1.0 (2026-02-28).

## Follow-On Information

Parker should structure the `apim/` Terraform module with a `sku_name` input variable (`Developer_1` default) so the tier can be changed to `StandardV2_1` in a single `terraform.tfvars` change when the upgrade is warranted.

## Record History

* **Proposed**: 2026-02-28 (as APIM Consumption tier)
* **Accepted**: 2026-02-28 (original — Consumption tier)
* **Last Reviewed**: 2026-03-01
* **Superseded by**: ADR-006 (this document — revised to Developer tier)
* **Date Superseded**: 2026-03-01
