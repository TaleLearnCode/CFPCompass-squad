---
title: Non-Goals and Guardrails
description: Establishes intentional scope boundaries and architectural guardrails for the CFP Compass platform.
tags:
  - non-goals-and-guardrails
  - architecture
  - cfp-compass
  - event-driven
  - governance
---

# CFP Compass Non-Goals and Guardrails

## Purpose and Audience

This document defines what CFP Compass **explicitly does not attempt to do**. Its purpose is to establish clear boundaries around product and platform scope, prevent scope creep during development and feature requests, and ensure that all stakeholders — architects, developers, product owners, and consumers — share a common understanding of the deliberate limits of this system.

Non-goals and guardrails are **not deficiencies or deferred work**. They represent intentional design decisions that preserve platform focus, operational simplicity, team velocity, and long-term maintainability. The boundaries documented here were made deliberately, not by accident or oversight.

**Who should read this document:**
- **Architects and technical leads** — to evaluate feature requests and change proposals against established boundaries
- **Developers** — to understand what not to build when implementing features
- **Product owners and business stakeholders** — to align roadmap discussions with architectural reality
- **Future maintainers** — to understand why certain capabilities are absent and should remain so

---

## Core Non-Goals

CFP Compass is a CFP discovery, submission, and speaker-tracking platform. The following capabilities are explicitly outside its scope.

### ✗ Non-Goal: Speaker Profile and Portfolio Platform

**What we do NOT do:**

CFP Compass does not provide speaker profile pages, public bios, talk history, submission history visibility to other users, or portfolio features. Speakers are internal users for tracking purposes only — their identity and activity are private.

**Why this matters:**

Building a speaker portfolio platform requires an entirely different product surface: public profile design, privacy controls, content moderation for bios and photos, speaker discovery features, and ongoing feature investment in profile management. This would shift CFP Compass's focus from CFP discovery (its core value) to speaker identity — a distinct product category with its own scope, risks, and user expectations. Mixing both in an MVP would dilute both.

**What users must do instead:**
1. Use Sessionize, Papercall.io, or similar dedicated speaker profile platforms for public portfolio management.
2. Use Speaker Deck, GitHub, or a personal website for talk materials and history.
3. CFP Compass tracks *your* submissions privately — it is a personal tool, not a public showcase.

---

### ✗ Non-Goal: CFP Tracking Tool for Conference Organizers

**What we do NOT do:**

CFP Compass does not provide submission review workflows, speaker scoring, acceptance communication tools, or scheduling capabilities for conference organizers managing their incoming speaker applications. The organizer experience in CFP Compass is limited to: submitting a listing, editing an owned listing, and verifying ownership via the claim flow.

**Why this matters:**

CFP management for organizers (reviewing applications, scoring submissions, communicating decisions, building schedules) is a complex product domain already served by tools like Sessionize, Papercall.io, and conference-specific platforms. Building this in CFP Compass would create direct competition with those tools, massively expand scope, and fragment focus away from the speaker side — which is the primary audience.

**What organizers must do instead:**
1. Use Sessionize, Papercall.io, or a similar platform to manage incoming speaker applications.
2. Use CFP Compass only to publish and maintain your CFP listing so speakers can discover it.
3. The approved CFP listing on CFP Compass links speakers directly to your CFP submission system.

---

### ✗ Non-Goal: Email Marketing Platform

**What we do NOT do:**

CFP Compass does not provide bulk email campaigns, promotional newsletters, sponsor communications, custom email template editors, subscriber list management, or email marketing analytics. Its email capabilities are strictly limited to: transactional notification emails (submission confirmations, moderation decisions, account events) and the two scheduled communications speakers opt into (deadline reminders, weekly digest).

**Why this matters:**

Email marketing is a distinct product category with its own compliance obligations (CAN-SPAM, GDPR Article 6(a) consent), deliverability infrastructure, and feature requirements. Mixing marketing email capabilities into a transactional system introduces legal complexity, deliverability risk (shared sender reputation), and operational overhead that is entirely outside CFP Compass's mission. The Azure Communication Services integration is sized and configured for transactional volume only.

