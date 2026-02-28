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


### 2026-02-28 — Requirements v3: Expanded Data Model, Speaker Tracking States, Standards Adoption

**Task:** Chad Green provided a comprehensive change set for v3 requirements. Updated requirements.md with surgical edits covering data model expansion, speaker tracking flow, international standards, and architectural notes.

**Key Changes Applied:**

**1. CFP Data Model Expansion (Feature 2.1):**
- Added comprehensive field set organized into logical groups: Event Details (12 fields including event type, time zone, logo, legal name, social links), CFP Details (5 fields including rich text description, speaker support email with visibility toggle), Event Scheduling (additional event dates repeater for meetups/user groups), Expense Coverage (4 booleans + free-text coverage details), Categorization (event category and topics as multi-select)
- Adopted international standards: ISO 3166-1 (country codes), ISO 3166-2 (country subdivisions), IANA Time Zone Database (time zones), UN M.49 (world regions — auto-assigned by system based on country)
- Added validation ACs: country/subdivision must be valid ISO codes, time zone must be canonical IANA identifier
- UN M.49 world region is backend-derived, not user input

**2. Speaker Tracking Status Flow (Feature 1.3):**
- Replaced "Favorites" terminology with "Personal CFP Tracking" and "Mark Interest"
- Introduced 3-state tracking: Interested → Submitted → Accepted
- Story 1.3.1: Mark Interest (was "Favorite")
- Story 1.3.2 (NEW): Track CFP Submission Status — speaker marks "I've Submitted"
- Story 1.3.3 (NEW): Track CFP Acceptance Status — speaker marks "I've Been Accepted"
- Story 1.3.4: View My Tracked CFPs (was "View My Favorites") — now includes status filtering
- Updated Epic 4 deadline reminders to trigger on Interested or Submitted status

**3. Discovery Filtering — Geographic Standards (Feature 1.2):**
- Added UN M.49 World Region filter (e.g., "Northern America", "Western Europe")
- Added Country filter (ISO 3166-1)
- Added Country Division/State/Province filter (ISO 3166-2)
- ACs clarify filters are combinable and use the backend-assigned world region mapping

**4. Organizer Submission Editing (Feature 2.1.3):**
- New Story 2.1.3: Organizer can edit submissions in "Pending Review" or "Rejected (Reconsidering)" status
- Approved submissions cannot be edited (contact admin required)

**5. Admin Reconsideration Flow (Feature 2.2):**
- Story 2.2.3: Updated rejection email to include "Request Reconsideration" button/link
- Story 2.2.4 (NEW): Organizer requests reconsideration → status changes to "Rejected (Reconsidering)" → submission becomes editable → back in admin queue with "Reconsidering" badge
- Story 2.2.5 (NEW): Admin reviews resubmitted CFP after reconsideration

**6. Authentication — Passkeys Evaluation (Epic 3):**
- Added architecture note at Epic 3 opening: Passkey-based auth (WebAuthn/FIDO2) should be evaluated as primary mechanism. Better UX, phishing-resistant. Decision deferred to Dallas/Ripley. Architecture must not assume password-only. OAuth/social login remains supported.

**7. API Infrastructure — Azure API Management (Epic 5):**
- Added infrastructure note at Epic 5 opening: All APIs fronted by Azure API Management (APIM). APIM handles rate limiting, API key management, versioning, developer portal, analytics. Arch decision for Dallas/Parker. Decision 3 rate limits remain target; APIM is enforcement layer.

**8. Metadata Updates:**
- Version: v2 → v3
- Features: 16 → 17 (added Story 1.3.2, 1.3.3, 2.1.3, 2.2.4, 2.2.5)
- Last Updated: 2026-02-28

**Patterns Applied:**
- Surgical edits only — no wholesale section rewrites where not needed
- Added `<!-- Updated v3: [brief description] -->` HTML comment markers at Feature 2.1, Feature 2.2, Feature 1.2, Feature 1.3, Epic 3, Epic 5 for traceability
- Inline validation ACs added for ISO/IANA standards to ensure testability
- Maintained Given/When/Then structure for all new ACs
- Updated cross-references (e.g., "favorites" → "tracked CFPs", "favorited" → "marked as Interested/Submitted")

**Standards Adopted:**
- **ISO 3166-1 alpha-2** — 2-letter country codes (e.g., US, DE, FR)
- **ISO 3166-2** — Country subdivision codes (e.g., US-CA for California)
- **IANA Time Zone Database** — Canonical time zone identifiers (e.g., "America/Chicago", "Europe/Berlin")
- **UN M.49** — World region classification (auto-assigned from country code, not user input)

**Impact:**
- Ripley, Lambert: Data model now comprehensive; database schema and API contracts must reflect all new fields + standards enforcement
- Kane: New validation tests required for ISO 3166, IANA time zone validation
- Dallas: Passkeys vs. password architecture decision needed before Feature 3.1 implementation starts
- Parker: APIM integration decision needed before Epic 5 (API) work begins
- Total feature count raised to **17** (from 16 in v2)

