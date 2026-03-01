# Copilot Instructions — CFPCompass

CFP Compass is a .NET 10, Azure-hosted web app that aggregates open Calls for Papers (CFPs) for community speakers. The full project description is in `ProjectDescription.md`. Architecture decisions, requirements, and team context live under `.squad/`.

## Build & Test

> The solution does not exist yet — this project is in the planning/design phase. Update this section once the solution is scaffolded.

Expected commands once the solution exists:

```bash
# Run from repo root
dotnet build CFPCompass.sln
dotnet test CFPCompass.sln

# Run a single test project
dotnet test tests/CFPCompass.Api.Tests/

# Run a single test by name
dotnet test tests/CFPCompass.Api.Tests/ --filter "FullyQualifiedName~YourTestName"

# Local dev (requires Aspire AppHost)
dotnet run --project apphost/CFPCompass.AppHost/
# Aspire Dashboard: https://localhost:18888
```

## Architecture Overview

### Solution Layout

```
src/
├── CFPCompass.Domain/         # Entities, Enums, ValueObjects, Domain Events — zero external NuGet deps
├── CFPCompass.Application/    # Interfaces, Services, DTOs, FluentValidation validators, AutoMapper profiles
├── CFPCompass.Infrastructure/ # EF Core, Repositories, ACS email, Blob Storage, Redis, Identity/passkeys
├── CFPCompass.Api/            # ASP.NET Core Web API — thin controllers, delegates to Application services
├── CFPCompass.Web/            # Blazor Server app — Components/Pages, Shared, Admin, Resources (.resx)
├── CFPCompass.Workers/        # Container Apps Jobs — CfpExpiryJob, DeadlineReminderJob, WeeklyDigestJob, etc.
└── CFPCompass.Functions/      # Azure Functions — Service Bus processors for async write operations
apphost/CFPCompass.AppHost/    # .NET Aspire 13.1 orchestrator — dev/test only, not deployed
servicedefaults/CFPCompass.ServiceDefaults/  # Shared OpenTelemetry, health checks, resilience, service discovery
tests/
├── CFPCompass.Domain.Tests/
├── CFPCompass.Application.Tests/
├── CFPCompass.Infrastructure.Tests/
├── CFPCompass.Api.Tests/      # WebApplicationFactory integration tests
├── CFPCompass.Web.Tests/      # xUnit + bUnit Blazor component tests
└── CFPCompass.E2E.Tests/      # Playwright end-to-end tests
infra/                         # Terraform IaC — modules/ + environments/dev|staging|prod/
```

### Dependency Rule (Clean Architecture / Onion)

```
Domain ← Application ← Infrastructure / Api / Web / Workers / Functions
```

- **Domain** — no NuGet packages except BCL
- **Application** — depends on Domain; defines interfaces (`ICfpService`, `IEmailService`, etc.) that Infrastructure implements
- **Api** and **Web** are thin entry points; delegate all logic to Application services
- **Workers** and **Functions** also depend only on Application, not Infrastructure directly
- Every service project calls `builder.AddServiceDefaults()` at startup (OpenTelemetry, health checks, resilience, service discovery)

### Event-Driven Write Pattern

POST/PUT write operations follow this flow:
1. API validates input → publishes event to **Azure Service Bus** (topic-per-aggregate)
2. API returns **HTTP 202 Accepted** with `Location: /api/v1/submissions/{id}/status`
3. **Azure Function** subscribes to the topic, processes the event, writes to Azure SQL
4. `CacheInvalidationProcessor` purges APIM response cache and Redis keys after successful write

GET operations use **APIM response caching** (5 min for listing, 1 min for detail, 60 min for reference data) to offset Azure SQL serverless cold-start.

### Key Azure Services

| Service | SKU | Role |
|---------|-----|------|
| Container Apps | Consumption | Web app (Blazor) + API (ASP.NET Core) |
| Container Apps Jobs | Consumption | Scheduled background workers |
| Azure SQL Database | Serverless GP | Primary relational store |
| Azure Managed Redis | C0 | Distributed cache + session state |
| Azure Service Bus | Standard | Event-driven write operations |
| Azure Functions | Consumption | Service Bus message processors |
| Azure API Management | Developer | Rate limiting, API keys, developer portal, response caching |
| Azure Front Door | Standard | CDN, SSL, routing |
| Azure Communication Services | PAYG | All transactional + digest email |
| Azure Key Vault | Standard | All secrets via Managed Identity |

> **Use Azure Managed Redis** (not the retired Azure Cache for Redis). APIM is Developer tier (not Consumption).

## Key Conventions

### Namespaces & Projects

- Pattern: `CFPCompass.{Layer}` and `CFPCompass.{Layer}.{Feature}`
- Examples: `CFPCompass.Application.Services`, `CFPCompass.Infrastructure.Data`
- Test projects: `CFPCompass.{Layer}.Tests`
- Terraform modules: lowercase kebab-case (`container-apps`, `key-vault`)

### API Design

