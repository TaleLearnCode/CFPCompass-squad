---
title: Risk Register
description: Register of identified risks for CFP Compass, with severity ratings, likelihood assessments, and mitigation strategies.
tags:
  - risk
  - risk-register
  - register
---

# Risk Register — CFP Compass

This register tracks identified risks to the CFP Compass architecture, infrastructure, and external dependencies. Each risk is assessed for likelihood and severity, with documented mitigation strategies and contingency plans.

## How to Use This Register

- **Likelihood:** How probable is this risk materialising? (`Low` / `Medium` / `High`)
- **Severity:** If this risk materialises, how bad is the impact? (`Low` / `Medium` / `High`)
- **Status:** `Open` — actively monitored; `Mitigated` — controls in place and verified effective; `Closed` — risk no longer applicable.

Add a new risk entry when:
- An architectural decision explicitly accepts a trade-off that could cause future harm.
- An external dependency is identified with no SLA or limited redundancy.
- A known constraint (cost, SKU choice, third-party service) may degrade user experience or system availability.

## Risk Summary

| ID | Title | Likelihood | Severity | Status |
|----|-------|-----------|----------|--------|
| [RSK-001](RSK-001-sql-serverless-cold-start.md) | Azure SQL Serverless Cold Start Latency | High | Medium | Open |
| [RSK-002](RSK-002-apim-developer-tier-availability.md) | APIM Developer Tier Availability Limitation | Low | High | Open |
| [RSK-003](RSK-003-cloudflare-turnstile-dependency.md) | Cloudflare Turnstile External Dependency | Low | Medium | Open |
| [RSK-004](RSK-004-service-bus-message-processing-lag.md) | Service Bus Message Processing Lag | Low | Low | Open |
| [RSK-005](RSK-005-azure-managed-redis-pricing.md) | Azure Managed Redis Pricing at Scale | Medium | Low | Open |

## Risk Heat Map

|              | **Low Severity** | **Medium Severity** | **High Severity** |
|--------------|-----------------|--------------------|--------------------|
| **High Likelihood**   | — | RSK-001 | — |
| **Medium Likelihood** | RSK-005 | — | — |
| **Low Likelihood**    | RSK-004 | RSK-003 | RSK-002 |

## Related Documents

- [Assumptions Register](../assumptions/README.md) — assumptions that underpin architectural decisions; assumption failures may activate risks in this register.
- [Decisions Register](../decisions/README.md) — architecture decision records where trade-offs were consciously accepted.
- Key cross-references:
  - RSK-001 is mitigated by ADR-007 (event-driven writes) and ADR-011 (APIM caching).
  - RSK-002 accepted in ADR-006 (APIM Developer tier selection).
  - RSK-003 accepted in ADR-012 (Cloudflare Turnstile bot protection).
  - RSK-005 mitigated by ADR-005 (containerised Redis fallback).
  - RSK-001 and ASM-005 are directly related (cold start acceptability assumption).