**What users must do instead:**
1. Use dedicated email marketing platforms (Mailchimp, SendGrid Marketing, ConvertKit) for promotional communications.
2. CFP Compass's email integration (ACS) is not configured for bulk broadcast marketing — do not attempt to repurpose it.
3. Conference organizer communications to accepted speakers must happen outside CFP Compass.

---

### ✗ Non-Goal: Real-Time Event Updates and Live Notifications

**What we do NOT do:**

CFP Compass does not provide real-time push notifications, live CFP status updates in the browser, WebSocket-based live feeds, or instant notification delivery. The system is eventually consistent — cache TTLs of 1–5 minutes are acceptable, and email notifications are delivered asynchronously (typically within minutes, not seconds).

**Why this matters:**

Real-time delivery requires significant infrastructure investment: WebSocket connections at scale, per-user notification fanout, presence tracking, and real-time message delivery guarantees. For a CFP discovery platform, sub-second notification latency is not a meaningful user benefit — speakers check deadline status on their own schedule, not in real time. The accepted eventual consistency window (maximum 5 minutes for cached listing updates, minutes for email delivery) is appropriate for the domain.

**What users must do instead:**
1. Rely on the weekly digest and deadline reminder emails for proactive notification.
2. Refresh the CFP listing page to see the latest approved CFPs (cache TTL: 5 minutes).
3. Poll the submission status endpoint (`GET /api/v1/submissions/{id}/status`) for write operation completion — the API is designed for polling, not push.

---

### ✗ Non-Goal: Multi-Tenant SaaS Platform

**What we do NOT do:**

CFP Compass is not a multi-tenant platform. It does not support white-labeling, tenant isolation, per-tenant configuration, per-tenant branding, or per-tenant data partitioning. There is one CFP Compass — one database, one application, one set of listings for the entire community.

**Why this matters:**

Multi-tenancy introduces significant architectural complexity: tenant isolation in the data model, per-tenant configuration management, per-tenant billing, tenant onboarding and offboarding workflows, and the risk of cross-tenant data leakage. None of this complexity is justified for CFP Compass's purpose, which is explicitly a single shared community resource. Adding multi-tenancy would require an architectural re-design that contradicts every cost and simplicity decision made to date.

**What organizations must do instead:**
1. Use the public CFP Compass platform as a shared community resource — it is not sold as a private deployment.
2. Organizations that need a private, branded CFP discovery tool should evaluate building their own or using conference management platforms with white-label options.
3. The public REST API (via APIM) provides programmatic access for organizations that want to integrate CFP Compass data into their own systems.

---

### ✗ Non-Goal: Raw Data Export, Analytics, and Reporting

**What we do NOT do:**

CFP Compass does not provide bulk data export (CSV, Excel), analytics dashboards, trend reports, submission volume statistics, geographic heatmaps, or business intelligence features. The admin dashboard shows operational summary metrics (pending submissions count, active users count) — it is not an analytics platform.

**Why this matters:**

Analytics and reporting require dedicated infrastructure (data warehouse, BI tooling, aggregation pipelines) and ongoing feature investment that is entirely outside the platform's mission. Providing raw data exports also raises privacy concerns (speaker tracking data, email addresses) that would require careful anonymization and GDPR-compliant data processing agreements. The public REST API provides programmatic read access to approved CFP listings — this is the appropriate integration point for consumers who need data.

**What users must do instead:**
1. Use the public REST API (`GET /api/v1/cfps` with filtering and pagination) to programmatically access CFP listing data.
2. Build your own aggregations and analytics from the API response data in your own tooling.
3. Platform-level analytics (traffic, API usage) are available to the CFP Compass operations team via Azure Monitor and APIM analytics — not exposed to end users.

---

### ✗ Non-Goal: Conference Scheduling and Agenda Tool

**What we do NOT do:**

CFP Compass does not manage conference schedules, session slots, speaker scheduling, room assignments, session ratings, attendee registration, or event agendas. The CFP lifecycle in CFP Compass ends at submission and publication — what happens after a speaker submits to a conference is entirely outside scope.

**Why this matters:**

