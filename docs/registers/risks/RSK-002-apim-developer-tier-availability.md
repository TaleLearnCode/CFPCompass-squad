---
title: "RSK-002: APIM Developer Tier Availability Limitation"
description: Azure API Management Developer tier lacks an SLA, posing an availability risk for production workloads.
tags:
  - risk
  - risk-register
  - apim
---

# APIM Developer Tier Availability Limitation

**ID:** RSK-002

## Risk Statement

Azure API Management Developer tier carries no zone redundancy and no high-availability SLA beyond 99.9% for the single-instance deployment. If the APIM instance becomes unavailable, the entire public REST API (`api.cfpcompass.com`) is inaccessible to third-party integrators and external API consumers. This is a known trade-off accepted in ADR-006 in exchange for lower cost and VNet integration capability at MVP scale.

## Root Cause / Trigger

- APIM Developer tier is designed for development and testing workloads, not high-availability production.
- A single APIM instance has no automatic failover; zone-redundant deployment requires Standard V2 or Premium tier.
- ADR-006 explicitly accepted this limitation for MVP to avoid the ~$180/month Standard V2 cost vs. ~$50/month Developer tier.
- Outage triggers: Azure platform incident affecting the APIM service in the deployed region; VM restart during Azure maintenance; rare service-level faults.

## Impact Assessment

- **Third-party API consumers:** Complete API outage. All calls to `api.cfpcompass.com` receive connection errors or timeouts. Integrations that depend on polling or webhooks from the CFP Compass API stop functioning until APIM recovers.
- **CFP Compass Web App:** The Blazor Server web app communicates with the API Host Container App via the internal Azure Container Apps environment URL — it does **not** route through APIM. The web app continues to function normally during an APIM outage.
- **Admin functions:** Admin moderation, account management, and all web-app-driven workflows are unaffected.
- **Duration:** Dependent on Azure's recovery timeline for the affected APIM instance; typically minutes to low hours for platform-level incidents.

## Likelihood

**Low**

Azure API Management has historically high availability. Developer tier outages are rare in practice; the primary concern is Azure platform incidents affecting the specific region, not APIM-specific failures. Azure's published incident history shows APIM service disruptions are infrequent.

## Severity

**High**

While the web application is unaffected, APIM is the sole publicly-addressable gateway for the REST API. Any third-party integration that relies on `api.cfpcompass.com` is completely disrupted during an outage. For a platform positioning itself as an integration-friendly API, an unplanned outage — even brief — has reputational impact proportionate to third-party adoption at the time.

## Mitigation Strategy

- **Internal routing bypass:** The CFP Compass web app uses the Container Apps internal environment DNS name to call the API Host directly. APIM is only in the path for external traffic. This ensures the primary user-facing application is fully resilient to APIM outages.
- **Azure Monitor alerting:** Configure Azure Monitor alerts on APIM availability metrics and 5xx response rate. Detect and respond to outages within 5 minutes.
- **Upgrade readiness:** Document the upgrade path from Developer tier to Standard V2 tier. Estimated upgrade time: 30–45 minutes. Terraform module parameterises the APIM SKU for fast promotion.
- **Status page:** Maintain a status page at `cfpcompass.com/status` that reflects APIM availability; allows third-party integrators to self-serve incident awareness.

## Detection Signals

- Azure Monitor alert: APIM availability metric drops below 99% over any 5-minute window.
- Azure Monitor alert: APIM 5xx response rate exceeds 1% over any 5-minute window.
- Azure Monitor alert: APIM request count drops to zero unexpectedly during expected traffic hours.
- External synthetic monitor (e.g., Application Insights availability test) hitting `GET /api/v1/cfps` via the APIM URL at 5-minute intervals.

## Contingency Plan

1. Confirm APIM outage via Azure Service Health and Application Insights availability test results.
2. Post incident update to `cfpcompass.com/status` within 15 minutes of confirmed outage.
3. If outage duration exceeds 30 minutes with no Azure recovery ETA, initiate upgrade from Developer to Standard V2 tier via Terraform (`apim_sku_name = "StandardV2"`, `apim_sku_capacity = 1`). Estimated upgrade time: 30–45 minutes.
4. After upgrade, validate all API operations via APIM developer portal smoke tests.
5. Document incident in a post-mortem and re-evaluate tier decision at next architecture review.

## Review Schedule

Review at first anniversary of production deployment, or immediately following any APIM-related incident. Re-evaluate tier upgrade if APIM availability incidents occur more than once in a rolling 90-day period, or if third-party API adoption grows such that outage impact becomes business-critical.
