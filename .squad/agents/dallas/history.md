# Dallas — Project Knowledge

## Project

**CFP Compass** — .NET 10 / C# web application aggregating open Calls for Papers for community speakers.

- **Stack:** .NET 10, C#, Azure Container Apps, Azure SQL / Cosmos DB, Azure Functions, Terraform, GitHub Actions, Azure AD B2C
- **Lead:** Chad Green
- **Team:** Dallas (Lead), Ripley (Backend), Lambert (Frontend), Parker (DevOps), Kane (Tester), Brett (Requirements)

## Core Context

- Public listing of open CFPs: filtering, sorting, detail pages
- Organizer submission workflow with admin moderation — no auto-publish
- User accounts: favorites, deadline reminder preferences
- Email notifications: deadline reminders + weekly digest (new and closing CFPs)
- Public REST API: authenticated, GET/POST/PUT for CFPs, submissions, and metadata
- IaC via Terraform; CI/CD via GitHub Actions; hosted on Azure Container Apps
- Clean, cloud-native architecture with clear separation of concerns

## Latest Context (2026-02-28)

**Brett Requirements v1 Delivered:** Requirements breakdown initially available at `.squad/requirements.md` — 6 epics, 15 features, 30+ user stories with Given/When/Then acceptance criteria. Included 10 flagged open questions requiring team decision.

**Brett Requirements v2 Complete:** All 10 open questions resolved by Chad Green and integrated. Feature 1.4 (Past CFPs Archive) added. **Consult requirements.md v2 before implementation.** Critical architectural change: i18n support must be built in from day 1 — no hard-coded strings in any tier.

## Learnings

### Architecture v1 Decisions (2026-02-28)

**Database:** Azure SQL Database (Serverless) over Cosmos DB — relational model is the right fit for FK-heavy domain (CFPs ↔ users ↔ tracking ↔ moderation). Cosmos overkill for MVP scale.

**Frontend:** Blazor Server (interactive SSR) over Razor Pages and Blazor WASM — rich interactivity without JS, SSR for SEO, direct service access. Risk: SignalR connection dependency; mitigated by Container Apps WebSocket support.

**Auth:** ASP.NET Core Identity (self-hosted) over Azure AD B2C — passkey support via `Fido2NetLib` is simpler and cheaper than B2C custom policies. Social login via built-in OAuth middleware (Google, GitHub, Microsoft). Admin identity via env config email list.

**Workers:** Azure Container Apps Jobs over Azure Functions — keeps deployment topology uniform (everything is containers). No Function-specific abstractions. Must implement our own retry logic (Polly).

**Caching:** Redis (Basic C0) for distributed cache + IMemoryCache for reference data. Output caching for public listing pages with tag-based invalidation.

**API Gateway:** APIM Consumption tier — pay-per-call, built-in rate limiting and developer portal. Cold start risk (~1-2s) mitigated by Front Door health probes.

**Architecture pattern:** Clean Architecture (Onion) — Domain → Application → Infrastructure/Api/Web/Workers.

**Key libraries:** EF Core 10 (data access), FluentValidation (input validation), Fido2NetLib (passkeys), Serilog (structured logging), NSubstitute + FluentAssertions (testing), HtmlSanitizer (XSS protection), RazorLight (email templates).

**Open questions flagged for Chad:** (1) Production domain name, (2) Bot protection mechanism (reCAPTCHA vs Turnstile vs honeypot), (3) Initial category/topic taxonomy seeding, (4) Email sender identity/domain.

**Risks identified:** Blazor Server SignalR dependency, APIM Consumption cold start, Redis Basic tier has no SLA, no VNet in MVP (Consumption APIM limitation), serverless SQL cold start (~10s).

