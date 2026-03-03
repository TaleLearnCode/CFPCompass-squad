---
title: Assumptions Register
description: Register of project assumptions for CFP Compass, with validation status and impact assessments.
tags:
  - assumption
  - assumption-register
  - register
---

# Assumption Register — CFP Compass

This register documents the assumptions that underpin architectural and infrastructure decisions for CFP Compass. When an assumption is invalidated, it may activate a corresponding risk or require an architectural decision record to be revisited.

## How to Use This Register

- **Risk Level:** How harmful is it if this assumption proves false? (`Low` / `Medium` / `High`)
- **Status:** `Active` — assumption is in force and unvalidated; `Validated` — confirmed by evidence; `Invalidated` — proven false; review the fallback plan.
- **Review Cadence:** How often should this assumption be re-checked?

Add a new assumption when:
- An architectural decision was made on the basis of an unconfirmed external fact.
- A key dependency (pricing, regional availability, third-party service behaviour) is taken as a given without current evidence.
- A "good enough for MVP" design choice depends on a condition that may not hold at scale.

## Assumption Summary

| ID | Title | Risk Level | Status | Review Cadence |
|----|-------|-----------|--------|----------------|
| [ASM-001](ASM-001-domain-availability.md) | cfpcompass.com Domain Availability and DNS Control | High | Active | Before infrastructure provisioning; annually thereafter |
| [ASM-002](ASM-002-azure-service-regional-availability.md) | Azure Services Available in Selected Deployment Region | Medium | Active | At region selection; on new service additions |
| [ASM-003](ASM-003-cloudflare-turnstile-free-tier.md) | Cloudflare Turnstile Free Tier Remains Available | Low | Active | Annually |
| [ASM-004](ASM-004-acs-email-delivery.md) | Azure Communication Services Email Delivery Rates | Medium | Active | Monthly (first 3 months post-launch); quarterly thereafter |
| [ASM-005](ASM-005-sql-serverless-auto-pause-acceptable.md) | Azure SQL Serverless Auto-Pause Cold Start Is Acceptable for MVP | High | Active | First 30 days post-launch; quarterly thereafter |

## Validation Checklist

The following assumptions must be validated **before production launch**:

| ID | Validation Action | Owner | Target Date |
|----|------------------|-------|------------|
| ASM-001 | Register `cfpcompass.com`; confirm DNS control | Chad Green | Before infrastructure provisioning |
| ASM-002 | Validate all 11 Azure services available at target SKUs in selected region | Parker (DevOps) | At region selection |
| ASM-004 | Complete ACS Email domain verification (SPF/DKIM/DMARC); run deliverability tests | Parker (DevOps) | Before first production email send |
| ASM-005 | Measure cold start duration in staging; validate Service Bus lock timeout > cold start duration | Parker / Ripley | During staging validation |

ASM-003 (Turnstile free tier) does not require active validation steps — it is confirmed by Cloudflare's public pricing page and monitored annually.

## Related Documents

- [Risk Register](../risks/README.md) — activated risks when assumptions are invalidated:
  - ASM-001 failure → immediate infrastructure blockers (not a risk; a prerequisite).
  - ASM-005 failure → activates RSK-001 (SQL Cold Start Latency) mitigation contingency.
  - ASM-004 failure → email delivery fallback (SendGrid via `IEmailService` interface).
- [Decisions Register](../decisions/README.md) — ADRs that depend on these assumptions:
  - ASM-001 → CORS, ACS Email, APIM custom domain (all ADRs involving domain-specific config)
  - ASM-003 → ADR-012 (Cloudflare Turnstile selection)
  - ASM-005 → ADR-001 (Azure SQL Serverless), ADR-007 (event-driven writes), ADR-011 (APIM caching)
