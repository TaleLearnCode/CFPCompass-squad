# Ash — History

## Project Context

- **Project:** CFP Compass — a .NET 10 / C# Azure-hosted web app aggregating open Calls for Papers for community speakers
- **Stack:** .NET 10, C#, Blazor Server, Azure Container Apps, Azure SQL (Serverless), Azure Managed Redis, Azure Service Bus, Azure Functions, Azure Communication Services, Azure API Management (Developer tier), .NET Aspire 13.1, Terraform, GitHub Actions
- **Lead:** Chad Green
- **Team:** Dallas (Lead/Architect), Ripley (Backend), Lambert (Frontend), Parker (DevOps), Kane (Tester), Brett (Requirements Analyst), Ash (Technical Writer)

## Key Files

- `.squad/requirements.md` — Requirements v3.5 (6 epics + 3 NFRs). Source of truth for what we're building.
- `.squad/architecture.md` — Architecture v4.0 (16 sections, 14 ADRs). Source of truth for how we're building it.
- `docs/api/openapi/` — OpenAPI 3.1 spec location (pending creation)
- `docs/api/asyncapi/` — AsyncAPI 3.0.0 spec location (pending creation)

## Key Decisions

- APIs are contract-first: OpenAPI 3.1 spec must be approved before implementation (ADR-014)
- Service Bus events require AsyncAPI 3.0.0 specs before implementation (ADR-014)
- 6 known Service Bus topics need AsyncAPI specs: cfp-submission-created, cfp-submission-updated, cfp-submission-approved, cfp-submission-rejected, cfp-submission-reconsideration, organizer-claim-requested
- APIM imports OpenAPI spec directly — spec is both documentation and gateway config
- English-only MVP with i18n built in from day one
- Health check endpoints on all services; JSON response contract documented in architecture.md §10

## Learnings

- Joined team at architecture v4.0 / requirements v3.5

- Updated 14 documentation files (274 route references) to reflect ADR-015 route prefix change: /api/v1/ → /v1/. Preserved Azure Functions /api/health endpoints unchanged per Functions host runtime conventions. Used PowerShell bulk replacements for efficiency across large files.

## Work — ADR-015 Documentation Update (2026-03-01)

**Scope:** Bulk documentation update for route prefix removal (ADR-015: `/api/v1/` → `/v1/`)

**Files modified:** 14 documentation files across 3 categories:
- **API Contract docs** (docs/contracts/apis/): cfps.md (27), submissions.md (38), account.md (29), metadata.md (20), claims.md (18), admin.md (24), README.md (40) = 196 replacements
- **Architecture docs** (docs/architecture/): architecture-specifications.md (8), system-context-and-logical-components.md (14) = 22 replacements
- **Process Flow docs** (docs/process-flows/): cfp-submission.md (15), cfp-moderation.md (12), api-write-pattern.md (14), organizer-claim.md (14) = 55 replacements
- **Architecture guide:** docs/architecture-guide.md (1 replacement)

**Total:** 276 route references updated

**Validation:** No `/api/health` endpoints modified (Azure Functions host convention exception per ADR-015). No HttpTrigger route examples altered. Frontmatter metadata preserved across all files.

**Cross-agent awareness:** Ash aware of ADR-015 decision (Dallas decision) and implemented it in full scope per specification. Dallas (Agent 11) aware of Ash's documentation work; noted completion in orchestration batch.

**Next:** Implementation teams will refactor controllers and APIM routes per ADR-015 decision.

