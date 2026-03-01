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

### Infrastructure Decisions Finalized (2026-03-01)

**App Configuration:** Initial recommendation rejected, then **REVISED and ADOPTED** after Chad Green's challenge. Azure App Configuration now serves as central configuration surface with feature flag support for trunk-based development. Environment labeling strategy (dev/staging/prod) replaces per-environment Terraform duplication. Key Vault references surface secrets through unified App Configuration SDK. Decision reversed because: (1) Feature flags are essential for trunk-based dev (not speculative), (2) Central config is operational hygiene not luxury, (3) Single retrieval pattern via App Configuration Key Vault references eliminates dual-path complexity, (4) Environment labeling cleaner than Terraform variable duplication. Risk assessment: LOW across outage/cost/dependency/bootstrap concerns. New action items: Parker creates `infra/modules/appconfig/` Terraform module; Ripley adds `AddAzureAppConfiguration()` to ServiceDefaults; Parker migrates env vars and creates Key Vault references; Dallas defines initial feature flag set.

**Route Prefix Removal (ADR-015):** Decision approved to remove `/api/` prefix from all ASP.NET Core API routes. Routes become `/v1/cfps`, `/v1/topics`, etc. Rationale: `/api/` disambiguation unnecessary in dedicated container with no page routes; APIM sole public ingress; OpenAPI spec imports directly to APIM. Exception: Azure Functions `HealthCheckFunction` keeps `GET /api/health` (Functions host runtime convention). Timing critical: decision made before controller/spec/policy implementation to minimize disruptive renames. Delegated to Ash for 14-file documentation update (276 route replacements) and to implementation team for code refactoring.

**Managed Identity Gaps Identified:** Three credential management inconsistencies flagged for implementation: (1) Gap 1 - SQL: Web + API use Key Vault secrets instead of Managed Identity like Jobs/Functions (HIGH priority), (2) Gap 2 - Blob Storage: SAS tokens require rotation and leak-prone, should use MI RBAC (MEDIUM), (3) Gap 3 - ACS: Connection string in Key Vault, should use ManagedIdentityCredential (LOW). One accepted exception: Redis stays on access key auth (StackExchange.Redis Entra support incomplete). Delegated to Parker for GitHub issue creation and Terraform implementation roadmap.

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

### Health Check Architecture Finalized (2026-03-01)

**Chad Green directive:** Health check endpoints must verify both liveness and dependency connectivity across all services.

**Decisions recorded in architecture.md §10 (v3.1):**

- **Per-service responsibilities** documented: Api checks SQL + Redis + Service Bus + ACS (degraded); Web checks API reachability only; Workers checks SQL + Service Bus + Redis; Functions checks SQL + Service Bus via `HealthCheckFunction`.
- **ACS degraded policy:** Azure Communication Services treated as `Degraded` (not `Unhealthy`) — ACS outage must not mark the API Unhealthy or trigger container restarts. API can still serve reads and queue writes.
- **JSON response contract** standardized: `{ status, components: { sql, redis, serviceBus, acs, api } }` with `duration_ms` per component. `200 OK` for Healthy/Degraded; `503 Service Unavailable` for Unhealthy.
- **Container Apps probe mapping:** Startup probe (cold-start grace), liveness probe (503 → restart), and readiness probe (non-200 → remove from load balancer) all target `GET /health`. Healthy and Degraded both return 200 so degraded instances stay in rotation.
- **Functions pattern:** `HealthCheckFunction` is an `HttpTrigger` at route `health` (`GET /api/health`) — bypasses ASP.NET Core middleware pipeline which Functions does not expose in the same way. Same JSON contract as other services. Container Apps probes `/api/health` for the Functions container.
- **Aspire ServiceDefaults note:** `AddServiceDefaults()` auto-registers `/health` for ASP.NET Core projects (Api, Web, Workers); Functions uses manual `HealthCheckFunction` instead.
- **No new ADR** — this is an elaboration of the existing health check commitment in ADR-013 and NFR-1.

### Contract-First API & Event Design (2026-03-01)

**Chad Green directive:** APIs and events are design-driven. No REST endpoint or Service Bus topic may be implemented without an approved specification.

**ADR-014 created** — Contract-First API and Event Design:

- **OpenAPI 3.1** required for all REST endpoints in `CfpCompass.Api` before implementation. Spec files: `docs/api/openapi/` (canonical: `cfp-compass-api-v1.yaml`). APIM imports the spec directly.
- **AsyncAPI 3.0.0** required for all Azure Service Bus topics before producer or consumer implementation. Spec files: `docs/api/asyncapi/`.
- **Approval gate:** Spec PR merged → implementation PR opened. No exceptions.
- **Known topics requiring AsyncAPI specs:** `cfp-submission-created`, `cfp-submission-updated`, `cfp-submission-approved`, `cfp-submission-rejected`, `cfp-submission-reconsideration`, `organizer-claim-requested`
- **CI validation:** Spectral (`spectral:oas`) for OpenAPI specs; AsyncAPI CLI (`asyncapi validate`) for AsyncAPI specs — both run on every PR touching `docs/api/`.
- **Tooling:** Spectral (OpenAPI linting), AsyncAPI CLI (validation), oasdiff (breaking-change detection), Scalar/Swashbuckle (developer serving — not canonical), AsyncAPI Studio (authoring).
- **Architecture.md:** v4.0 — new Section 11 (API & Event Contract Design); ADR-014 in Section 15; spec-first note added to Section 4 (API Design); sections 11–15 renumbered to 12–16.

