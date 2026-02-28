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

### 2026-02-28 — Initial Requirements Breakdown

**Task:** Created comprehensive requirements breakdown from ProjectDescription.md covering 6 epics, 15 features, and 30+ user stories.

**Key Decisions:**
- Structured requirements with personas first to establish user context for all stories
- Used Given/When/Then format for all acceptance criteria to ensure testability
- Organized epics by user-facing capability area (Discovery, Submission, Accounts, Notifications, API, Admin)
- Prioritized clarity over cleverness — plain language, no jargon, no assumptions about tech stack in requirements

**Patterns Applied:**
- Each feature has 1-3 user stories — granular enough for a sprint, but not micro-tasks
- All user stories include role, goal, benefit statement ("As a/I want to/So that")
- Acceptance criteria focus on observable behavior, not implementation details
- Separated "happy path" stories from validation/error handling stories for clarity

**Open Questions Identified:**
- 10 critical ambiguities flagged for Chad/Dallas decision (account requirements, expiration policy, rate limits, admin role assignment, email provider, date schema, API versioning, duplicate detection, notification granularity, i18n)
- Recommended defaults provided for each to unblock team if decisions delayed

**Context for Future Work:**
- `.squad/requirements.md` is now the single source of truth for what "done" looks like
- Ripley, Lambert, Parker, Kane should reference this before starting any feature work
- Requirements are testable — Kane can derive test cases directly from ACs
- Open questions should be resolved in `.squad/decisions.md` by Chad or Dallas before affected features begin development
