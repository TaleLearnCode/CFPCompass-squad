# SSIS Job Cadence Assumption

**ID:** ASM‑001

## Statement

The SSIS jobs that synchronize item master data from the DataFlex Oracle database to the JET Enterprise SQL Server database run **every 5 minutes during business hours** for the relevant data models.

## Context / Rationale

Several architectural options depend on the cadence at which authoritative item master data becomes available in JET Enterprise. Early discussions suggested nightly SSIS execution; subsequent clarification confirmed that the primary data-transfer jobs run at a 5-minute interval during business hours, with a separate nightly reconciliation job.

This assumption underpins the feasibility of event‑driven and batch‑driven replication strategies that source data from JET Enterprise rather than directly from DataFlex.

## Scope of Impact

- Item Master Data Retrieval Strategy ADR
- Event‑driven replication design (Option 2C)
- Data freshness SLA/SLO definitions
- Ingestion pipeline scheduling and monitoring
- Stakeholder expectations for “near real‑time” behavior

## Risk Level

<!-- markdownlint-disable-next-line MD036 -->
**High**

If the SSIS cadence is reduced, paused, or reverted to nightly execution, downstream systems will not meet agreed-upon freshness expectations.

## Validation Evidence

- Confirmation from the database team that SSIS data transfer jobs execute every five minutes during business hours.
- Existing SSIS job schedules and operational run history.
- Observed data arrival timestamps in JET Enterprise during business hours.

## Dependencies

- Continued operational support and monitoring of SSIS jobs.
- No material increase in SSIS execution latency or failure rates.
- No architectural changes that bypass or delay SSIS synchronization.

## Review Cadence / Expiry

Review quarterly, or immediately upon any change to SSIS scheduling, scope, or ownership.

## Fallback Plan

If SSIS cadence cannot be maintained, reassess data freshness guarantees and evaluate alternative change‑detection strategies (e.g., CDC‑based replication from DataFlex).
