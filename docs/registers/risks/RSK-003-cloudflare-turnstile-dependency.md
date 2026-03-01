---
title: "RSK-003: Cloudflare Turnstile External Dependency"
description: Reliance on Cloudflare Turnstile as a third-party service introduces availability and policy-change risk for bot protection.
tags:
  - risk
  - risk-register
  - cloudflare-turnstile
---

# Cloudflare Turnstile External Dependency

**ID:** RSK-003

## Risk Statement

The CFP submission form depends on Cloudflare Turnstile for bot protection: the Turnstile JavaScript widget must load in the browser, and Cloudflare's server-side token verification API must respond successfully when the API validates a submission. If Cloudflare experiences an outage or degrades its Turnstile service, new CFP submissions may be blocked entirely — even for legitimate organizers.

## Root Cause / Trigger

- Cloudflare Turnstile is a free, externally-hosted service. The JavaScript widget is loaded from Cloudflare's CDN (`challenges.cloudflare.com`); the token verification call is made from the CFP Compass API to Cloudflare's API at submission time (ADR-012).
- CFP Compass has no operational control over Cloudflare's availability or API behaviour.
- Trigger scenarios: (a) Cloudflare CDN outage prevents Turnstile JS from loading in submitters' browsers; (b) Cloudflare's siteverify API (`https://challenges.cloudflare.com/turnstile/v0/siteverify`) becomes unreachable or returns errors from the server side.

## Impact Assessment

- **CFP submissions:** New submissions fail if Turnstile cannot complete the challenge (browser-side) or if server-side verification returns an error. Organizers attempting to submit a CFP during an outage receive a form submission error.
- **Existing data:** No impact. Published CFPs, user accounts, tracking state, and all existing data are completely unaffected.
- **Authenticated users:** Speaker browsing, tracking, and all authenticated workflows continue normally.
- **Admin queue:** Existing submissions in the moderation queue are unaffected; admin workflows continue.
- **Duration:** Dependent on Cloudflare's recovery timeline. Cloudflare historically resolves incidents within minutes to low hours.

## Likelihood

**Low**

Cloudflare's infrastructure is globally distributed with multiple redundancy layers and a historical availability well above 99.9%. Turnstile-specific outages are rare. The most credible failure mode is a transient Cloudflare API degradation, not a complete outage.

## Severity

**Medium**

The impact is bounded to new CFP submission creation only. No existing data or user workflows are disrupted. However, if an outage coincides with a popular CFP deadline, organizers may be unable to submit time-sensitive listings — which is the core value proposition of the platform.

## Mitigation Strategy

- **Honeypot field fallback:** A honeypot field is included in the submission form regardless of Turnstile status. If Turnstile is unavailable, the honeypot provides passive bot protection as a first line of defence.
- **Graceful server-side fallback:** The server-side Turnstile verification is implemented to fall through gracefully when the Cloudflare API is unreachable (HTTP timeout or connection error), rather than hard-failing the submission. A configurable `TURNSTILE_STRICT_MODE` flag controls whether unreachable Cloudflare API causes a hard rejection or a logged bypass.
- **Turnstile "managed" mode:** The widget is configured in `managed` mode, which allows Cloudflare to silently pass challenges in degraded conditions rather than requiring explicit user interaction that may fail.
- **Alerting:** Alert on Turnstile verification failure rate exceeding 10% in any 5-minute window — distinguishing between spam rejections (expected) and API-unreachable errors (incident signal).
- **Cloudflare status monitoring:** Cloudflare status page (`cloudflarestatus.com`) is included in the on-call monitoring checklist.

## Detection Signals

- Application Insights custom metric: Turnstile verification result `cf-error` (Cloudflare API error) rate > 10% in 5-minute window.
- Application Insights custom metric: Turnstile verification HTTP timeout rate > 5% in 5-minute window — indicates Cloudflare API is unreachable from the Azure Functions/API Host network.
- Zero new CFP submissions over an abnormally long period (indirect signal when submission volume is normally non-zero).
- Cloudflare Turnstile dashboard showing widget load failures or verification errors.

## Contingency Plan

1. Confirm Cloudflare incident via `cloudflarestatus.com`; check Turnstile widget load success rate in browser analytics.
2. Set `TURNSTILE_STRICT_MODE=false` via Key Vault configuration update (or environment variable on the API Container App). This allows submissions to pass through with honeypot-only protection during the Cloudflare outage.
3. Monitor the admin moderation queue for an increase in spam submissions during the bypass period.
4. Re-enable `TURNSTILE_STRICT_MODE=true` once Cloudflare confirms recovery.
5. Review spam submissions that passed during the bypass window; reject as appropriate via admin moderation.

## Review Schedule

Review annually, or immediately if Cloudflare announces changes to the Turnstile service, pricing model, or API contract. Re-evaluate if honeypot bypass period results in significant spam increases, indicating honeypot alone is insufficient.
