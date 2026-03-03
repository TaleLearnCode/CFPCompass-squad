---
title: "RSK-001: Azure SQL Serverless Cold Start Latency"
description: Azure SQL Serverless may experience cold start latency after auto-pause, degrading user-facing response times.
tags:
  - risk
  - risk-register
  - azure-sql
---

# Azure SQL Serverless Cold Start Latency

**ID:** RSK-001

## Risk Statement

Azure SQL Serverless auto-pauses after 1 hour of inactivity (configurable). The cold start on the first query after a pause can take up to 10 seconds, degrading the user experience during low-traffic periods — particularly nights, weekends, and early-morning hours when MVP traffic is sparse.

## Root Cause / Trigger

- Azure SQL Serverless is designed to auto-pause when idle to reduce cost; this is the expected behaviour of the selected SKU (ADR-001).
- MVP traffic is unlikely to sustain continuous SQL activity across all hours, meaning auto-pause will trigger regularly.
- Cold start latency is incurred on the very first query after the pause — a synchronous database wake-up that blocks the calling thread.
- The most impactful scenario is a synchronous write operation arriving immediately after a cold start before the event-driven pattern has buffered the request.

## Impact Assessment

- First user after an idle period experiences degraded response times (up to 10 seconds on the initial query).
- Potential timeout on critical write operations if the Azure Functions Service Bus processor exceeds its configured lock timeout during the SQL cold start window.
- API read endpoints served from APIM cache are unaffected during cold start; uncached reads (e.g., individual CFP detail not yet in cache) may be slow.
- Admin moderation actions that go directly to SQL without cache buffering are exposed during cold start windows.

## Likelihood

**High**

MVP traffic is expected to be low and irregular. Auto-pause will trigger on most nights and potentially on weekends. Cold starts should be anticipated as a routine occurrence, not an exception, for the MVP launch period.

## Severity

**Medium**

The event-driven write architecture (ADR-007) decouples the API layer from SQL write latency — the API returns HTTP 202 Accepted immediately, and the Azure Function processor tolerates the cold start before writing. APIM response caching (ADR-011) serves read traffic from cache during cold start windows. Severity is bounded by these existing mitigations; end-user impact is primarily a delayed first page load or slow first admin action after an idle period.

## Mitigation Strategy

- **Event-driven write pattern (ADR-007):** POST/PUT operations publish to Service Bus and return 202 immediately. The `CfpSubmissionProcessor` Azure Function absorbs cold start latency before writing to SQL — decoupling user-facing API response time from SQL availability.
- **APIM response caching (ADR-011):** Public read endpoints (CFP listing, browse, search) are cached at APIM with a 5-minute TTL for list pages and 1-minute TTL for detail pages. Cache serves reads during cold start.
- **Auto-pause delay configuration:** Set auto-pause delay to 60 minutes (not the default 1 hour minimum) to reduce cold start frequency during daytime operating hours.
- **Azure Container Apps startup probe:** Configure a 10-second grace period on the API Container App startup probe to avoid health check failures during cold start windows at application restart.
- **Application Insights monitoring:** Track cold start frequency and duration; alert when SQL query duration exceeds 5 seconds to detect worsening cold start patterns.

## Detection Signals

- Application Insights alert: SQL query duration > 5 seconds (threshold for likely cold start, not normal query latency).
- Monitor `CfpSubmissionProcessor` Azure Function execution duration — sustained high execution times indicate SQL cold starts are delaying event processing.
- Azure SQL Database metrics: `connection_successful` spike after a gap in `dtu_consumption_percent` (indicating wake-up from pause).
- User-reported slow initial page loads during off-peak hours.

## Contingency Plan

1. Increase auto-pause delay from 60 minutes to the maximum configurable value to reduce cold start frequency.
2. If cold starts remain unacceptably frequent or long, switch Azure SQL Database from Serverless to provisioned compute (S0 tier, ~$15/month). This requires a Terraform SKU change only — no application code changes.
3. Add a lightweight scheduled ping (e.g., a Container Apps Job running every 45 minutes) to keep SQL warm during expected high-traffic windows.

## Review Schedule

Review at MVP launch (first 30 days of production traffic), then quarterly. Re-evaluate if cold start alerts fire more than 3 times per day consistently, or if user complaints about slow load times increase.
