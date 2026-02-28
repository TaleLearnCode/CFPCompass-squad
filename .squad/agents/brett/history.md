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

### 2026-02-28 — Requirements v2: Resolved Decisions & Archive Feature

**Task:** Updated requirements.md with all 10 resolved decisions from Chad Green and added Feature 1.4 (Past CFPs Archive).

**Key Decisions Applied:**
- Organizer form is public, email-only — no account required (Decision 1)
- CFPs hidden 7 days post-deadline; archived to Past CFPs section (Decision 2)
- API rate limits: 100 read / 10 write req/min per key (Decision 3)
- Admin accounts via environment config (email list) for MVP (Decision 4)
- Email via Azure Communication Services (Decision 5)
- Event dates are optional startDate/endDate, null if TBD (Decision 6)
- API versioning via URL path `/api/v1/` (Decision 7)
- Duplicate detection: manual admin review, flag on exact URL match (Decision 8)
- Notification preferences: global toggle only for MVP (Decision 9)
- i18n architecture built in from day 1 — no hard-coded UI strings (Decision 10)

**New Feature Added:**
- Feature 1.4: Past CFPs Archive (2 user stories: 1.4.1 Browse archive, 1.4.2 View event CFP history)
- Epic 1 now has 4 features (1.1–1.4); total feature count raised to 16

**Stories Updated:**
- Feature 2.1 description: clarified no account required for organizers
- Features 4.1/4.2: added global toggle language to descriptions and opt-out ACs
- Feature 5.1 description: added rate limit spec (100/10 req/min)
- Features 5.2/5.3 descriptions: noted `/api/v1/` URL versioning

**Format Change:**
- "## Open Questions" section replaced with "## Resolved Decisions" using Decision N / Answer / Impact structure


### 2026-02-28 — Requirements v2: All Open Questions Resolved + Feature 1.4 Added

**Task:** Chad Green answered all 10 open questions. Updated requirements.md with resolved decisions, targeted AC updates, and new Feature 1.4.

**Resolved Decisions (summary):**
1. **Organizer account** — No account required; public form + email only. Story 2.1.1 updated.
2. **CFP expiration** — Hide 7 days after deadline; archive to Past CFPs section.
3. **API rate limits** — 100 req/min read, 10 req/min write per API key. Story 5.1.1 updated.
4. **Admin accounts** — Environment config (list of admin emails) for MVP; no admin management UI.
5. **Email provider** — Azure Communication Services (ACS).
6. **Event date schema** — Optional `startDate`/`endDate`; both nullable if TBD.
7. **API versioning** — URL path versioning: `/api/v1/`. Feature 5.3 description updated.
8. **Duplicate detection** — Manual admin review; flag on exact URL match.
9. **Notification preferences** — Global toggle only for MVP (no per-CFP granularity). Stories 4.1.1 and 4.2.1 updated.
10. **i18n** — English-only MVP; i18n architecture (resource files, locale-aware rendering) built in from day one; no hard-coded UI strings.

**New Scope — Feature 1.4: Past CFPs Archive:**
- A browsable `/past-cfps` screen for expired CFPs (hidden from main listing after 7 days).
- Story 1.4.1: Browse Past CFPs — list view sorted by most recently expired first.
- Story 1.4.2: View Past CFP Event History — per-event history page showing historical pattern of CFP open/close windows.
- Total features: 15 → 16.

**Pattern Note:**
- Inline `> ℹ️ Decision N (Resolved):` callouts added to affected stories for traceability — team can see the decision rationale without leaving the story.