- **Spec-first**: All REST endpoints require an approved OpenAPI 3.1 spec in `docs/api/openapi/cfp-compass-api-v1.yaml` before implementation. APIM imports the spec directly.
- All public endpoints under `/api/v1/` fronted by APIM
- Write endpoints (POST/PUT) return HTTP 202 with a `statusUrl` in the body
- Rate limits: 100 req/min (read), 10 req/min (write) per APIM subscription key
- Public API uses `Ocp-Apim-Subscription-Key` header; web app uses HttpOnly cookie sessions

### Authentication

- **ASP.NET Core Identity** (not Azure AD B2C) + `Fido2NetLib` for WebAuthn/FIDO2 passkeys
- Social login: Google, GitHub, Microsoft OAuth middleware
- Admin identity: email match against `CFPCOMPASS_ADMIN_EMAILS` env var (checked on every login)
- Submission edit and claim verification links use short-lived single-use JWTs embedded in emails

### Data Access (EF Core)

- Repository pattern wrapping `DbContext` for testability
- Specification pattern for complex CFP filter queries
- Global query filters for soft-delete/archive (`IsArchived`)
- Enums stored as strings via value converters
- `CreatedAt`/`UpdatedAt` auto-stamped via interceptors
- Category/Topic are **many-to-many** via junction tables (`CfpListingCategory`, `CfpTopic`) — filter queries use `EXISTS`/`JOIN`, not simple equality
- Reference data (countries, topics) seeded via `HasData()` in migrations; ISO 3166-1/3166-2, IANA Time Zones, UN M.49 region codes are validated server-side

### Frontend (Blazor Server)

- No JavaScript framework — Blazor handles all interactivity; minimal JS interop for WebAuthn passkeys only
- CSS: Bootstrap 5
- Every user-facing string goes through `IStringLocalizer<T>` — no string literals in Razor/Blazor markup
- `Resources/Pages/*.en.resx` and `Resources/Shared/*.en.resx` for localization strings
- Reusable components: `CfpCard`, `FilterPanel`, `CountryPicker`, `SubdivisionPicker`, `TimeZonePicker`, `TrackingButtons`

### Email

- `IEmailService` interface in Application; `AcsEmailService` in Infrastructure wraps `Azure.Communication.Email` SDK
- Email templates: Razor-based (`.cshtml`) in `CFPCompass.Infrastructure/Email/Templates/`
- Every email includes an unsubscribe link with signed JWT; includes `List-Unsubscribe` header

### Bot Protection

Submission form uses **Cloudflare Turnstile (invisible) + hidden honeypot field** (ADR-012). Server-side validation verifies the Turnstile token via Cloudflare API before accepting CFP data.

### Health Checks

- All services expose `GET /health`; Functions exposes `GET /api/health`
- ACS is treated as `Degraded` (not `Unhealthy`) to avoid false alarms
- JSON response: `{ "status": "Healthy|Degraded|Unhealthy", "components": { ... } }`
- `Degraded` returns HTTP 200; `Unhealthy` returns HTTP 503

### Terraform

- Remote state in Azure Storage (separate account from app); state locking via blob lease
- Module per Azure service under `infra/modules/`
- Environment-specific overrides in `infra/environments/dev|staging|prod/`
- `azurerm` + `azapi` providers

---

## Squad Workflow

This project uses **Squad v0.5.3** — an AI team framework. The coordinator agent lives at `.github/agents/squad.agent.md`.

### Issue Routing
- Adding the `squad` label to a GitHub issue triggers the Lead to triage it.
- The Lead assigns a `squad:{member}` or `squad:copilot` label based on the capability profile in `.squad/team.md`.
- When `squad:copilot` is assigned and auto-assign is enabled, Copilot picks up the issue autonomously.

### Branch Naming
```
squad/{issue-number}-{kebab-case-slug}
```

### Pull Requests
- Reference the issue: `Closes #{issue-number}`
- If the issue had a `squad:{member}` label, note: `Working as {member} ({role})`
- If it's a 🟡 needs-review task, add: `⚠️ Needs squad member review before merging`

### Decisions
Write decisions that affect other team members to:
```
.squad/decisions/inbox/copilot-{brief-slug}.md
```
The Scribe merges these into the shared decisions file.

### Key `.squad/` Files

- `.squad/team.md` — Team roster and Copilot capability profile. The `## Members` header is hardcoded in workflows — do not rename it.
- `.squad/architecture.md` — Full system architecture, ADRs, data model, API spec
- `.squad/decisions.md` — Shared team decisions (maintained by Scribe)
- `.squad/requirements.md` — Feature requirements with Given/When/Then acceptance criteria
- `.squad/routing.md` — Work routing rules by domain keyword

### File Ownership

| Path | Owner | Notes |
|------|-------|-------|
| `.squad/` | User | Never overwrite during init |
| `.squad-templates/` | Squad | Overwritten on upgrade |
| `.github/agents/squad.agent.md` | Squad | Overwritten on upgrade |

### Git Merge Strategy

`.gitattributes` sets union merge on Squad state files:
```
.squad/decisions.md merge=union
.squad/agents/*/history.md merge=union
```

### Squad Ceremonies

- **Design Review** — runs automatically before multi-agent tasks touching 2+ shared systems
- **Retrospective** — runs automatically after build failure, test failure, or reviewer rejection
