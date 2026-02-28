# Lambert — Project Knowledge

## Project

**CFP Compass** — .NET 10 / C# web application aggregating open Calls for Papers for community speakers.

- **Stack:** .NET 10, C#, Azure Container Apps, Azure SQL / Cosmos DB, Azure Functions, Terraform, GitHub Actions, Azure AD B2C
- **Lead:** Chad Green
- **Team:** Dallas (Lead), Ripley (Backend), Lambert (Frontend), Parker (DevOps), Kane (Tester), Brett (Requirements)

## Core Context

- Public CFP listing: filterable, sortable, detail pages — must be fast and accessible
- Submission form for organizers; admin moderation UI for reviewing and approving submissions
- User account pages: registration, login, favorites list, notification preferences
- UI framework: Razor Pages or Blazor — TBD by Dallas; follow whatever is decided
- Clean, responsive, accessible design expected from Chad

## Latest Context (2026-02-28)

**Brett Requirements v2 Complete:** All 10 open questions resolved by Chad Green and integrated into `.squad/requirements.md`. Feature 1.4 (Past CFPs Archive) added. **Consult requirements.md v2 before frontend implementation.** Critical frontend change: UI must support i18n from day 1 — no hard-coded strings in components. All user-facing text must be translatable.

## Learnings