Conference scheduling is a complex operational domain with its own specialized tooling (Sessionize, Sched, Whova, Guidebook). It requires integration with venue management, speaker travel coordination, AV logistics, and attendee-facing app development. This is categorically outside CFP Compass's purpose as a *discovery* platform for speakers looking for open CFPs — not a conference operations platform.

**What users must do instead:**
1. Use Sessionize, Sched, Whova, or similar tools for conference schedule management.
2. Once a speaker is accepted (tracked as "Accepted" in CFP Compass), all further communication and logistics are managed in the conference's own tooling.

---

### ✗ Non-Goal: Replacing Existing Conference Management Systems

**What we do NOT do:**

CFP Compass does not replace, integrate with, or synchronize data from existing conference management platforms (Sessionize, Papercall.io, Eventbrite, etc.). It is a community aggregation layer — organizers submit CFP listings manually, or API consumers can automate submission. CFP Compass does not pull data from other platforms automatically.

**Why this matters:**

Real-time data synchronization with external platforms requires negotiated API access, ongoing maintenance of integrations as external APIs change, and conflict resolution when data diverges. This would make CFP Compass dependent on third-party platform stability and API availability — a dependency that increases operational risk without proportional benefit for MVP. Organizers submit once; speakers discover centrally. That is the value proposition.

**What users must do instead:**
1. Organizers submit CFP listings directly to CFP Compass via the public submission form or the API.
2. Third-party tools that want to integrate CFP Compass data can consume the public REST API (APIM subscription required).
3. Bidirectional sync or deep integration with Sessionize, Papercall.io, or similar platforms is not planned and would require an architecture review if proposed.

---

## Guardrails and Constraints by Design

Guardrails are intentional architectural constraints that shape how CFP Compass behaves within its scope. Unlike non-goals (which exclude capabilities entirely), guardrails constrain *how* included capabilities work.

### Guardrail: Contract-First API and Event Design (ADR-014)

**What this means:**

No REST API endpoint and no Azure Service Bus topic may be implemented without an approved specification. REST endpoints require a merged OpenAPI 3.1 spec PR in `docs/api/openapi/`; Service Bus topics require a merged AsyncAPI 3.0.0 spec PR in `docs/api/asyncapi/`. The spec PR must be approved and merged *before* the implementation PR is opened — no exceptions.

**Tradeoff accepted:**

This adds a mandatory spec-authoring step before any API or event work. Developers cannot immediately write code for a new endpoint — they must first author a spec, submit it for review, get it merged, and then implement. This slows down the first delivery of any new API surface. In return, the team gains: design review happens at spec time (before code exists), APIM is always in sync with the contract (it imports the spec directly), breaking changes are detectable via `oasdiff`, and the API surface is fully documented for external consumers from day one.

**Design implication:**

The GitHub Projects board includes explicit **Spec** and **Spec Review** columns before **In Progress** — making the spec gate visible in project tracking. CI validates OpenAPI specs with Spectral and AsyncAPI specs with the AsyncAPI CLI on every PR touching `docs/api/`. Implementation PRs must reference the approved spec PR. Developers must author specs before implementation — this is a workflow, not just a policy.

---

### Guardrail: Event-Driven Writes Only — No Synchronous DB Writes from API (ADR-007)

**What this means:**

API controllers on the write path (POST, PUT) must publish a Service Bus event and return HTTP 202 Accepted. They must not perform synchronous writes to Azure SQL. The database write happens in the Azure Function that processes the Service Bus message asynchronously.

**Tradeoff accepted:**

Write operations are eventually consistent — callers must poll the status endpoint to confirm completion. This is a departure from the familiar "POST returns 201 Created with the new resource" REST pattern. In exchange, the API is responsive regardless of Azure SQL's cold-start state, the system degrades gracefully during SQL maintenance windows, and the write path scales independently from the read path. The polling pattern is well-specified in the HTTP 202 + Location header response (ADR-009).

**Design implication:**

Developers cannot implement a "quick" synchronous write shortcut, even for simple operations. All POST/PUT endpoints follow the same pattern: validate → publish → 202. Status polling infrastructure (`ProcessingStatus` table, `StatusUpdateProcessor`, `/api/v1/submissions/{id}/status` endpoint) must be maintained for the pattern to work correctly. API consumers must handle 202 responses and implement polling.

