---
title: "ADR-012: Bot Protection: Cloudflare Turnstile + Honeypot"
description: Cloudflare Turnstile invisible challenge combined with a hidden honeypot field is adopted as the GDPR-compliant, zero-friction bot protection strategy for the public CFP submission form.
tags:
  - adr
  - architecture-decision-record
  - cloudflare-turnstile
  - security
status: accepted
---

# Bot Protection: Cloudflare Turnstile + Honeypot

- **Status:** Accepted
- **Date:** 2026-02-28
- **Work Item:** [*arch-012* — public form bot protection strategy]

## Context and Problem

The CFP submission form at `cfpcompass.com/submit` is entirely public and requires no account. Any visitor can submit a CFP directly. This open-submission model is intentional (zero friction for event organizers), but it creates a risk of automated spam submissions flooding the admin moderation queue. Bot protection is needed that stops automated submissions without introducing friction for legitimate organizers, and without violating the privacy expectations of the international developer community (GDPR, LGPD, PIPEDA compliance). Cloudflare is already in the infrastructure as Azure Front Door handles CDN, so a non-Google, privacy-first bot protection approach is preferred.

## Decision Drivers

- Prevent automated spam submissions from degrading the admin moderation queue
- Zero friction for legitimate users (invisible to human visitors)
- GDPR-compliant — no persistent cross-site tracking cookies; no Google Analytics-style profiling
- No cost at MVP scale (unlimited free tier preferred)
- No false positives for VPN or proxy users (common among the developer/tech community audience)
- Defense in depth — at least two independent layers of protection
- No external dependency on Google services (reCAPTCHA carries GDPR Article 26 DPA requirements)

## Considered Options

- Cloudflare Turnstile (invisible challenge) + hidden honeypot field
- Google reCAPTCHA v3 (score-based, invisible)
- Honeypot hidden field only (passive, no external service)

## Decision Outcome

Chosen option: **Cloudflare Turnstile (invisible challenge) + hidden honeypot field**, because it provides the highest combined score (4.70/5.00) in the weighted decision matrix, eliminates Google's cross-site tracking dependency, offers unlimited free verifications with no VPN false positives, and is fully GDPR-compliant without requiring a cookie consent banner. The honeypot adds a zero-cost passive layer that functions even if Turnstile's JavaScript fails to load.

#### Consequences

- Good, because Turnstile is completely invisible to legitimate users — zero friction for event organizers.
- Good, because GDPR-compliant: Cloudflare's privacy policy for Turnstile does not require cross-site tracking cookies or a Data Processing Agreement (DPA) for basic integration.
- Good, because free unlimited verifications — no cost dependency on submission volume.
- Good, because zero false positives for VPN/proxy users — unlike reCAPTCHA v3 which scores VPN users as suspicious.
- Good, because the honeypot provides a passive second layer with zero external dependency — works if Turnstile JS fails.
- Good, because no Google dependency — aligns with the privacy expectations of the developer/tech community audience.
- Bad, because Turnstile adds Cloudflare as a dependency for form submission validation — low risk (free tier, no CDN coupling), but a new external service.
- Bad, because server-side token verification requires an outbound HTTPS call to Cloudflare's verification API (`challenges.cloudflare.com/turnstile/v0/siteverify`) — adds a small latency to submission processing.

#### Implementation

1. Lambert adds the Cloudflare Turnstile JavaScript widget to the CFP submission form (`<script src="https://challenges.cloudflare.com/turnstile/v0/api.js">`).
2. Turnstile renders invisibly — no user interaction required. It generates a `cf-turnstile-response` token on form load.
3. Lambert adds a honeypot hidden field (`<input type="text" name="website" style="display:none" tabindex="-1" autocomplete="off">`). Bots fill it; humans leave it blank.
4. On form submission, the Blazor Server backend performs two checks before any processing:
   a. **Honeypot check:** if the `website` field is non-empty, silently discard the submission and return a fake success response (no error message to avoid bot fingerprinting).
   b. **Turnstile token verification:** POST to `https://challenges.cloudflare.com/turnstile/v0/siteverify` with the `secret` key (from Key Vault: `Turnstile-SecretKey`) and the submitted token. If verification fails, return HTTP 400 with an error message.
5. `Turnstile-SiteKey` (public, used in the widget) and `Turnstile-SecretKey` (server-side verification) are stored in Key Vault.
6. Parker adds both secrets to the Key Vault Terraform module.

