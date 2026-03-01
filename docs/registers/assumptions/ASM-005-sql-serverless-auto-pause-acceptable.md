---
title: "ASM-005: Azure SQL Serverless Auto-Pause Cold Start Is Acceptable for MVP"
description: The cold start latency introduced by Azure SQL Serverless auto-pause is acceptable for MVP user experience requirements.
tags:
  - assumption
  - assumption-register
  - azure-sql
---

# Azure SQL Serverless Auto-Pause Cold Start Is Acceptable for MVP

**ID:** ASM-005

## Statement

The Azure SQL Serverless auto-pause cold start latency — up to 10 seconds on the first query after an idle period — is acceptable for MVP traffic patterns. The event-driven write architecture (ADR-007) and APIM response caching (ADR-011) together provide sufficient insulation from cold start impact that the user-facing degradation is tolerable for the launch phase of CFP Compass.

## Context / Rationale

Azure SQL Serverless (ADR-001) auto-pauses compute after a configurable idle period (minimum 1 hour; configured at 60 minutes for CFP Compass). When the first query arrives after a pause, SQL resumes compute — a process that can take up to 10 seconds. This is not a failure; it is the documented and expected behaviour of the Serverless SKU.

This assumption is the architectural lynchpin of the cost-optimised MVP infrastructure design. The entire event-driven write pattern (ADR-007) was designed in part to absorb this cold start — the API returns HTTP 202 immediately and the Azure Function processor tolerates the cold start before writing to SQL. APIM caching (ADR-011) means most read traffic never reaches SQL at all during cold start windows.

If this assumption proves incorrect — that is, if cold starts are frequent enough and severe enough to create a poor user experience despite these mitigations — the fallback to provisioned compute is a Terraform-only change with no application code impact. The assumption is therefore time-bounded to the MVP launch period and is subject to empirical validation with production traffic data.

**What this assumption accepts:**

- Cold starts will occur, likely daily during off-peak hours (nights, weekends).
- The first user session after a cold start will experience a slower-than-normal experience on non-cached operations.
- Background jobs (`CfpExpiryJob`, `DeadlineReminderJob`, `WeeklyDigestJob`) may experience up to 10 seconds of startup latency on their first SQL query.
- The event-driven write path may take up to 10 seconds longer to process the first submission after an idle period.

**What this assumption does NOT accept:**

- Cold starts occurring multiple times per hour (indicates something is preventing auto-pause from keeping SQL warm — should not happen if traffic is above the threshold).
- Cold start duration exceeding 15 seconds (above the documented maximum; would indicate a service issue).
- Write operations being permanently lost due to Service Bus lock timeouts during a cold start (Service Bus lock timeout configured > 15 seconds to account for worst-case cold start).

## Scope of Impact

- **API write path:** Service Bus `CfpSubmissionProcessor`, `UserAccountProcessor` Functions must tolerate up to 10 seconds additional latency on first execution after idle.
- **API read path:** APIM caching serves most public reads during cold start windows; uncached reads (e.g., individual CFP detail pages not yet in cache) may be slow.
- **Background jobs:** `CfpExpiryJob`, `DeadlineReminderJob`, `WeeklyDigestJob`, `WorldRegionAssignmentJob`, `DuplicateDetectionJob` — first SQL query after being scheduled may experience cold start latency. Jobs should not be scheduled to run immediately after expected idle windows (e.g., do not schedule `WeeklyDigestJob` at 3:00 AM Monday if SQL is likely paused; prefer 8:00 AM).
- **Service Bus lock timeout:** Service Bus message lock timeout must be set > 15 seconds to prevent lock expiry during a cold start. Configured in `host.json` Functions binding.

## Risk Level

**High**

This assumption will definitely be tested by production traffic — cold starts will occur. The assumption is about acceptability of the degradation, not whether degradation will occur. If the actual cold start frequency or duration exceeds what the event-driven and caching mitigations can absorb, user experience will visibly suffer. The risk is RSK-001 (SQL Serverless Cold Start Latency) — this assumption and that risk are directly related.

## Validation Evidence

Architecture design review confirmed that the event-driven write pattern (ADR-007) adequately buffers cold starts for write operations, and APIM caching (ADR-011) protects the primary read path.

Pre-launch validation steps (required before production launch):

1. **Dev/staging cold start measurement:** Force SQL auto-pause in the staging environment (wait 1 hour with no activity) and measure actual cold start duration via Application Insights query latency metrics.
2. **Service Bus lock timeout validation:** Confirm that the `messageLock` setting in `host.json` is greater than the measured worst-case cold start duration.
3. **Acceptance test:** Simulate cold start in staging; verify that a CFP submission via the web app receives HTTP 202 within 2 seconds, and that the submission appears in the admin queue within 2 minutes (async processing SLO).
4. **Auto-pause delay setting:** Confirm `auto_pause_delay_in_minutes = 60` is applied in Terraform (not the default); monitor whether this is sufficient to keep SQL warm during normal business hours.

## Dependencies

- ADR-007 (event-driven write architecture) must be implemented before this assumption can be validated.
- ADR-011 (APIM response caching) must be configured before read path cold start protection is in place.
- Service Bus lock timeout configuration in `CFPCompass.Functions/host.json`.
- Background job scheduling configuration must avoid scheduling jobs immediately after expected SQL idle windows.

## Review Cadence / Expiry

Validate empirically during the first 30 days of production operation. If Application Insights cold start alerts (SQL query duration > 5s) fire more than 3 times per day on average, trigger a review and consider switching to provisioned compute. Review quarterly thereafter.

## Fallback Plan

If cold start latency is unacceptable in production (frequent user complaints, cold start alerts firing daily, admin moderation lag attributable to cold starts):

1. **Increase auto-pause delay:** Extend to the maximum configurable value to reduce cold start frequency during operating hours. No code change — Terraform variable update only.
2. **Switch to provisioned compute (preferred fallback):** Change Terraform `sql_sku_name` from `GP_S_Gen5_2` (Serverless) to `S0` (provisioned, ~$15/month). Azure SQL supports online SKU changes with minimal downtime. **No application code changes required.**
3. **Scheduled warm-up ping:** Add a lightweight Container Apps Job running every 45 minutes during business hours (8 AM–10 PM UTC) that executes a trivial SQL query (`SELECT 1`) to prevent auto-pause. Free to operate; eliminates cold starts at the cost of making the "serverless" behaviour moot.
