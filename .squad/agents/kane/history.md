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

**Brett Requirements Delivered:** Requirements breakdown now available at `.squad/requirements.md` — 6 epics, 15 features, 30+ user stories with Given/When/Then acceptance criteria. **Consult for test case derivation.** Acceptance criteria in Given/When/Then format; use directly to drive test design. 30+ stories provide comprehensive coverage matrix for unit and integration tests.

## Learnings

