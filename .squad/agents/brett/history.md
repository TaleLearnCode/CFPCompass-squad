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

### 2026-02-28 — Requirements v3.1: Submitter/Organizer Distinction & Claim Flow

**Task:** Chad Green requested two new requirements: tracking who submits vs. who owns a CFP listing, and a full organizer claim flow for community-submitted listings.

**Key Changes Applied:**

**1. Submitter/Organizer Distinction (Feature 2.1):**
- Added **Submitter** to Auto-populated fields: the authenticated user account (or contact email) captured at submission time — never a user input field.
- Added **"Are you the event organizer?"** boolean checkbox to Submission Flags group. Defaults to Yes. When No, submission is flagged "Unverified — Awaiting Organizer Claim."
- Added **Organizer Contact Email** (conditional, shown only when organizer = No): used to send claim invitation on publish.
- Updated Story 2.1.1 ACs to cover all three branches: organizer submitted, community submitted (unverified), and claim invitation email trigger.

**2. Feature 2.3: Organizer Claim Flow (new):**
- Story 2.3.1: Organizer self-service claim via email verification (Speaker Support Email or provided contact email).
- Story 2.3.2: Admin-assisted claim — manual assignment of organizer-owner from admin dashboard.
- Story 2.3.3: Claim invitation via email — system emails the organizer contact when CFP is published.
- Listing statuses introduced: "Unverified — Awaiting Organizer Claim", "Organizer Verified", "Organizer Verified (Admin Assigned)".
- Original submitter retains community contributor credit even after organizer claims ownership.

**3. Community Contributor Persona (Personas table):**
- Added Community Contributor: a speaker/community member who submits on behalf of an event they didn't organize; no ongoing ownership, receives credit, benefits from a comprehensive directory.

**Patterns Applied:**
- Submitter is auto-captured at submission time — never user-entered.
- "Are you the organizer?" defaults to Yes to minimize friction for the common case.
- Claim verification routes to Speaker Support Email (on listing) or Organizer Contact Email (from submission) — not to submitter's email.
- Feature count raised to **18** (from 17 in v3).

### 2026-02-28 — Requirements v3.2: Full Taxonomy & Multi-Select Categories/Topics

**Task:** Chad Green provided the full authoritative taxonomy for Event Category (Primary Domains) and Event Topics (Secondary Tags), and specified that both are multi-select fields.

**Key Changes Applied:**

**1. Full Taxonomy Replacement (Feature 2.1 — Categorization):**
- Replaced placeholder category/topic description with the full authoritative taxonomy
- **10 Primary Domains (Event Category):** Software Development & Engineering, Cloud & Infrastructure, Data/AI/ML, Security & Privacy, Web/Mobile/Frontend, DevOps/Platform Engineering/Automation, Enterprise & Architecture, Open Source & Community, Product/Design/Innovation, Specialized Domains
- **10 Secondary Tag Groups (Event Topics):** Programming Languages, Frameworks & Ecosystems, Cloud Providers, AI/ML Focus Areas, Architecture Styles, Infrastructure Practices, Security Topics, Data Topics, Developer Experience, Community & Career
- Both are seeded from the authoritative list; admin-extensible (not fully free-text or open)

**2. Multi-Select for Categories AND Topics (Feature 2.1):**
- **Event Category (Primary Domain):** Multi-select, at least 1 required. A CFP may belong to multiple primary domains (e.g., Cloud + Security).
- **Event Topics (Secondary Tags):** Multi-select, 0 or more optional. No maximum — select all that apply.
- Updated submission form field descriptions to clarify multi-select behavior and requirement constraints

**3. Submission Story ACs Expanded (Story 2.1.1):**
- Added ACs: Organizer can select 1+ categories from seeded list; at least one required to submit
- Added ACs: Multiple selected categories appear on listing and are filterable
- Added ACs: Organizer can select 0+ topics; field is optional
- Added AC: Filter behavior works against multi-value sets (any CFP with the selected category/tag is returned)

**4. Filter Behavior Updated (Features 1.1, 1.2):**
- Feature 1.1 description: Added note that CFPs may have multiple categories/topics; filtering works against multi-value sets
- Feature 1.2 description: Added note that category/topic filters work against multi-value sets — a CFP with multiple categories appears in results for any of its selected categories
- Story 1.2.1 (Filter by Topic): Added AC clarifying multi-value set membership filter behavior

