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

### Architecture v2 Revisions (2026-03-01)

**Redis:** Switched from Azure Cache for Redis (retiring Sep 2028) to **Azure Managed Redis** (C0). Documented containerized Redis as fallback option if managed pricing is unacceptable at scale.

**APIM:** Switched from Consumption to **Developer tier**. Gains: no cold start, VNet integration, dedicated capacity, built-in developer portal. Upgrade path: Developer → Standard V2 (not Premium). Developer tier is not HA — no zone redundancy, 99.9% SLA only.

**Event-driven write pattern:** POST/PUT operations now publish to **Azure Service Bus** (Standard tier, topic-per-aggregate). API returns **202 Accepted** with `Location` header for status polling. **Azure Functions** (Consumption plan) subscribe to topics and process writes asynchronously. Decouples API from Azure SQL cold starts.

**APIM read caching:** Response caching on public GET endpoints — 5-min TTL for listings, 1-min for detail. Cache invalidation triggered by Service Bus events after successful writes.

**Resolved open questions:** (1) Domain: `cfpcompass.com`, (2) Bot protection: still pending Chad's review, (3) Taxonomy: 10 Primary Domains + 10 Secondary Tag groups seeded in migration, admin-extensible, multi-select, (4) Email sender: `noreply@cfpcompass.com`.

**Multi-select taxonomy data model:** Category and Topic are now many-to-many via junction tables (`CfpListingCategory`, `CfpTopic`). Filter queries require EXISTS/JOIN. Both fields multi-select on submission form.

### Bot Protection Analysis (2025-03-01)

**Comprehensive comparison document delivered:** Analyzed three bot protection options for CFP submission form — reCAPTCHA v3 (Google), Cloudflare Turnstile, and Honeypot fields. Document covers technical integration for .NET 10 / Blazor Server, privacy/GDPR implications, cost projections, risk assessment, and hybrid approaches. Written to session files: `C:\Users\chadg\.copilot\session-state\112b81f4-76e5-4d47-8515-e0c60a20b566\files\bot-protection-comparison.md`.

**Recommendation:** **Cloudflare Turnstile + Honeypot (Hybrid 1)** — Layered defense with zero cost, GDPR-compliant, privacy-first (critical for international tech community audience), effective against simple and sophisticated bots. Weighted decision matrix score: 4.70/5.00. Honeypot catches 80%+ of low-effort spam instantly (no API latency). Turnstile catches remaining 20% (headless browsers, sophisticated scripts). Implementation: 8 hours total. Fallback if Turnstile alone preferred: 4-6 hours (honeypot can be added later if spam increases).

**Why not reCAPTCHA v3:** Google tracking creates GDPR liability (requires Enterprise tier at $5-10/mo + DPA + consent banner + legal review). Reputational risk with privacy-aware developer audience. Turnstile delivers equivalent effectiveness without privacy tradeoff.

**Decision pending:** Chad Green final approval. Open question #2 (Bot protection strategy) resolved pending Chad's review of analysis.

### Bot Protection Decision Finalized (2026-02-28)

**Chad Green approved:** Cloudflare Turnstile + Honeypot as selected bot protection strategy.

**Implementation details locked:**
- Turnstile: Invisible challenge widget on CFP submission form; free tier, GDPR-compliant (no Google tracking)
- Honeypot: Hidden form field (CSS hidden, not type=hidden); server-side validation before processing
- Server validation: Submission API verifies Turnstile token via Cloudflare API; rejects filled honeypot fields
- No cost impact; Cloudflare as separate dependency from CDN choice
- Zero false positives for VPN/proxy users (unlike reCAPTCHA v3)
- Layered defense: Honeypot catches 80%+ low-effort spam instantly; Turnstile catches sophisticated bots

**ADR-012 created** documenting decision rationale, integration approach, and consequences.

**Open question Q2 fully resolved.** No blockers remain for submission form implementation (Lambert) or API submission endpoint (Ripley).

### Architecture Open Questions — All Resolved (2026-02-28)

Chad Green confirmed Cloudflare Turnstile + Honeypot as the bot protection strategy, closing Q2. All four architecture open questions are now resolved:

- Q1 ✅ Domain: `cfpcompass.com`
- Q2 ✅ Bot protection: Cloudflare Turnstile + Honeypot (ADR-012)
- Q3 ✅ Taxonomy: 10 Primary Domains + 10 Secondary Tag groups, admin-extensible
- Q4 ✅ Email sender: `noreply@cfpcompass.com`

`architecture.md` updated: Q2 section replaced with full resolution detail; ADR-012 in Section 12; `Turnstile-SiteKey` and `Turnstile-SecretKey` added to Key Vault secrets table (Section 9). No open architectural questions remain.

### .NET Aspire 13.1 Adoption (2026-03-01)

**ADR-013 created:** .NET Aspire 13.1 adopted for local development orchestration and observability baseline. Chad Green directive.

**Solution structure:** Expanded from 7 to 9 projects with the addition of:
- `CfpCompass.AppHost` — Aspire orchestrator declaring full service topology (Api, Web, Workers, Functions, SQL, Redis, Service Bus). Dev/test only; NOT deployed to production.
- `CfpCompass.ServiceDefaults` — Shared `AddServiceDefaults()` extension consumed by all service projects. Configures OpenTelemetry (traces, metrics, logs), health check endpoints (`/health`, `/alive`), resilience defaults (Polly), and service discovery.

**Key patterns:**
- All service projects (Api, Web, Workers, Functions) call `builder.AddServiceDefaults()` at startup — enforced via PR review
- AppHost provides single-command local startup: `dotnet run --project CfpCompass.AppHost`
- Aspire Dashboard at `https://localhost:18888` for distributed tracing and log correlation during development
- Aspire integration packages (`Aspire.Azure.*`) replace manual SDK configuration for Redis, Service Bus, and SQL — handle connection string injection, health checks, and telemetry automatically
- Production: OpenTelemetry exports to Azure Monitor / Application Insights (config-only switch from Aspire Dashboard)
- AppHost excluded from CI/CD deployment pipeline and production Docker builds — dev tooling only
- Production hosting remains Azure Container Apps + Terraform (unchanged)

**Architecture.md changes:**
- Version bumped to v3.0
- Section 2 (Solution Structure): 9-project layout with AppHost and ServiceDefaults
- Section 10 (Observability): New — OpenTelemetry, Aspire Dashboard, Azure Monitor, health checks, distributed tracing
- Section 11 (Local Development): New — single-command startup, service table, prerequisites
- Sections 10-13 renumbered to 12-15
- ADR-013 added to Section 14
- Aspire integration packages noted in data/caching section (Section 3)
- Container Registry note: AppHost/ServiceDefaults excluded from Docker images