### Arch Review: Config, Identity, Routes (2026-03-02)

**Chad Green reviewed /docs and raised three architectural questions. All three resolved:**

**Azure App Configuration — Rejected for MVP:**
Do not add Azure App Configuration. Container Apps environment variables + Key Vault references (via managed identity) are sufficient. App Configuration is justified only if dynamic feature flags without redeployment become a requirement. The rule: sensitive values → KV, non-sensitive values → Container Apps env vars managed by Terraform. Add the no-App-Config guardrail to `non-goals-and-guardrails.md`.

**Managed Identities — Mostly in place, three gaps to close:**
MI is correctly wired for Key Vault, Service Bus, and ACR pull across all services. Jobs + Functions already use MI for Azure SQL (Entra token auth). Three gaps documented:
1. **Gap 1 (HIGH):** Web + API Container Apps connect to Azure SQL via connection string from Key Vault — should use MI (Entra token auth) for consistency with Jobs/Functions. Fix: add `db_datareader/db_datawriter` RBAC grants; switch to `DefaultAzureCredential` in EF Core SQL provider.
2. **Gap 2 (MEDIUM):** Blob Storage uses SAS tokens — should use `Storage Blob Data Contributor` RBAC + MI via `DefaultAzureCredential`.
3. **Gap 3 (LOW):** ACS uses connection string — ACS SDK supports `ManagedIdentityCredential`; switch and remove `ACS-ConnectionString` from Key Vault.
Accepted exception: Redis keeps access key from Key Vault — StackExchange.Redis Entra auth support is immature; revisit when the client library matures.

**`/api/` route prefix — Removed:**
Decision: drop `/api/` prefix from all ASP.NET Core API routes. Rationale: the prefix has no purpose when the API is a dedicated container with no page routes, and when the Container App has no public ingress (APIM is the sole entry point). Cleaner consumer-facing URLs. Routes become `/v1/cfps`, `/v1/topics`, etc. Update: route attributes in all API controllers, the canonical OpenAPI spec (`cfp-compass-api-v1.yaml`), and architecture.md route tables. Exception: Azure Functions `HealthCheckFunction` stays at `/api/health` — that's a Functions host runtime convention, not an application route. ADR-015 should be created to document this decision formally.

### Azure App Configuration Adopted — Previous Rejection Reversed (2026-03-02)

**Chad Green challenged the original "no App Configuration" recommendation.** After reviewing four counter-arguments, the previous rejection is reversed. Azure App Configuration is now an adopted, provisioned resource.

**Revised position:**
- **App Configuration** is the central configuration surface for all services. Non-sensitive config values (log levels, APIM URLs, job schedules), feature flags, and Key Vault references all live in App Configuration.
- **Key Vault** stores secrets. Secrets are surfaced through App Configuration Key Vault references — one retrieval pattern in code for all config.
- **Environment labeling:** `dev`, `staging`, `prod` labels on App Configuration keys. One service, multiple environments, no Terraform duplication per config value.
- **Feature flags** support trunk-based development — the team's branching model requires flags to safely ship incremental changes on `main`.
- **Container Apps env vars** reduced to bootstrap-only: the App Configuration endpoint itself.

**Why the reversal:** The original position undervalued (1) feature flags as essential for trunk-based development, (2) centralized config management as operational hygiene, (3) the single retrieval pattern that Key Vault references enable, and (4) label-based multi-environment management. Chad's counter-arguments were correct on all four points.

**Decision file:** `.squad/decisions/inbox/dallas-app-config-revised.md`
**Docs updated:** `docs/infrastructure/overview.md` — App Config added to owned resources, network diagram, and cost estimate.

**Learning:** Don't dismiss infrastructure services as "speculative" without fully evaluating how the team's development workflow (trunk-based dev, multi-environment management) creates real operational requirements. Feature flags aren't optional when your branching model depends on them.

### ADR-015 Created: Remove /api/ Route Prefix (2026-02-28)

**ADR-015 formally documents** the decision to remove the `/api/` prefix from all API routes. Previously captured informally in the arch review decision; now formalized as a proper ADR.

**Key points:**
- All routes use `/v1/` directly: `/v1/cfps`, `/v1/topics`, `/v1/categories`, etc.
- Exception: Azure Functions `HealthCheckFunction` stays at `GET /api/health` (Functions host runtime convention).
- Decision made before implementation — zero migration cost.
- APIM imports the OpenAPI spec directly; path changes propagate automatically.

**Files created:**
- `docs/registers/decisions/ADR-015-remove-api-route-prefix.md` — formal ADR
- `.squad/decisions/inbox/dallas-adr-015-route-prefix.md` — decision inbox file


