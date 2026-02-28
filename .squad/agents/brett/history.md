# Brett — Project Knowledge

## Project

**CFP Compass** — .NET 10 / C# web application aggregating open Calls for Papers for community speakers.

- **Stack:** .NET 10, C#, Azure Container Apps, Azure SQL / Cosmos DB, Azure Functions, Terraform, GitHub Actions, Azure AD B2C
- **Lead:** Chad Green
- **Team:** Dallas (Lead), Ripley (Backend), Lambert (Frontend), Parker (DevOps), Kane (Tester), Brett (Requirements)

## Core Context

### Personas
- **Speaker** — browses CFPs, filters by topic/date, favorites them, gets deadline reminders
- **Organizer** — submits a new CFP via public form; waits for admin approval
- **Admin** — reviews submitted CFPs, approves or rejects them; approved entries go live
- **API Consumer** — authorized third party reading/writing CFP data via the public REST API

### Core Features
- Public CFP listing with filtering, sorting, and detail pages
- Organizer submission form (no account required, or account required — TBD)
- Admin moderation workflow (approve / reject with optional feedback)
- User accounts: favorites, deadline reminder preferences
- Email: deadline reminders + weekly digest (new + closing CFPs)
- Public REST API: authenticated, versioned, GET/POST/PUT

## Learnings