---

### Guardrail: English-Only UI for MVP — i18n Architecture in Place

**What this means:**

CFP Compass ships in English only for MVP. No non-English locale is supported at launch. However, all user-facing strings must go through `IStringLocalizer<T>` — no string literals in Razor/Blazor markup, email templates, or validation messages. Resource files in `Resources/` are in place from day one.

**Tradeoff accepted:**

All developers must use `IStringLocalizer` even for strings that will only ever appear in English at MVP. This is extra ceremony for every UI string. In return, adding a new locale requires only adding `.resx` files — no code changes, no architectural rework. The decision to enforce the i18n framework now costs a small per-string overhead and prevents the accumulation of hard-coded strings that would make a future locale effort prohibitively expensive.

**Design implication:**

PR reviews must verify that no user-facing string literals appear directly in Razor components or controllers. The CI pipeline should (or does) lint for hard-coded string literals in UI code. Email templates use the same `IStringLocalizer` pattern. Validation messages use `ErrorMessageResourceType` + `ErrorMessageResourceName` data annotations.

---

### Guardrail: No Direct Database Access from the Web Layer

**What this means:**

`CFPCompass.Web` must not reference `CFPCompass.Infrastructure`, instantiate a `DbContext`, inject a repository, or call any Azure SDK directly. All data access from the Web layer flows through Application Service interfaces injected via DI.

**Tradeoff accepted:**

Blazor Server could be made to access the database directly — it runs on the server, the connection string is available. Preventing this requires discipline (enforced via code review and the absence of an Infrastructure project reference in the Web project file). In return, the Web layer remains thin, testable without a database, and unable to bypass Application layer validation rules. This boundary makes it possible to unit-test Application Services independently of the Web UI.

**Design implication:**

The `CFPCompass.Web.csproj` must not contain a `<ProjectReference>` to `CFPCompass.Infrastructure`. Adding such a reference to "quickly access data" is a guardrail violation. If a data access pattern cannot be expressed through Application Service interfaces, the correct fix is to add a method to the Application Service, not to bypass the layer.

---

### Guardrail: Admin Accounts via Environment Configuration Only (MVP)

**What this means:**

Admin identity is determined at login time by checking the authenticated user's email against a comma-separated list stored in Azure Key Vault (`AdminEmails` secret). There is no admin management UI, no admin role assignment screen, and no database-managed admin role table for MVP.

**Tradeoff accepted:**

Adding or removing an admin requires a Key Vault secret update and the user's next login (the check runs on every login, not cached). There is no UI workflow for this. In return, the admin system has zero attack surface for privilege escalation through the application — there is no "promote to admin" endpoint that could be abused. Admin identity management is an operations-level concern, not a product feature, which is appropriate for MVP where the admin population is a handful of known individuals.

**Design implication:**

The `Admin` claim is assigned in the authentication middleware on every login. No `Admin` role record exists in the `AspNetRoles` table. The list of admin emails is never logged or exposed in API responses. Future post-MVP admin management UI is possible but would require adding a proper admin role table and migrating away from the env-config approach — document this as a known future evolution point.

---

## Tradeoffs Accepted

The following are deliberate, documented architectural choices where two reasonable paths existed and one was chosen with full awareness of the consequences.

### Tradeoff #1: Eventual Consistency vs. Immediate Consistency

**Decision:** Accepted eventual consistency for all write operations via the event-driven write pattern (ADR-007). API returns HTTP 202 Accepted; data is available after asynchronous Function processing completes (typically seconds to minutes).

**Impact:** API consumers and the Web App cannot rely on data being immediately available after a write. The polling pattern via `GET /api/v1/submissions/{id}/status` is the documented mechanism for confirming write completion. This is a departure from the familiar synchronous REST model but is the correct trade for a system where Azure SQL Serverless cold starts are a real latency risk. The UI must handle `Pending` status states and show appropriate feedback to users.

---

### Tradeoff #2: APIM Developer Tier Fixed Cost vs. Consumption Variable Cost (ADR-006)

**Decision:** APIM Developer tier (~$50/month fixed) instead of Consumption tier (pay-per-call, ~$0.0035/10K calls).

