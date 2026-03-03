---
title: "ADR-003: ASP.NET Core Identity over Azure AD B2C"
description: Selects ASP.NET Core Identity with Fido2NetLib over Azure AD B2C to provide native passkey (WebAuthn/FIDO2) support, zero per-authentication cost, full UI control, and simple admin identification via a Key Vault-stored email list.
tags:
  - adr
  - architecture-decision-record
  - aspnet-core
  - identity
  - authentication
  - passkeys
status: accepted
---
# ASP.NET Core Identity over Azure AD B2C

- **Status:** Accepted
- **Date:** 2026-02-28
- **Work Item:** [*arch-003* — authentication and identity provider selection]

## Context and Problem

CFP Compass requires authentication for speakers (who track CFPs), admins (who moderate submissions), and organizers (who claim listings). Authentication must support passkeys (WebAuthn/FIDO2) as a phishing-resistant first-class login option, OAuth social login (Google, GitHub, Microsoft), and a simple mechanism for identifying admin accounts without an admin management UI. The system must be cost-effective at MVP scale and allow full control over the login UI and user experience. Azure AD B2C was the original assumption before passkey requirements were clarified.

## Decision Drivers

- Passkey (WebAuthn/FIDO2) support as a first-class, non-bolted-on authentication method
- No per-authentication charges — cost predictability at any scale
- Simple admin identification via a configurable email list without complex group/role management in an external directory
- Full UI customisation without custom policies or external templates
- .NET-native implementation sharing domain models with the rest of the stack
- OAuth social login support (Google, GitHub, Microsoft) without additional services

## Considered Options

- ASP.NET Core Identity with Fido2NetLib (self-hosted)
- Azure AD B2C (managed identity service)

## Decision Outcome

Chosen option: **ASP.NET Core Identity with Fido2NetLib**, because it provides full, native WebAuthn/FIDO2 passkey support without the complexity of Azure AD B2C custom policies, charges no per-authentication fees, and allows admin identification to be as simple as a Key Vault-stored email list checked at login. The team retains full UI control and avoids an external dependency for the core authentication flow.

#### Consequences

- Good, because full control over passkey registration and login flow via Fido2NetLib — no custom policy authoring required.
- Good, because no per-authentication charges — cost is fixed regardless of login volume.
- Good, because admin email check is implemented as a simple lookup against the `AdminEmails` Key Vault secret on every login — no B2C group mapping or custom attributes.
- Good, because UI is fully customisable using standard Blazor/Razor components — no B2C hosted page templates or iframes.
- Good, because OAuth social login (Google, GitHub, Microsoft) is built into ASP.NET Core Identity's external provider middleware.
- Bad, because we own the security surface — must implement and maintain account lockout, token rotation, password hashing, and security hardening. (Mitigated: ASP.NET Core Identity handles these natively.)
- Bad, because no enterprise SSO (SAML, OpenID Connect federation) out of the box — can be added later via ASP.NET Core OpenID Connect middleware if required.

#### Implementation

1. Ripley adds `Microsoft.AspNetCore.Identity.EntityFrameworkCore` to `CFPCompass.Api` and configures the Identity store against the Azure SQL Database.
2. `Fido2NetLib` NuGet package is added to the API project for WebAuthn credential registration and assertion handling.
3. Passkey credential storage uses a `PasskeyCredential` entity linked to `ApplicationUser` in the EF Core schema.
4. OAuth providers (Google, GitHub, Microsoft) are configured via `AddAuthentication().AddGoogle().AddGitHub().AddMicrosoftAccount()` with client IDs/secrets stored in Key Vault.
5. Admin identification: a startup service reads `AdminEmails` from Key Vault; an `IAdminEmailService` is injected into the login flow to check the authenticated user's email against the list and assign the admin role claim.
6. Account lockout (5 failed attempts, 15-minute lockout), password requirements, and token expiry are configured in `IdentityOptions`.
7. Single-use email tokens (72h expiry for organizer edits, 7-day expiry for organizer claims) are issued via `UserManager<ApplicationUser>.GenerateUserTokenAsync`.

#### Confirmation

- Passkey registration and login round-trip tested in integration tests using a FIDO2 test harness.
- Social login tested with each configured OAuth provider in staging environment.
- Admin login confirmed to assign admin role claim for emails in the `AdminEmails` Key Vault secret.
- Account lockout confirmed after 5 failed login attempts.
- No plaintext OAuth credentials in application config or environment variables (all from Key Vault).

#### Stakeholders

- **Dallas (Lead & Architect):** Decision owner; identified passkey requirement as blocker for Azure AD B2C
- **Ripley (Backend):** Implements Identity schema, passkey integration, OAuth providers, and admin email check
- **Lambert (Frontend):** Implements login UI, passkey registration/authentication UI flows
- **Kane (Tester):** Tests passkey flows, lockout behaviour, admin identification, and OAuth provider integration

## Pros and Cons of the Options

### ASP.NET Core Identity with Fido2NetLib

- Good, because full native WebAuthn/FIDO2 passkey support — no workarounds or custom policies.
- Good, because no per-auth costs — Identity is in-process.
- Good, because admin identification is a simple email list check — no B2C custom attributes or group management.
- Good, because built-in OAuth middleware for Google, GitHub, Microsoft social login.
- Good, because full UI control — standard Blazor/Razor components, no external templates.
- Good, because .NET-native — shares domain models, DI container, and logging infrastructure.
- Neutral, because we own the security implementation, but ASP.NET Core Identity handles lockout, hashing, tokens natively.
- Bad, because no built-in enterprise SSO federation — can be added later if required.
- Bad, because passkey UX requires custom implementation beyond the default Identity scaffolding.

### Azure AD B2C

- Good, because fully managed identity service — Microsoft owns the security surface.
- Good, because enterprise SSO federation supported out of the box.
- Good, because scales to millions of users with Azure's global identity infrastructure.
- Neutral, because social login (Google, GitHub) is configurable but requires B2C custom policies.
- Bad, because passkey/WebAuthn support in B2C requires a custom policy (Identity Experience Framework) — complex, XML-based, difficult to maintain.
- Bad, because per-authentication pricing ($0.0016/auth for social accounts) adds cost at scale.
- Bad, because UI customisation requires B2C hosted page templates — restricted HTML/CSS, no Blazor components.
- Bad, because admin identification requires B2C custom attributes or group membership — adds complexity vs. a simple email list.
- Bad, because B2C custom policies are notoriously difficult to debug and maintain — high operational risk for a small team.

## More Information

Fido2NetLib documentation and samples: https://github.com/passwordless-lib/fido2-net-lib

WebAuthn/FIDO2 passkeys are a phishing-resistant authentication method that bind credentials to a specific origin, making them the most secure authentication option available for web applications. Making passkeys a first-class login option (not an add-on) was a key product requirement.

The admin email list in Key Vault can be updated without a deployment — the check occurs on every login. This satisfies the MVP requirement for admin account management without a full admin management UI.

## Follow-On Information

Post-MVP considerations:
- If enterprise customers require SSO federation (SAML/OIDC), add ASP.NET Core OpenID Connect middleware for external identity provider support.
- If admin management at scale requires a UI, build an admin management page backed by the existing ASP.NET Core Identity role management APIs.

## Record History

* **Proposed**: 2026-02-28
* **Accepted**: 2026-02-28
* **Last Reviewed**: 2026-02-28