**Patterns Applied:**
- Surgical edits only — updated Categorization section, relevant ACs, and feature descriptions
- Maintained Given/When/Then structure for all new ACs
- Clarified multi-select constraints: at least 1 category required, 0+ topics optional
- Made filter behavior explicit: multi-value set membership (not exact match)

**Impact:**
- Ripley (Backend): Database schema must support many-to-many relationships for categories and topics; seeded taxonomy data in migration; filter queries must handle multi-value set membership
- Lambert (Frontend): Multi-select UI controls for both fields; validation to enforce at least 1 category selected; filter UI supports multi-select with OR logic
- Kane (Tester): Test multi-select validation; test filter behavior with CFPs having multiple categories/topics; verify at least 1 category required, topics optional
- Dallas (Lead): Taxonomy is now defined and locked for MVP; admin extension mechanism can be deferred to post-MVP

**Taxonomy:**
- **Primary Domains (10):** Software Dev/Eng, Cloud/Infra, Data/AI/ML, Security/Privacy, Web/Mobile/Frontend, DevOps/Platform/Automation, Enterprise/Architecture, Open Source/Community, Product/Design/Innovation, Specialized Domains
- **Secondary Tags (10 groups):** Programming Languages, Frameworks/Ecosystems, Cloud Providers, AI/ML Focus, Architecture Styles, Infrastructure Practices, Security Topics, Data Topics, Developer Experience, Community/Career


### 2026-03-01 — Requirements v3.3: Observability & Developer Experience NFRs (Aspire 13.1)

**Task:** Chad Green directed adoption of .NET Aspire 13.1. Analyzed whether user-facing or non-functional requirements need updating. Added two NFR sections to requirements.md.

**Key Decisions:**

1. **Aspire scope:** Aspire is primarily infrastructure/developer tooling — NOT user-facing. Technical details (AppHost project, AddServiceDefaults(), Aspire diagnostics) belong in architecture.md, not requirements.md.

2. **What to add to requirements.md:**
   - NFR-1: Observability (health endpoints, distributed tracing, structured logging, correlation across service boundaries)
   - NFR-2: Developer Experience (single-command local stack start, local telemetry dashboard)
   - Both are observable, testable requirements grounded in user/operator needs

**Changes Applied:**

**1. New "Non-Functional Requirements" Section (v3.3):**
- Placed after Epic 6 (Administration), before Resolved Decisions
- Two NFRs covering observability and developer experience

**2. NFR-1: Observability (Distributed Tracing & Health Checks):**
- Requirement: `/health` endpoint on every service component
- Health checks cover all external dependencies (SQL, Redis, Service Bus, ACS)
- Traces correlated by trace ID across service boundaries
- Structured logs include trace ID for end-to-end correlation
- Traces exported to Azure Monitor / Application Insights
- ACs demonstrate: end-to-end tracing from API → Service Bus → background worker, operator debugging capability, health endpoint behavior

**3. NFR-2: Developer Experience (Local Stack):**
- Requirement: Full local development stack startable with a single command
- All services (API, Web, SQL, Redis, Service Bus emulator) initialized automatically
- Local telemetry dashboard available during development (port-accessible)
- ACs demonstrate: 30-second startup, dashboard accessibility, real-time trace visibility for debugging

**4. Metadata Updates:**
- Version: v3.1 → v3.3
- Last Updated: 2026-02-28 → 2026-03-01
- Added HTML comment markers for traceability: `<!-- Updated v3.3: Added NFR section... -->`

**Patterns Applied:**
- NFRs describe observable behavior, not implementation (Aspire tooling details deferred to architecture)
- Health endpoint and distributed trace requirements grounded in operator/debugger needs
- Local stack startup and dashboard requirements grounded in developer productivity
- All ACs use Given/When/Then for testability
- Separation of concerns: requirements cover "what must be observable", architecture covers "how to build with Aspire"

**Rationale:**
- Health endpoints are operator-facing (monitoring, alerting) — belongs in NFRs
- Distributed tracing and trace correlation enable production debugging — belongs in NFRs
- Local development stack experience affects team velocity — belongs in NFRs
- Aspire implementation details (AppHost, orchestration, SDK extensions) stay in architecture.md
- This aligns with Requirements Analyst charter: define observable behavior, not technical stack

**Impact:**
- Ripley (Backend): Implement `/health` endpoints on all service components; ensure trace ID propagation in logging
- Lambert (Frontend): Ensure Blazor Server logs include trace IDs
- Parker (DevOps): Container Apps health probes configured to use `/health` endpoints; Application Insights configured as traces sink
- Dallas (Lead): Aspire AppHost project architecture and service configuration; ensures all services call AddServiceDefaults() and are discoverable via Aspire
- Kane (Tester): Test health endpoints and external dependency coverage; test trace correlation end-to-end


