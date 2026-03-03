---
title: "ASM-004: Azure Communication Services Email Delivery Rates"
description: Azure Communication Services will achieve acceptable email delivery rates for transactional notifications.
tags:
  - assumption
  - assumption-register
  - azure-communication-services
---

# Azure Communication Services Email Delivery Rates

**ID:** ASM-004

## Statement

Azure Communication Services (ACS) will successfully deliver transactional and batch emails sent from `noreply@cfpcompass.com` with delivery rates acceptable for the CFP Compass use case — specifically: submission confirmation emails delivered within 2 minutes of submission processing, deadline reminder emails delivered before the tracked deadline, and weekly digest emails delivered within the scheduled send window.

## Context / Rationale

ACS Email was selected as the email service provider for all CFP Compass email flows (Decision 5). It was chosen over alternatives such as SendGrid and Mailgun for its native Azure integration, AAD-based authentication, and no per-email cost at low-to-moderate volumes.

Email deliverability for a new sending domain (`cfpcompass.com`) is a well-understood challenge: new domains have no sending reputation history with inbox providers (Gmail, Outlook, Yahoo, etc.). Poor inbox placement during the initial launch period is a common experience for new senders that improves as sending history and domain reputation build over weeks and months.

Key deliverability prerequisites for ACS Email:

1. **SPF record:** `v=spf1 include:spf.protection.outlook.com -all` (or ACS-specific SPF) on `cfpcompass.com`.
2. **DKIM record:** Azure Communication Services generates DKIM keys during domain verification; the public DKIM key is published as a DNS TXT record on `cfpcompass.com`.
3. **DMARC record:** `v=DMARC1; p=none; rua=mailto:dmarc@cfpcompass.com` initially (reporting mode); upgrade to `p=quarantine` or `p=reject` as domain reputation matures.
4. **Domain verification in ACS portal:** ACS requires DNS TXT verification record before allowing email sending from the domain.

All four prerequisites depend on `cfpcompass.com` being registered and DNS-controlled (ASM-001).

## Scope of Impact

All CFP Compass email flows are affected:

| Email Type | Trigger | Job / Processor |
|------------|---------|----------------|
| CFP submission confirmation | Organizer submits CFP | `NotificationProcessor` (Azure Function) |
| CFP approval notification | Admin approves submission | `NotificationProcessor` |
| CFP rejection notification | Admin rejects submission | `NotificationProcessor` |
| Reconsideration outcome notification | Admin reviews reconsideration | `NotificationProcessor` |
| Deadline reminder (7-day) | Scheduled job | `DeadlineReminderJob` |
| Deadline reminder (24-hour) | Scheduled job | `DeadlineReminderJob` |
| Weekly digest | Scheduled job (Monday morning) | `WeeklyDigestJob` |
| Account welcome email | User registers | `UserAccountProcessor` (Azure Function) |
| Password reset | User requests reset | Direct API call |
| Organizer claim approved/rejected | Admin reviews claim | `NotificationProcessor` |

`WeeklyDigestJob` and `DeadlineReminderJob` batch send to potentially hundreds of subscribers; ACS Email throughput and any send-rate limits are relevant for these operations.

## Risk Level

**Medium**

New domain with no sending history may experience initial inbox placement issues (emails landing in spam folders) for the first 4–6 weeks of production sending. ACS Email has known deliverability strengths for transactional email to Microsoft domains (Outlook, Hotmail) but Gmail and Yahoo inbox placement depends on domain reputation. This is a time-bounded risk that resolves as sending history establishes domain reputation.

## Validation Evidence

Pending. DNS verification and initial test sends must be completed before launch.

- ACS Email domain verification: Chad Green to complete in Azure portal before first production email.
- SPF/DKIM/DMARC DNS records: Parker (DevOps) to add to DNS zone configuration in Terraform (`azure_dns_zone` module).
- Pre-launch deliverability test: Send test emails to Gmail, Outlook, Yahoo, and Apple Mail accounts; verify inbox placement before public launch.
- ACS Email sending limits: Review ACS Email documentation for applicable send-rate limits on the selected ACS resource tier.

## Dependencies

- `ASM-001` (domain registration): `cfpcompass.com` must be registered and DNS-controlled before ACS domain verification can be completed.
- DNS zone configuration: SPF, DKIM, and DMARC records must be added to the Terraform DNS module before deployment.
- ACS Email resource provisioning: ACS resource must be created and domain verified before any Application or Infrastructure code calls `IEmailService`.

## Review Cadence / Expiry

Review monthly for the first 3 months post-launch (monitor deliverability metrics, bounce rates, spam complaint rates via ACS Email delivery reports). Review quarterly thereafter. Escalate immediately if bounce rate exceeds 5% or spam complaint rate exceeds 0.1%.

## Fallback Plan

If ACS deliverability is unacceptably poor (sustained bounce rates > 5%, inbox placement failure for major providers):

1. **Warm-up period:** Implement a gradual send-volume ramp-up for the first 4 weeks (start with 50 emails/day, double weekly) to build domain reputation before full-volume sending.
2. **Alternative provider:** The `IEmailService` interface in `CFPCompass.Application` abstracts the email provider. Replace the ACS implementation (`CFPCompass.Infrastructure/Email/AcsEmailService.cs`) with a SendGrid or Mailgun implementation. No changes to application logic, job implementations, or email template rendering.
3. **SendGrid free tier:** 100 emails/day free; sufficient for MVP volumes. SMTP or SendGrid API client can be implemented behind `IEmailService` in under a day.
4. **Dedicated IP (ACS):** If volume justifies it, request a dedicated sending IP from ACS to isolate CFP Compass reputation from other ACS senders on shared IPs.