**Impact:** At MVP traffic levels, the Developer tier is more expensive than Consumption. The trade is: Developer tier eliminates cold starts (~1–2s on Consumption tier), enables VNet integration (internal mode), provides dedicated capacity, and gives a clear upgrade path to Standard V2. For a public API where response time consistency is part of the product quality, the cold-start risk of Consumption tier was the deciding factor. The ~$50/month fixed cost is accepted as a floor for API reliability. **Note:** Developer tier has no zone redundancy — it is appropriate for MVP but must be upgraded to Standard V2 when availability SLA requirements increase.

---

### Tradeoff #3: ASP.NET Core Identity vs. Azure AD B2C (ADR-003)

**Decision:** ASP.NET Core Identity (self-hosted) instead of Azure AD B2C (managed).

**Impact:** CFP Compass owns the entire authentication system — identity storage, session management, passkey flows, and OAuth integration. This means we own security bugs, schema migrations, and operational responsibility for the identity subsystem. In return, we get full control over the WebAuthn/FIDO2 passkey flow (B2C's passkey support requires brittle custom XML policies), zero per-authentication charges at scale, and direct customization of all authentication UI without B2C's custom policy complexity. For a public community platform where the tech-savvy user base has high privacy expectations, ASP.NET Core Identity with passkey support is the right long-term investment.

---

### Tradeoff #4: Single-Tenant Architecture vs. Multi-Tenant

**Decision:** Single-tenant architecture — one CFP Compass, one database, one community.

**Impact:** CFP Compass cannot be white-labeled, sold as a private deployment, or operated as a per-organization SaaS product without a full architectural re-design. This is an accepted constraint — multi-tenancy would require row-level security in Azure SQL, per-tenant configuration management, tenant onboarding/offboarding workflows, and significantly higher operational complexity. The community benefit of a single shared, neutral CFP aggregation platform outweighs the commercial flexibility of multi-tenancy for the defined mission.

---

## Problems the Platform Does Not Solve

The following are specific, real problems that users or stakeholders might expect CFP Compass to solve — but which are intentionally out of scope.

### Speaker Acceptance Rate Analytics

CFP Compass does not track whether speakers were accepted or rejected by conferences — only the speaker's self-reported tracking state (Interested, Submitted, Accepted). There is no aggregate statistics feature showing acceptance rates, speaker success rates, or topic popularity trends across conferences.

### Conference Quality Rating

CFP Compass does not allow speakers to rate, review, or flag conferences for quality, responsiveness, or CFP integrity. There is no reputation system for conferences or organizers. Moderation is limited to admin-reviewed CFP listings for completeness and legitimacy — not ongoing conference quality signals.

### Speaker Networking and Community Features

CFP Compass is not a community platform. There are no forums, discussion threads, direct messaging, speaker mentoring connections, or community features. Speakers interact only with their own tracking data, not with each other.

### CFP Deadline Negotiation or Extension Tracking

When a conference extends a CFP deadline, CFP Compass reflects the updated deadline only if the organizer (or an admin) manually updates the listing. The platform does not monitor conference websites for deadline changes or automatically detect updated deadlines.

### Speaker Travel and Expense Coordination

While CFP listings may include expense coverage information (as submitted by organizers), CFP Compass does not manage travel bookings, expense reimbursements, or speaker travel logistics. This is a strictly informational field in the listing.

### Conference Acceptance Notification Pipeline

CFP Compass does not receive acceptance or rejection notifications from conferences on behalf of speakers. The "Accepted" tracking state is self-reported by the speaker — there is no automated conference-to-platform notification of acceptance decisions.

---

## Future Expansion (What *Might* Be Added)

While CFP Compass has clear non-goals, it is designed to be extensible. Future evolution is possible in these areas (though not committed):

- **Per-CFP notification preferences** — currently global on/off toggles for deadline reminders and digest; per-CFP notification controls are a deferred capability (Decision 9).
- **Additional OAuth providers** — the current MVP supports Google, GitHub, and Microsoft; additional OAuth providers (LinkedIn, Twitter/X) could be added without architectural change.
- **API webhook support** — consumers that prefer push to polling for write operation completion could be served by a webhook delivery mechanism, though this would require significant new infrastructure (webhook registration, delivery retry, security signing).
- **Additional locales** — the i18n architecture (`.resx` files, `IStringLocalizer`) is in place; non-English locales require only resource file translation and locale-specific testing.
- **Enhanced admin analytics** — a dedicated admin analytics view (submission volume trends, popular topics, geographic distribution) is architecturally feasible as a read-only query layer over Azure SQL.

**These possibilities are not commitments.** Any expansion would require an architecture review, an ADR, and in the case of new API surfaces, an approved OpenAPI or AsyncAPI spec before implementation.

---

## Implications for Architecture and Governance

### Feature Requests

When a stakeholder or team member proposes a new capability for CFP Compass, the first question is: "Does this fall into one of our documented non-goals?"

- **If yes** → The answer is no. Redirect to the appropriate alternative (documented in each non-goal's "What consumers must do instead" section). Non-goals are not negotiated away without an explicit architectural decision — treating a non-goal as a feature request restores it to the backlog without context for *why* it was excluded.
- **If no** → Evaluate the feature against architectural principles, the guardrails, and resource constraints. If it passes, open a spec PR (for API surface) or an ADR PR (for architectural changes) before implementation work begins.

### Architecture Reviews

Architecture reviews of proposed changes must explicitly verify that changes do not creep into non-goal territory. Reviewers should ask:

- Does this change add CFP tracking capabilities for organizers? (Non-goal #2)
- Does this add profile or portfolio features? (Non-goal #1)
- Does this require real-time delivery guarantees? (Non-goal #4)
- Does this introduce per-tenant configuration or data isolation? (Non-goal #5)
- Does this bypass the event-driven write pattern with a synchronous DB write? (Guardrail: Event-Driven Writes)
- Does this omit a spec PR before implementation? (Guardrail: Contract-First)

### Consumer Guidance

Consumers of the public REST API should receive this document (or a summary) during onboarding. API consumers frequently request capabilities that fall within these non-goals (raw data export, webhook delivery, analytics endpoints). Understanding these boundaries early prevents misdirected integration design and sets correct expectations about the API surface.

### Platform Evolution

CFP Compass evolution should remain additive within its defined scope — new CFP fields, additional background jobs, new API endpoints for existing domain capabilities — and should not creep into the excluded capability areas. When a proposed evolution requires crossing a non-goal boundary (e.g., "let's add a speaker profile page"), the team should treat it as a significant scope discussion requiring explicit product and architecture decision-making, not a straightforward backlog item.

---

## Summary: Platform Scope Lens

This quick-reference table summarizes what CFP Compass owns, what it does not own, and what architectural constraints are accepted by design.

**In Scope (CFP Compass Owns):**
- CFP listing aggregation: discovery, search, filtering, pagination, and historical archive
- CFP submission ingestion: public form, moderation workflow, organizer claim verification
- Speaker tracking: 3-state personal tracking (Interested → Submitted → Accepted)
- Notification delivery: deadline reminders and weekly digest emails (user-controlled, global toggle)
- Public REST API for programmatic access to approved CFP listings
- Admin moderation: submission review, user management, API key approval

**Out of Scope (Users and Consumers Own):**
- Speaker public profiles, portfolios, and talk history
- Conference organizer submission management, scoring, and acceptance workflows
- Bulk email marketing, promotional campaigns, and conference communications
- Real-time notification delivery and sub-minute data freshness
- Multi-tenant white-label deployments and per-organization configuration
- Analytics, business intelligence, and raw data exports

**By Design (Accepted Constraints):**
- Eventual consistency for write operations (API 202 + polling, max 5-minute cache TTL)
- Contract-first development: spec PR merged before implementation PR opened (ADR-014)
- English-only UI for MVP (i18n architecture in place; locales added by adding `.resx` files)
- No direct DB access from the Web layer (Web → Application Services → Infrastructure → SQL)
- Admin accounts defined in Key Vault environment config; no admin management UI for MVP

By maintaining these clear boundaries, CFP Compass remains focused on its mission — making CFP discovery effortless for community speakers — while staying operationally simple, architecturally coherent, and maintainable by a small team over the long term.