### 2026-03-01 — Requirements v3.4: Expanded NFR-1 Health Check Requirements

**Task:** Chad Green directed: "Health check endpoints must verify both service availability AND connectivity to all required dependencies." Expanded NFR-1 with per-service dependency coverage, status semantics, HTTP codes, and Container Apps integration.

**Key Directive:**
Health endpoints must not only report "up/down" but expose per-dependency status and appropriate HTTP codes for orchestration (200 for operational, 503 for unhealthy).

**Changes Applied:**

**1. NFR-1 Complete Rewrite — Health Checks Now Include Per-Service Dependency Verification:**
   - **CfpCompass.Api:** SQL Database, Redis Cache, Service Bus
   - **CfpCompass.Web:** API service reachability
   - **CfpCompass.Workers:** SQL Database, Service Bus, Redis Cache
   - **CfpCompass.Functions:** SQL Database, Service Bus (plus `/api/health` HTTP function endpoint requirement)

**2. Health Status Semantics (3-State Model):**
   - **Healthy:** All required dependencies reachable
   - **Degraded:** Non-critical dependencies unreachable; service continues operating
   - **Unhealthy:** One or more critical dependencies unreachable; service cannot operate correctly

**3. HTTP Status Code Mapping:**
   - **200 OK:** Returned for Healthy or Degraded status
   - **503 Service Unavailable:** Returned for Unhealthy status
   - Ensures Container Apps liveness/readiness probes can correctly evaluate service state

**4. Container Apps Integration Requirement:**
   - Health endpoints must respond within ≤5 seconds
   - Compatible with Azure Container Apps probe evaluation
   - No authentication headers required

**5. New Acceptance Criteria (9 detailed scenarios):**
   - Per-service healthy state with all dependencies OK (HTTP 200)
   - Degraded state when non-critical dependency (Redis) fails (HTTP 200)
   - Unhealthy state when critical dependency (SQL) fails (HTTP 503)
   - Web service health check behavior (API reachability)
   - Functions service health check endpoint (`/api/health`)
   - Container Apps liveness probe integration (restart on 503)
   - Distributed trace correlation (end-to-end visibility)

**6. Metadata Updates:**
- Version: v3.3 → v3.4
- Last Updated: 2026-03-01
- Added HTML comment marker for traceability: `<!-- Updated v3.4: Expanded NFR-1 health checks... -->`
- Added comprehensive Revision History table (v1.0 through v3.4)

**Patterns Applied:**
- Surgical edit to NFR-1 requirement section — expanded without removing existing trace/logging requirements
- Per-service dependency lists organized in clear bulleted format
- Status semantics defined operationally (what "healthy" means to each service)
- HTTP codes tied directly to orchestration use case (probes)
- Acceptance criteria cover both happy path (all healthy) and failure modes (degraded, unhealthy)
- All new ACs follow Given/When/Then structure

**Rationale:**
- Container Apps requires explicit HTTP status codes to drive orchestration decisions (liveness restart, readiness drain)
- Per-dependency reporting enables operators to diagnose which specific resource is unhealthy without false positives
- Degraded state allows graceful degradation (e.g., cache failure shouldn't kill the service)
- Function Apps health endpoint is a new requirement — must be HTTP-triggered (not middleware) due to Functions runtime limitations

**Impact:**
- **Ripley (Backend):** Implement `/health` endpoint on API, Workers with per-dependency checks (SQL ping, Redis PING, Service Bus peek); report Healthy/Degraded/Unhealthy with HTTP 200/503; Web service must check API reachability; Functions must expose `/api/health` HTTP function
- **Lambert (Frontend):** Blazor Server health endpoint checks API reachability
- **Parker (DevOps):** Configure Container Apps liveness/readiness probes to use `/health` endpoint with appropriate timeout; verify 503 responses trigger restarts; verify 200 responses keep containers running
- **Dallas (Lead):** Review health endpoint architecture with Ripley; confirm Functions runtime compatibility with HTTP function approach
- **Kane (Tester):** Test all 9 acceptance criteria; verify dependency failure scenarios return correct HTTP codes; verify probe integration with local Container Apps emulation
- **Chad (Product):** Health endpoints now fully specified for MVP release


