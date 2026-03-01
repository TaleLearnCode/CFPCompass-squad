# Dallas — Project Knowledge

## Project

**CFP Compass** — .NET 10 / C# web application aggregating open Calls for Papers for community speakers.

- **Stack:** .NET 10, C#, Azure Container Apps, Azure SQL / Cosmos DB, Azure Functions, Terraform, GitHub Actions, Azure AD B2C
- **Lead:** Chad Green
- **Team:** Dallas (Lead), Ripley (Backend), Lambert (Frontend), Parker (DevOps), Kane (Tester), Brett (Requirements)

## Core Context

**Architecture Summary:** Azure SQL Database (Serverless), Blazor Server, ASP.NET Core Identity + Fido2NetLib passkeys, Container Apps Jobs, Azure Managed Redis (C0), APIM Developer tier, event-driven write pattern (Service Bus + Azure Functions), Cloudflare Turnstile + Honeypot bot protection, .NET Aspire 13.1 for local development, OpenTelemetry-based observability, contract-first API/event design (OpenAPI 3.1 + AsyncAPI 3.0.0), health check patterns across all services. **Key decisions:** 4 open questions all resolved (domain, bot protection, taxonomy, email sender). **Requirements:** v2 complete; i18n required from day 1. **Infrastructure:** Terraform IaC; GitHub Actions CI/CD; Container Apps hosting; multi-environment support (dev/staging/prod).

## Decisions Made (2026-02-28 through 2026-03-01)

### Infrastructure Decisions Finalized (2026-03-01)

**App Configuration:** Initial recommendation rejected, then **REVISED and ADOPTED** after Chad Green's challenge. Azure App Configuration now serves as central configuration surface with feature flag support for trunk-based development. Environment labeling strategy (dev/staging/prod) replaces per-environment Terraform duplication. Key Vault references surface secrets through unified App Configuration SDK. Decision reversed because: (1) Feature flags are essential for trunk-based dev (not speculative), (2) Central config is operational hygiene not luxury, (3) Single retrieval pattern via App Configuration Key Vault references eliminates dual-path complexity, (4) Environment labeling cleaner than Terraform variable duplication. Risk assessment: LOW across outage/cost/dependency/bootstrap concerns. New action items: Parker creates `infra/modules/appconfig/` Terraform module; Ripley adds `AddAzureAppConfiguration()` to ServiceDefaults; Parker migrates env vars and creates Key Vault references; Dallas defines initial feature flag set.

**Route Prefix Removal (ADR-015):** Decision approved to remove `/api/` prefix from all ASP.NET Core API routes. Routes become `/v1/cfps`, `/v1/topics`, etc. Rationale: `/api/` disambiguation unnecessary in dedicated container with no page routes; APIM sole public ingress; OpenAPI spec imports directly to APIM. Exception: Azure Functions `HealthCheckFunction` keeps `GET /api/health` (Functions host runtime convention). Timing critical: decision made before controller/spec/policy implementation to minimize disruptive renames. Delegated to Ash for 14-file documentation update (276 route replacements) and to implementation team for code refactoring.

**Managed Identity Gaps Identified:** Three credential management inconsistencies flagged for implementation: (1) Gap 1 - SQL: Web + API use Key Vault secrets instead of Managed Identity like Jobs/Functions (HIGH priority), (2) Gap 2 - Blob Storage: SAS tokens require rotation and leak-prone, should use MI RBAC (MEDIUM), (3) Gap 3 - ACS: Connection string in Key Vault, should use ManagedIdentityCredential (LOW). One accepted exception: Redis stays on access key auth (StackExchange.Redis Entra support incomplete). Delegated to Parker for GitHub issue creation and Terraform implementation roadmap.

### Bot Protection Decision Finalized (2026-02-28)

**Chad Green approved:** Cloudflare Turnstile + Honeypot as selected bot protection strategy (ADR-012). Implementation details: Turnstile invisible widget on form (free tier, GDPR-compliant); Honeypot hidden field; server-side validation; no cost impact. Honeypot catches 80%+ low-effort spam instantly; Turnstile catches sophisticated bots. Zero false positives for VPN/proxy users.

### Architecture Open Questions — All Resolved (2026-02-28)

Chad Green confirmed all four architecture open questions resolved:
- Q1 ✅ Domain: `cfpcompass.com`
- Q2 ✅ Bot protection: Cloudflare Turnstile + Honeypot (ADR-012)
- Q3 ✅ Taxonomy: 10 Primary Domains + 10 Secondary Tag groups, admin-extensible
- Q4 ✅ Email sender: `noreply@cfpcompass.com`

### .NET Aspire 13.1 Adoption (2026-03-01)

ADR-013 created. Solution structure expanded from 7 to 9 projects: `CfpCompass.AppHost` (Aspire orchestrator; dev/test only) and `CfpCompass.ServiceDefaults` (shared `AddServiceDefaults()` extension). All service projects call `AddServiceDefaults()` at startup. AppHost provides single-command local startup: `dotnet run --project CfpCompass.AppHost`. Aspire Dashboard at `https://localhost:18888`. Aspire integration packages replace manual SDK configuration. OpenTelemetry exports to Azure Monitor/Application Insights in production. AppHost excluded from CI/CD and production Docker builds.

### Health Check Architecture Finalized (2026-03-01)

Per-service health check responsibilities documented: Api checks SQL + Redis + Service Bus + ACS (degraded); Web checks API reachability; Workers checks SQL + Service Bus + Redis; Functions checks SQL + Service Bus. ACS treated as Degraded (not Unhealthy). JSON response contract: `{ status, components: { sql, redis, serviceBus, acs, api }, duration_ms }`. Container Apps probes (startup/liveness/readiness) target `GET /health`. Functions uses `HealthCheckFunction` at `GET /api/health` (Functions host convention). `AddServiceDefaults()` auto-registers `/health` for ASP.NET Core services.

### Contract-First API & Event Design (2026-03-01)

ADR-014 created. APIs and events are design-driven: no REST endpoint or Service Bus topic implemented without approved specification. OpenAPI 3.1 required for REST endpoints in `CfpCompass.Api` (`docs/api/openapi/cfp-compass-api-v1.yaml`); APIM imports directly. AsyncAPI 3.0.0 required for Service Bus topics (`docs/api/asyncapi/`). Approval gate: spec PR merged → implementation PR opened. Known topics: `cfp-submission-created`, `cfp-submission-updated`, `cfp-submission-approved`, `cfp-submission-rejected`, `cfp-submission-reconsideration`, `organizer-claim-requested`.

### Bot Protection Decision Finalized (2026-02-28)
(Summarized in prior section)
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


