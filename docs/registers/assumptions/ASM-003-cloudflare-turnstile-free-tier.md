---
title: "ASM-003: Cloudflare Turnstile Free Tier Remains Available"
description: Cloudflare Turnstile's free tier will remain available and sufficient for CFP Compass traffic volumes.
tags:
  - assumption
  - assumption-register
  - cloudflare-turnstile
---

# Cloudflare Turnstile Free Tier Remains Available

**ID:** ASM-003

## Statement

Cloudflare Turnstile's free tier, which provides unlimited CAPTCHA challenge verifications, remains available and free of charge throughout the operational lifetime of CFP Compass. No usage-based billing or rate limiting on free-tier verifications is introduced by Cloudflare.

## Context / Rationale

Cloudflare Turnstile was selected as the bot protection mechanism for the CFP submission form (ADR-012). A key factor in this selection — compared to alternatives such as Google reCAPTCHA v3 and hCaptcha — was that Turnstile offers genuinely unlimited verifications on the free tier with no commercial licence requirement, no per-verification charge, and no enterprise-tier requirement for higher volumes.

Turnstile launched in September 2022 and has maintained its free, unlimited verification model since launch. Cloudflare's stated positioning is that Turnstile is a privacy-preserving CAPTCHA replacement that Cloudflare provides as a service to drive adoption of its broader platform — not as a standalone revenue-generating product. This business rationale provides reasonable confidence in the free tier's longevity.

This assumption was validated against Cloudflare's public pricing page at the time of architecture design. The honeypot field, which is implemented regardless of Turnstile status, provides a zero-cost fallback that would remain in place if this assumption is invalidated.

## Scope of Impact

- CFP submission form bot protection (`CFPCompass.Web` — submission form component)
- API server-side Turnstile token verification (`CFPCompass.Api` — submission endpoint)
- ADR-012: Cloudflare Turnstile bot protection decision
- Infrastructure cost assumptions (Turnstile is currently $0 in the cost model)

## Risk Level

**Low**

Cloudflare has not introduced pricing on Turnstile since its launch in 2022. The honeypot field already provides a free baseline of passive protection; if Turnstile became paid, the honeypot alone or a free alternative (hCaptcha free tier) would be viable replacements with minimal code changes. The `ITurnstileVerificationService` interface in `CFPCompass.Application` abstracts the verification provider, making a swap low-effort.

## Validation Evidence

Cloudflare's public documentation confirms free tier availability as of architecture design date (Q1 2026):

- Cloudflare Turnstile pricing page: `https://developers.cloudflare.com/turnstile/` — no pricing section; free tier stated as standard offering.
- Cloudflare blog post (September 2022): "Cloudflare Turnstile: A Private, CAPTCHA-free Experience" — explicitly states free availability.
- No Cloudflare product announcement or changelog indicates pricing introduction is planned.

## Dependencies

- No cost dependencies; Turnstile is free and requires only a Cloudflare account and site key registration.
- Site key and secret key stored in Azure Key Vault (`TURNSTILE_SITE_KEY`, `TURNSTILE_SECRET_KEY`).
- If Turnstile pricing is introduced, a budget approval step may be required depending on per-verification cost at CFP Compass submission volumes.

## Review Cadence / Expiry

Review annually, or immediately upon any Cloudflare announcement regarding Turnstile pricing, service terms changes, or product deprecation notices. Monitor Cloudflare's product changelog (`developers.cloudflare.com/changelog/`) as part of the annual architecture review.

## Fallback Plan

If Cloudflare introduces pricing on Turnstile that is not acceptable for the CFP Compass budget:

1. **Immediate fallback:** Disable Turnstile server-side verification; rely on honeypot field alone (already implemented; zero cost; provides passive bot filtering with no user friction). Update `TURNSTILE_STRICT_MODE=false` in Key Vault.
2. **Alternative CAPTCHA (if honeypot insufficient):** Evaluate hCaptcha free tier (100,000 verifications/month free) or Friendly Captcha (free tier available). Implement via `ITurnstileVerificationService` interface replacement — no changes to form components or API controllers.
3. **Google reCAPTCHA v3 (last resort):** Free up to 1M assessments/month; privacy trade-offs accepted in ADR-012 are revisited if volume justifies Google's free tier. Implement via interface replacement.
