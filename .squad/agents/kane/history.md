# Kane — Project Knowledge

## Project

**CFP Compass** — .NET 10 / C# web application aggregating open Calls for Papers for community speakers.

- **Stack:** .NET 10, C#, Azure Container Apps, Azure SQL / Cosmos DB, Azure Functions, Terraform, GitHub Actions, Azure AD B2C
- **Lead:** Chad Green
- **Team:** Dallas (Lead), Ripley (Backend), Lambert (Frontend), Parker (DevOps), Kane (Tester), Brett (Requirements)

## Core Context

- Testing framework: xUnit (standard for .NET 10)
- Key test areas: CFP submission workflow, admin moderation logic, user auth flows, API endpoint contracts, email trigger conditions, deadline reminder logic
- Integration tests: use WebApplicationFactory or TestContainers for SQL/Cosmos DB
- Edge cases to keep in mind: duplicate CFPs, expired submissions, invalid deadlines, unauthorized API access, email delivery failures
- CI integration: tests run in GitHub Actions pipeline (Parker owns the pipeline config)

## Latest Context (2026-02-28)

**Brett Requirements v1 Delivered:** Requirements breakdown initially available at `.squad/requirements.md` — 6 epics, 15 features, 30+ user stories with Given/When/Then acceptance criteria. Acceptance criteria in Given/When/Then format; use directly to drive test design.

**Brett Requirements v2 Complete:** All 10 open questions resolved by Chad Green and integrated. Feature 1.4 (Past CFPs Archive) added. **Consult requirements.md v2 for comprehensive test case derivation.** Critical test focus: i18n must be testable from day 1 — test cases must verify proper localization of all UI strings and API response strings across multiple languages/regions.

## Learnings

