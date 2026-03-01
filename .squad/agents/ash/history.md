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