#### Confirmation

- Automated form submission (no Turnstile token) rejected with 400 error.
- Submission with honeypot field populated silently discarded; caller receives fake success response.
- Valid human submission (Turnstile token present and valid) processes successfully.
- Turnstile verification tested with Cloudflare test keys in dev/staging before production keys.
- No cookie consent banner required (confirmed by Cloudflare privacy policy review).

#### Stakeholders

- **Dallas (Lead & Architect):** Produced full comparison document; recommended Turnstile + honeypot hybrid
- **Chad Green (Product Owner):** Final decision authority; approved Turnstile + honeypot after reviewing comparison
- **Lambert (Frontend):** Implements Turnstile widget and honeypot field on submission form
- **Ripley (Backend):** Implements server-side Turnstile token verification and honeypot check in submission API
- **Parker (DevOps):** Adds `Turnstile-SiteKey` and `Turnstile-SecretKey` to Key Vault Terraform module

## Pros and Cons of the Options

### Cloudflare Turnstile + Honeypot (Score: 4.70/5.00)

- Good, because invisible to legitimate users — zero friction.
- Good, because GDPR-compliant: no persistent cross-site tracking, no DPA required.
- Good, because free unlimited verifications.
- Good, because zero false positives for VPN/proxy users.
- Good, because honeypot adds a passive layer with zero external dependency.
- Good, because no Google dependency.
- Neutral, because Cloudflare is a new external dependency — low risk, free tier, separate from CDN choice.
- Bad, because requires outbound HTTP call to Cloudflare API for token verification (< 100ms typically).

### Google reCAPTCHA v3 (Score: 4.15/5.00)

- Good, because score-based, invisible to users.
- Good, because widely deployed and understood by developers.
- Good, because free up to 1 million assessments/month.
- Neutral, because score threshold requires tuning to balance security and false positives.
- Bad, because GDPR concerns — Google processes user data cross-site; requires cookie consent banner in EU contexts.
- Bad, because false positives for VPN/proxy users — common in the developer community — may block legitimate organizers.
- Bad, because Google dependency introduces a third-party tracking relationship.
- Bad, because GDPR Article 26 Data Processing Agreement may be required depending on data controller context.

### Honeypot Only (Score: 2.80/5.00)

- Good, because zero external dependencies.
- Good, because zero cost.
- Good, because fully GDPR-compliant (no external service).
- Good, because invisible to legitimate users (CSS-hidden field).
- Neutral, because no JS required — works even in no-script environments.
- Bad, because ineffective against sophisticated bots that parse HTML and skip hidden fields.
- Bad, because single layer — no active bot detection; relies purely on bot naivety.
- Bad, because provides minimal assurance against targeted spam campaigns.

## More Information

Weighted decision matrix scores (Effectiveness 25%, Privacy 20%, Cost 15%, Implementation 15%, UX 10%, Maintenance 10%, Vendor Risk 5%):

| Option | Effectiveness | Privacy | Cost | Implementation | UX | Maintenance | Vendor Risk | **Total** |
|--------|--------------|---------|------|---------------|-----|------------|------------|---------|
| Turnstile + Honeypot | 4.5 | 5.0 | 5.0 | 4.5 | 5.0 | 4.5 | 4.0 | **4.70** |
| reCAPTCHA v3 | 5.0 | 2.5 | 4.5 | 4.5 | 4.5 | 4.0 | 3.0 | **4.15** |
| Honeypot Only | 2.0 | 5.0 | 5.0 | 5.0 | 5.0 | 5.0 | 5.0 | **2.80** |

Cloudflare Turnstile documentation: https://developers.cloudflare.com/turnstile/

Test keys for dev/staging (public, official Cloudflare test keys):
- Site key: `1x00000000000000000000AA` (always passes)
- Secret key: `1x0000000000000000000000000000000AA` (always passes)

## Follow-On Information

Monitor submission spam rates after launch. If Turnstile + honeypot is insufficient against sophisticated targeted attacks, the next defensive layer would be:
1. Rate limiting at the APIM and app level (already configured: 10 submissions/hour per IP)
2. Admin-configurable keyword blocklist on the submission form
3. Manual challenge (visible CAPTCHA) triggered on suspicious patterns

## Record History

* **Proposed**: 2026-02-28
* **Accepted**: 2026-02-28 (Chad Green approval)
* **Last Reviewed**: 2026-02-28
