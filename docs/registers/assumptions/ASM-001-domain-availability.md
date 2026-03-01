---
title: "ASM-001: cfpcompass.com Domain Availability and DNS Control"
description: The cfpcompass.com domain is available for registration and DNS can be managed via Cloudflare.
tags:
  - assumption
  - assumption-register
  - cloudflare
---

# cfpcompass.com Domain Availability and DNS Control

**ID:** ASM-001

## Statement

The domain `cfpcompass.com` is available for registration and will be controlled by the project owner (Chad Green / TaleLearnCode) for the full operational lifetime of the CFP Compass application.

## Context / Rationale

Domain availability was discussed and verified as a prerequisite during architecture planning. The domain underpins multiple infrastructure components that cannot function without it:

- **CORS policies:** The API Host Container App restricts cross-origin requests to `https://cfpcompass.com` and `https://www.cfpcompass.com`. Incorrect domain control breaks web app → API communication.
- **ACS email domain verification:** Azure Communication Services requires SPF, DKIM, and DMARC DNS records on `cfpcompass.com` to send email from `noreply@cfpcompass.com`. Without DNS control, email delivery cannot be verified or trusted.
- **Azure Front Door custom domain:** Front Door's custom domain (`cfpcompass.com`) requires DNS ownership verification via a CNAME or TXT record.
- **APIM custom domain:** The developer portal and API gateway are served at `api.cfpcompass.com`, requiring DNS control to configure the CNAME pointing to the APIM gateway URL.
- **SSL certificate provisioning:** Managed SSL certificates (via Azure Front Door or Let's Encrypt) require DNS-01 or HTTP-01 domain ownership challenges.

The domain must be registered **before** infrastructure provisioning begins, as Terraform modules reference the domain name and CI/CD pipelines generate environment configurations that embed it.

## Scope of Impact

- CORS configuration in the API Host Container App (`CFPCompass.Api`)
- Email sender identity (`noreply@cfpcompass.com`) and ACS domain verification (SPF/DKIM/DMARC records)
- Azure Front Door custom domain routing and SSL certificate
- APIM custom domain (`api.cfpcompass.com`) and developer portal URL
- All environment-specific configuration referencing the production domain
- Terraform variable `domain_name` used across infrastructure modules

## Risk Level

**High**

If the domain is not registered and controlled before infrastructure provisioning, all domain-dependent features fail during deployment. There is no graceful fallback for production operations — Azure-generated default hostnames (`*.azurecontainerapps.io`, `*.azure-api.net`) cannot substitute for a consistent public-facing identity once user-facing URLs have been communicated.

## Validation Evidence

Pending domain registration. Chad Green (TaleLearnCode) to register `cfpcompass.com` via preferred registrar before infrastructure provisioning milestone.

- Domain availability check: Verified available at architecture planning stage (Q1 2026).
- Registration responsibility: Assigned to Chad Green; must be completed before Parker begins Terraform provisioning.
- DNS hosting: DNS records to be managed via the registrar's DNS or delegated to Azure DNS zones (Terraform module `azure_dns_zone`).

## Dependencies

- Domain registration must be completed before Terraform `infrastructure/` provisioning begins.
- ACS domain verification (SPF/DKIM/DMARC) must be completed before any email sending is attempted (`ASM-004`).
- Front Door and APIM custom domain configuration depend on DNS zone delegation being in place.

## Review Cadence / Expiry

Review at each infrastructure provisioning milestone and annually thereafter to confirm domain registration renewal. Flag immediately if domain registrar contact information changes or renewal is at risk.

## Fallback Plan

If `cfpcompass.com` is unavailable or registration is delayed:

1. Use Azure-provided default hostnames temporarily during development and staging: `*.azurecontainerapps.io` for the web app and API, `*.azure-api.net` for APIM.
2. Update all environment configuration and CORS policies to reflect the temporary hostnames.
3. Register an alternative domain (e.g., `cfp-compass.com`, `cfpcompassapp.com`) if `cfpcompass.com` cannot be secured, and propagate the new domain name through all Terraform variables and application configuration.
4. Do not launch the production environment publicly until a consistent, owned domain is in place.
