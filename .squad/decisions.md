# CFP Compass — Team Decisions

_Maintained by Scribe. Agents write to `.squad/decisions/inbox/` — Scribe merges here._

---

## System Architecture v1 — Tech Stack & ADRs Complete

**Date:** 2026-02-28  
**Author:** Dallas (Lead & Architect)  
**Status:** Proposed — pending Chad Green review for 4 open questions  
**Full document:** `.squad/architecture.md`

---

### Summary

System architecture defined across 6 architectural decision records (ADRs):

1. **ADR-001: Azure SQL Database (Serverless)** — Relational storage for CFPs, users, tracking, moderation
2. **ADR-002: Blazor Server with .NET 10 SSR** — Frontend framework combining SEO + rich interactivity
3. **ADR-003: ASP.NET Core Identity + Fido2NetLib** — Authentication with WebAuthn/FIDO2 passkeys + OAuth middleware
4. **ADR-004: Azure Container Apps Jobs** — Background workers for digest, reminders, expiry, region assignment
5. **ADR-005: Redis Basic C0** — Distributed caching for API responses and session state
6. **ADR-006: APIM Consumption Tier** — Public API with built-in rate limiting, key management, developer portal

### Open Questions for Chad Green

| Question | Impact | Urgency |
|----------|--------|---------|
| Production domain name | Infra provisioning | High |
| Bot protection strategy (reCAPTCHA v3 / Cloudflare Turnstile / honeypot) | Submission form | High |
| Initial taxonomy definition (who defines category/topic lists) | DB seeding | Medium |
| Email sender address/domain for ACS | Email implementation | High |

### Decisions Locked In

- **Compute:** .NET 10 / C# everywhere (backend + Blazor Server frontend)
- **Storage:** Azure SQL + Redis + APIM for API caching
- **Deployment:** Container Apps + Container Apps Jobs + APIM
- **Auth:** ASP.NET Core Identity with passkey support (WebAuthn/FIDO2)
- **Background Jobs:** Container Apps Jobs with Polly retry policies
- **API Management:** APIM Consumption tier for rate limiting + key management

### Impact by Team

**Ripley (Backend):** Proceed with EF Core schema design on Azure SQL; passkey integration via Fido2NetLib; API rate limiting integrated with APIM

**Lambert (Frontend):** Blazor Server enables C# UI; can leverage shared domain models with backend; SSR handles SEO for public CFP listings

**Parker (DevOps):** Terraform IaC for Container Apps, SQL (Serverless), Redis Basic, APIM (Consumption), Key Vault, ACR; GitHub Actions CI/CD for containerized deployments

**Kane (Tester):** Integration tests use WebApplicationFactory + SQL Server Docker container; test APIM rate limiting scenarios; passkey auth flow testing requires FIDO2 test harness

---

## Resolved Open Questions — Requirements v2 Complete

**Date:** 2026-02-28  
**Author:** Chad Green (captured via Copilot), Brett (Requirements Analyst)  
**Status:** Merged into requirements — all decisions now guide feature implementation

---

### Decision 1: Organizer Account Requirement

**Resolved:** No account required. The CFP submission form is entirely public — organizers provide a contact email only. No login or registration is needed to submit a CFP.

**Impact:** Feature 2.1 (Organizer Submission Form) is zero-friction — lowers barrier for event organizers to list their CFPs.

---

### Decision 2: CFP Expiration / Archive Policy

**Resolved:** CFPs are hidden from the main listing 7 days after their submission deadline. Hidden CFPs are automatically archived to a "Past CFPs" section. A dedicated archive browsing screen (`/past-cfps`) exists so speakers can track event history and anticipate when CFPs will reopen.

**Impact:** Introduces Feature 1.4 (Past CFPs Archive). Speakers gain historical context to plan submission calendar.

---

### Decision 3: API Rate Limits

**Resolved:** 100 requests/minute per API key for read operations; 10 requests/minute per API key for write operations. Requests exceeding limits receive `429 Too Many Requests`.

**Impact:** Feature 5.1 (API Authentication) enforces rate limiting. Prevents abuse while allowing reasonable integration volume.

---

### Decision 4: Admin Account Creation

**Resolved:** Admin accounts are defined via environment config (list of admin emails) for MVP. No admin management UI will be built initially.

**Impact:** MVP simplicity — admins are bootstrap-configured at deployment. Feature 6.1 (Admin Dashboard) assumes admin identity pre-established.

---

### Decision 5: Email Service Provider

**Resolved:** Azure Communication Services (ACS) will handle all transactional and digest emails (deadline reminders, digest, approval/rejection notifications).

**Impact:** Features 4.1 (Deadline Reminders), 4.2 (Weekly Digest), 2.2.2 (Approval), 2.2.3 (Rejection) all integrate with ACS for reliable delivery.

---

### Decision 6: CFP Event Date Schema

**Resolved:** Optional `startDate` / `endDate` fields. Both may be null if the event date is TBD.

**Impact:** Flexible event date capture. Allows organizers to submit CFP before event schedule is finalized.

---

### Decision 7: API Versioning Strategy

**Resolved:** URL path versioning: `/api/v1/`. All API endpoints are prefixed with this path.

**Impact:** Features 5.2 (Read endpoints), 5.3 (Write endpoints) all follow `/api/v1/` path structure. Enables backward compatibility as API evolves.

---

### Decision 8: Duplicate CFP Detection

**Resolved:** Manual admin review. The admin UI flags potential duplicates when an exact official URL match is found on an incoming submission.

**Impact:** Feature 2.2 (Admin Moderation Workflow) includes duplicate detection helper. Prevents accidental CFP duplication while avoiding false positives.

---

### Decision 9: Notification Preferences Granularity

**Resolved:** Global toggle for MVP — deadline reminders on/off, digest on/off. Per-CFP notification controls are deferred to a future iteration.

**Impact:** Features 4.1 (Deadline Reminders), 4.2 (Weekly Digest) implement global account-level toggles. Simplifies MVP; per-CFP controls (future) will refine user control.

---

### Decision 10: Internationalization

**Resolved:** English-only for MVP. i18n architecture (resource files, locale-aware rendering) is built in from day one. No hard-coded UI strings.

**Impact:** All features defer to i18n framework even though MVP is English-only. Enables multi-language support without architectural rework later.

---

## Requirements Scope & Structure

**Date:** 2026-02-28  
**Author:** Brett (Requirements Analyst)  
**Status:** Proposed — needs team review  

### Decision

**Scope Boundaries:**
- Requirements cover only features explicitly mentioned or strongly implied in ProjectDescription.md
- Advanced features (e.g., analytics, email templates, API webhooks, speaker profiles) are intentionally out of scope for MVP
- Open questions flagged rather than assumed — 10 critical ambiguities need Chad/Dallas resolution

**Structure:**
- Personas defined first to establish user context
- Epics organized by user-facing capability (not by tech layer)
- User stories sized for sprint-level work (1-3 stories per feature, not individual tasks)
- Acceptance criteria written in Given/When/Then format for testability

**Output Format:**
- Single file: `.squad/requirements.md`
- Structured with headers, tables, and clear section breaks for readability
- No assumption of technical implementation in requirements (that's Dallas/Ripley/Lambert's domain)

### Rationale

- **Personas-first:** Ensures every story traces back to a real user need
- **Given/When/Then:** Makes requirements testable without interpretation; Kane can derive test cases directly
- **Flagged ambiguities:** Prevents premature decisions and surfaces them to Chad/Dallas for product-level resolution
- **Sprint-sized stories:** Balances granularity (not epics, not micro-tasks) for practical development workflow

### Impact

- Ripley, Lambert, Parker, Kane now have a single source of truth for "done" criteria
- Open questions may block some features until resolved — recommend prioritizing decisions for Epic 1 (CFP Discovery) and Epic 2 (Submission) first
- Requirements are living — expect refinement as team learns during development

---

## Requirements v3 Update — Data Model, Tracking States, International Standards

**Date:** 2026-02-28  
**Author:** Brett (Requirements Analyst)  
**Status:** Merged into requirements.md — guidance for implementation teams

---

### Summary

Requirements advanced from v2 → v3 with seven major improvements:

1. **CFP Data Model Expansion (Feature 2.1)** — 30+ fields in Event Details, CFP Details, Event Scheduling, Expense Coverage, Categorization
2. **Speaker Tracking Status Flow (Feature 1.3)** — 3-state tracking: Interested → Submitted → Accepted (replaced "favorites" terminology)
3. **Geographic Filters (Feature 1.2)** — UN M.49 world region, ISO 3166-1 country, ISO 3166-2 subdivision filters
4. **Organizer Edit Capability (Story 2.1.3)** — Organizers can edit Pending/Rejected submissions before admin approval
5. **Admin Reconsideration Flow (Stories 2.2.4, 2.2.5)** — Organizer requests re-review; admin sees "Reconsidering" badge
6. **Passkeys Evaluation Note (Epic 3)** — Architecture decision flagged for Dallas/Ripley (WebAuthn/FIDO2 vs. password)
7. **APIM Infrastructure Note (Epic 5)** — Architecture decision flagged for Dallas/Parker (Azure API Management fronting all APIs)

Feature count: 16 → 17

---

### Impact by Team

**Ripley (Backend):**
- Database schema expansion: 30+ new CFP fields
- ISO 3166-1/3166-2 country/subdivision validation
- IANA Time Zone Database validation
- UN M.49 world region auto-assignment via mapping table
- User-CFP tracking table: status column (Interested, Submitted, Accepted)
- Submission editing endpoint: status checks for Pending/Rejected (Reconsidering)
- Reconsideration request endpoint; moderation queue includes reconsidering submissions
- Decision needed: Passkeys (WebAuthn/FIDO2) vs. password-based auth
- Decision needed: APIM rate limiting + key management vs. app-level implementation

**Lambert (Frontend):**
- Submission form: all 30+ new fields organized by group
- Country/subdivision/time zone inputs with validation, searchable dropdowns
- Speaker tracking dashboard: 3-state status (Interested, Submitted, Accepted) with filtering
- "I've Submitted" and "I've Been Accepted" buttons
- Edit flow for Pending/Rejected submissions accessible via confirmation email
- "Request Reconsideration" button in rejection email and dashboard
- "Reconsidering" badge visibility in admin moderation queue

**Kane (Tester):**
- Test ISO 3166-1/3166-2 validation (valid codes accepted, invalid rejected)
- Test IANA time zone validation (canonical identifiers only)
- Test UN M.49 world region auto-assignment (e.g., US states → "Northern America")
- Test 3-state tracking transitions (Interested → Submitted → Accepted)
- Test edit flow for Pending/Rejected submissions; verify Approved submissions cannot be edited
- Test reconsideration flow end-to-end: rejection → request → edit → resubmit → admin re-review
- Test combined geographic filters (world region + country + subdivision)

**Dallas (Lead Developer):**
- Architectural decision: Passkeys (WebAuthn/FIDO2) as primary auth, or password + OAuth?
  - If passkeys: Azure AD B2C integration path available; Epic 3 stories will need AC updates
  - If password retained: Note serves as "considered but deferred" for future reference
- Architectural decision: Azure API Management (APIM) to front all APIs?
  - If yes: APIM handles rate limiting (100 req/min read, 10 req/min write), key management, versioning, developer portal, analytics
  - If no: App-level rate limiting/key management retained
  - Both decisions block Epic 3 and Epic 5 implementation respectively

**Parker (DevOps):**
- Conditional APIM provisioning: If APIM decision is "yes," provision APIM instance via Terraform
- APIM policies configured for rate limiting (read/write limits per Decision 3)
- APIM policies for API versioning (already decided: `/api/v1/`)

---

### Decisions Needed

| Decision | Owner | Impact | Urgency |
|----------|-------|--------|---------|
| Passkeys (WebAuthn/FIDO2) vs. password-based auth | Dallas, Ripley | Epic 3 (Account Registration) implementation | Blocks Epic 3 start |
| APIM to front all APIs vs. app-level management | Dallas, Parker | Epic 5 (Public API) + infrastructure setup | Blocks Epic 5 start |

---

### Traceability

All v3 changes marked in requirements.md with HTML comment: `<!-- Updated v3: [brief description] -->`

---

## Submitter/Organizer Distinction & Organizer Claim Flow

**Date:** 2026-02-28  
**Author:** Brett (Requirements Analyst)  
**Requested by:** Chad Green  
**Status:** Merged into requirements v3.1 — Feature 2.3 (Organizer Claim Flow)  

---

### Summary

Requirements v3.1 introduces a formal distinction between the person who submits a CFP listing to CFP Compass and the verified event organizer. Submitter is auto-captured at submission time; an "Are you the organizer?" checkbox controls whether the CFP enters normal moderation or "Unverified — Awaiting Organizer Claim" state. Organizers can claim listings via email verification, self-service claim button, or admin assignment.

---

### Key Decisions

1. **Submitter Auto-Captured** — Recorded as authenticated user or contact email; not a form field
2. **"Are You the Organizer?" Checkbox** — Default: Yes; if No, flags submission as community contribution
3. **Organizer Contact Email (Conditional)** — Optional field shown when organizer is not the submitter; used for claim invitation email
4. **Unverified Listings Visible But Flagged** — Published with status "Unverified — Awaiting Organizer Claim"
5. **Claim Verification Via Email** — Organizer identity verified by sending email to Organizer Contact Email or Speaker Support Email
6. **Admin-Assisted Claim Fallback** — Admins can manually assign organizer from dashboard; status becomes "Organizer Verified (Admin Assigned)"
7. **Community Contributor Credit Retained** — Original submitter acknowledged even after organizer claims the listing

---

### New Listing Statuses

- `Organizer Submitted` — Submitted by organizer themselves; normal moderation
- `Unverified — Awaiting Organizer Claim` — Submitted by community contributor; organizer not yet claimed
- `Organizer Verified` — Organizer completed self-service verification
- `Organizer Verified (Admin Assigned)` — Admin manually assigned organizer ownership

---

### Impact by Team

| Team | Impact |
|------|--------|
| **Ripley (Backend)** | New Submitter field; submission flag boolean; organizer contact email field; claim workflow endpoints; status transitions; claim invitation email trigger |
| **Lambert (Frontend)** | "Are you the organizer?" toggle on form; conditional Organizer Contact Email field; "Claim This Event" button on listing detail; claim confirmation flow |
| **Kane (Tester)** | Test submitter auto-capture; test community contributor path end-to-end; test claim invitation email; test admin-assisted claim; test status transitions |
| **Dallas (Lead)** | Review claim verification design; confirm status consistency with existing moderation states |
| **Parker (DevOps)** | ACS email template for claim invitation |

---

# CFP Taxonomy & Multi-Select Category/Topic Fields

**Date:** 2026-02-28  
**Author:** Brett (Requirements Analyst)  
**Requested by:** Chad Green  
**Status:** Merged into requirements v3.2  

---

## Summary

Requirements v3.2 introduces the full authoritative taxonomy for Event Category (Primary Domains) and Event Topics (Secondary Tags). Both fields are multi-select, with at least 1 Primary Domain required and 0+ Secondary Tags optional. Filters work against multi-value sets.

---

## Authoritative Taxonomy

### Primary Domains (Event Category — Multi-Select, 1+ Required)

Seeded from this list; admin-extensible (not free-text):

1. **Software Development & Engineering** — General programming, languages, frameworks, tooling, architecture, testing, DevOps
2. **Cloud & Infrastructure** — Cloud platforms, distributed systems, networking, SRE, observability, infrastructure automation
3. **Data, AI & Machine Learning** — Data engineering, analytics, ML/AI, LLMs, MLOps, data science
4. **Security & Privacy** — Application security, cloud security, governance, compliance, identity, threat detection
5. **Web, Mobile & Frontend** — Web technologies, frontend frameworks, UX/UI, mobile development
6. **DevOps, Platform Engineering & Automation** — CI/CD, platform teams, IaC, GitOps, automation, reliability
7. **Enterprise & Architecture** — Software architecture, system design, integration, enterprise platforms, modernization
8. **Open Source & Community** — OSS ecosystems, maintainership, community governance, tooling
9. **Product, Design & Innovation** — Product management, design systems, research, innovation practices
10. **Specialized Domains** — Niche or vertical-specific tech (e.g., fintech, health tech, IoT, robotics, gaming)

### Secondary Tags (Event Topics — Multi-Select, 0+ Optional)

Seeded from these tag groups; admin-extensible (not free-text):

- **Programming Languages** — .NET, Java, JavaScript/TypeScript, Python, Go, Rust, C++, etc.
- **Frameworks & Ecosystems** — React, Angular, Vue, ASP.NET Core, Spring, Django, Node.js, etc.
- **Cloud Providers** — Azure, AWS, GCP, multi-cloud, hybrid cloud
- **AI/ML Focus Areas** — LLMs, generative AI, MLOps, applied ML, AI ethics
- **Architecture Styles** — Event-driven, microservices, serverless, monolith modernization, domain-driven design
- **Infrastructure Practices** — IaC, Terraform, Kubernetes, containers, networking, observability
- **Security Topics** — AppSec, cloud security, identity, zero trust, red/blue/purple team
- **Data Topics** — Data engineering, warehousing, analytics, BI, streaming, databases
- **Developer Experience** — Tooling, productivity, documentation, testing, automation
- **Community & Career** — Speaking, leadership, mentoring, DEI, community building

---

## Multi-Select Field Behavior

### Event Category (Primary Domain)
- **Multi-select:** Organizers can select 1 or more categories
- **Required:** At least 1 category must be selected to submit
- **Use case:** A conference on Cloud + Security selects both "Cloud & Infrastructure" AND "Security & Privacy"
- **On listing:** All selected categories appear and are filterable

### Event Topics (Secondary Tags)
- **Multi-select:** Organizers can select 0 or more tags
- **Optional:** No tags required; no maximum limit — select all that apply
- **On listing:** All selected topics appear and are filterable

---

## Filter Behavior

**Multi-value set membership:**
- When a speaker filters by a Primary Domain or Secondary Tag, any CFP that includes that category/tag in its multi-value set is returned
- A CFP with multiple categories will appear in results for **any** of its selected categories (OR logic)
- Example: A CFP tagged with ["Cloud & Infrastructure", "Security & Privacy"] appears in results when filtering by Cloud OR Security

---

## Impact by Team

| Team | Impact |
|------|--------|
| **Ripley (Backend)** | Many-to-many relationships for categories and topics; seeded taxonomy data in migration; filter queries handle multi-value set membership (OR logic) |
| **Lambert (Frontend)** | Multi-select UI controls for both fields; validation enforces at least 1 category; filter UI supports multi-select with OR logic |
| **Kane (Tester)** | Test multi-select validation; test filter behavior with CFPs having multiple categories/topics; verify at least 1 category required, topics optional |
| **Dallas (Lead)** | Taxonomy is locked for MVP; admin extension mechanism can be deferred to post-MVP |

---

## Traceability

- **Feature 2.1 (Organizer Submission Form):** Categorization section replaced with full taxonomy; field descriptions updated to multi-select
- **Story 2.1.1 (Submit a New CFP):** ACs added for multi-select category/topic behavior and validation
- **Feature 1.1 (Public CFP Listing):** Description updated to note multi-value filtering
- **Feature 1.2 (Filtering & Sorting):** Description updated to note multi-value set behavior
- **Story 1.2.1 (Filter by Topic):** AC added for multi-value set membership filter logic

---

## User Directive — Architecture Revisions

**Date:** 2026-02-28T21:15  
**By:** Chad Green (via Copilot)

**Directive 1 — Redis: Do NOT use Azure Cache for Redis**
Azure Cache for Redis is being retired on September 30, 2028. Use Azure Managed Redis (preferred) or a self-hosted containerized Redis instance instead.

**Directive 2 — APIM: Use Developer tier for MVP**
Do not use Consumption tier. Use APIM Developer tier for MVP. Upgrade path: Developer → Standard V2 (when financially justified).

**Directive 3 — Event-driven architecture for writes**
POST and PUT operations should submit an event to Azure Service Bus. An Azure Function processes the message asynchronously. The API responds with HTTP 202 Accepted. Lean on APIM response caching for read (GET) endpoints to offset Azure SQL serverless cold-start impact.

**Why:** User request — captured for team memory.

---

## User Directive — Bot Protection Decision

**Date:** 2026-02-28T21:51  
**By:** Chad Green (via Copilot)
**What:** Bot protection for CFP Compass submission form: **Cloudflare Turnstile + Honeypot hybrid**. Turnstile provides invisible, privacy-first bot detection (GDPR-compliant, no Google dependency, free/unlimited). Honeypot adds a zero-cost passive layer. This is the final decision — closes open question Q2 from architecture.md.
**Why:** User decision after reviewing Dallas's full technical, privacy, and cost comparison document.

---

# Decision: Bot Protection — Cloudflare Turnstile + Honeypot

**Status:** Approved by Chad Green (2026-02-28)  
**Author:** Dallas (Lead)  
**ADR:** ADR-012  

## Summary

CFP Compass submission form security will use **Cloudflare Turnstile (primary) + hidden honeypot field (secondary)** as a layered bot protection strategy.

## Decision

**Cloudflare Turnstile + Honeypot hybrid.**

- **Primary:** Cloudflare Turnstile — invisible challenge, privacy-first, GDPR-compliant, free/unlimited, no Google dependency
- **Secondary:** Honeypot hidden form field — zero cost, zero external dependency, passive filter

## Rationale

- Turnstile is invisible to legitimate users (zero friction)
- Privacy-first: Cloudflare does not track users cross-site (no GDPR Article 26 DPA required for basic integration)
- Free tier: unlimited verifications at no cost
- No Google dependency (avoids reCAPTCHA GDPR concerns and VPN false positives)
- Honeypot adds a second passive layer with zero external dependency
- Combined score: 4.70/5.00 in weighted decision matrix (Effectiveness 25%, Privacy 20%, Cost 15%, Implementation 15%, UX 10%, Maintenance 10%, Vendor Risk 5%)
- Best fit for international tech community audience where GDPR compliance and developer privacy expectations matter

## Impact

- Closes open question Q2 in architecture.md
- Unblocks submission form implementation (Lambert) and API submission endpoint (Ripley)
- `Turnstile-SiteKey` and `Turnstile-SecretKey` added to Key Vault secrets list (Section 9)
- No cost impact; no cookie consent banner required
- Fallback: if Turnstile JS fails to load, honeypot still provides passive protection

---

# Architecture v2 Revisions — ADR Summaries

**Date:** 2026-03-01  
**Author:** Dallas (Lead & Architect)  
**Requested by:** Chad Green  
**Status:** Active — decisions finalized, integrated into `architecture.md` v2.0

---

## ADR-005 (Revised): Azure Managed Redis over Azure Cache for Redis

**Decision:** Azure Managed Redis (C0) as default distributed cache. Containerized Redis as documented fallback.

**Rationale:** Azure Cache for Redis is retiring September 30, 2028. Azure Managed Redis is Microsoft's replacement — built on Redis 7.x, same managed experience, no retirement risk. Containerized Redis (self-hosted as Container App) is a viable fallback with zero vendor lock-in and no additional Azure service cost, but adds operational responsibility.

**Impact:** Parker updates Terraform `redis/` module to provision Azure Managed Redis. Ripley — no code changes (connection string is the same pattern).

---

## ADR-006 (Revised): APIM Developer Tier

---

## Git Workflow — User Directive

**Date:** 2026-03-01T02:30:24Z  
**Author:** Chad Green (captured via Copilot)  
**Status:** Active — enforced as team policy

**Directive:** Never commit directly to main. All squad changes must go through a branch and pull request.

**Rationale:** Ensures code review, team visibility, and clean commit history. Prevents accidental breaks to main branch.

**Implementation:** All Scribe commits, Lead triages, and member work routes through feature/fix branches with pull requests.

---

## GitHub Projects v2 — Project Board Workflow Definition

**Date:** 2026-03-01  
**Author:** Dallas (Lead Architect)  
**Requested by:** Chad Green  
**Status:** Ready for Implementation

**What:** GitHub Projects v2 board defined with 6 workflow stages explicitly modeling the contract-first development approach:
- **Backlog** → Items not yet prioritized
- **Spec** → OpenAPI/AsyncAPI specification being authored
- **Spec Review** → Spec submitted, awaiting approval
- **In Progress** → Implementation underway (spec approved)
- **In Review** → PR open, awaiting code review
- **Done** → Merged and closed

**Why:** Contract-first workflow (ADR-014) is the defining characteristic of CFP Compass development. Every REST endpoint and Service Bus topic requires an approved specification before implementation. Explicit **Spec** and **Spec Review** columns make this gate visible in project tracking and prevent inadvertent implementation-before-spec workflows. User requested project board for team coordination.

**Board Definition:** See `.squad/project-board.md`

**Implementation:** Script and manual setup instructions provided in `project-board.md`. Non-interactive setup pending Chad/Dallas with gh CLI access.

**Status:** Ready for Chad Green to execute `scripts/create-project-board.ps1` with gh CLI authentication.

---

**Decision:** Azure API Management Developer tier for MVP. Upgrade path: Developer → Standard V2.

**Rationale:** Developer tier provides dedicated capacity (no cold start), VNet integration (internal mode), and built-in developer portal. Consumption tier's cold start (~1-2s) and lack of VNet were identified risks. Fixed cost (~$50/month) is justified by the capability gains.

**Risk note:** Developer tier is NOT suitable for high-availability production — no SLA beyond 99.9%, no zone redundancy. Upgrade to Standard V2 (not Premium) when traffic demands it.

**Impact:** Parker updates Terraform `apim/` module for Developer SKU + VNet config. Removes Consumption cold-start workarounds.

---

## ADR-007: Event-Driven Write Pattern (Service Bus + Azure Functions + 202 Accepted)

**Decision:** POST/PUT operations publish events to Azure Service Bus. API returns HTTP 202 Accepted. Azure Functions process writes asynchronously.

**Rationale:** Decouples API responsiveness from Azure SQL cold starts. Service Bus buffers events during DB wake-up. Dead-letter queues provide automatic failure handling. Independent scaling of read and write paths.

**Write path:** API → validate → publish to Service Bus topic → return 202 + Location header → Function subscribes → writes to SQL → updates status

**Impact:** Ripley implements Service Bus publishing in API controllers. New `CFPCompass.Functions` project for Service Bus processors. Status tracking table added to schema.

---

## ADR-008: Azure Service Bus Standard Tier

**Decision:** Service Bus Standard tier with topic-per-aggregate pattern.

**Rationale:** Topics + subscriptions enable fan-out (write → cache invalidation + notification). Dead-letter queues for failed messages. ~$10/month — cost-effective for MVP.

---

## ADR-009: HTTP 202 Accepted Response Pattern

**Decision:** Write endpoints return 202 Accepted with `Location` header pointing to status-check endpoint.

**Rationale:** Async consistency — callers poll `GET /api/v1/submissions/{id}/status` for processing state (Pending → Processing → Completed | Failed). Clear API contract for async operations.

---

## ADR-010: Multi-Select Taxonomy with Junction Tables

**Decision:** Many-to-many relationships via `CfpListingCategory` and `CfpTopic` junction tables. Both Category and Topic are multi-select on submission form.

**Rationale:** CFPs span multiple domains and topics. Richer filtering for speakers. 10 Primary Domains and 10 Secondary Tag groups seeded in DB migration; admin-extensible.

**Impact:** Ripley updates EF Core schema — removes `CategoryId` FK from `Cfp`, adds junction tables. Lambert updates submission form for multi-select. Kane tests junction table queries.

---

## ADR-011: APIM Response Caching for Read Path

**Decision:** APIM response caching on public GET endpoints. TTL: 5 minutes (listings), 1 minute (detail). Cache invalidation via Service Bus events.

**Rationale:** Offsets Azure SQL serverless cold starts for read operations. Reduces SQL load. Event-driven invalidation ensures data freshness within minutes.

---

## Resolved Open Questions

| Question | Answer | Impact |
|----------|--------|--------|
| Q1: Production domain | `cfpcompass.com` | CORS, APIM custom domain, ACS sender domain, Front Door |
| Q2: Bot protection | Cloudflare Turnstile + Honeypot (ADR-012) | Submission form implementation unblocked |
| Q3: Taxonomy | Full taxonomy seeded (10 Primary Domains, 10 Secondary Tag groups); multi-select; admin-extensible | DB migration, submission form, filter queries |
| Q4: Email sender | `noreply@cfpcompass.com` | ACS domain verification, email templates |

---

# ADR-013: .NET Aspire 13.1 for Orchestration and Observability

**Status:** Accepted  
**Date:** 2026-03-01  
**Author:** Dallas (Lead & Architect)  
**Requested by:** Chad Green  

## Decision

Adopt .NET Aspire 13.1 for local development orchestration (AppHost), shared observability baseline (ServiceDefaults), and Azure integration packages.

## Summary

- Solution expanded from 7 to 9 projects: added `CfpCompass.AppHost` and `CfpCompass.ServiceDefaults`
- AppHost orchestrates all services/containers for local dev — single `dotnet run` entry point
- ServiceDefaults provides consistent OpenTelemetry (traces, metrics, logs), health checks (`/health`, `/alive`), and resilience (Polly) across all service projects
- Aspire Dashboard at `https://localhost:18888` for distributed tracing and log correlation during development
- Aspire integration packages (`Aspire.Azure.*`) replace manual SDK configuration for Redis, Service Bus, and SQL
- Production: AppHost is NOT deployed; OpenTelemetry exports to Azure Monitor / Application Insights (config-only switch)
- Production hosting remains Azure Container Apps + Terraform (unchanged)
- Aspire 13.1 targets .NET 10 — version-aligned with project stack
- Developers need: `dotnet workload install aspire`

## Impact

| Team | Impact |
|------|--------|
| **Ripley (Backend)** | All service projects must call `builder.AddServiceDefaults()` at startup; Aspire integration packages replace manual connection string wiring for Redis, Service Bus, SQL |
| **Lambert (Frontend)** | Web project calls `AddServiceDefaults()` — gains health checks and OpenTelemetry automatically |
| **Parker (DevOps)** | AppHost excluded from CI/CD and production Docker builds; `dotnet workload install aspire` added to dev setup docs |
| **Kane (Tester)** | Integration tests can leverage Aspire's test host for multi-service scenarios |
| **All** | Enforce `AddServiceDefaults()` in all service projects via PR review |

## Architecture Changes

- `architecture.md` v3.0: New sections 10 (Observability) and 11 (Local Development); ADR-013 in Section 14; sections renumbered

---

# Non-Functional Requirements — Observability & Developer Experience

**Status:** Integrated into requirements.md v3.3  
**Date:** 2026-03-01  
**Author:** Brett (Requirements Analyst)  
**Cross-reference:** ADR-013, architecture.md v3.0 §10–11

## NFR-1: Observability

**Requirement:** CFP Compass must emit structured logs, distributed traces, and custom metrics to a centralized observability platform.

**Details:**
- All service projects produce structured JSON logs (Serilog)
- Distributed tracing via OpenTelemetry; correlation IDs propagate across service boundaries
- Custom metrics for CFP submission latency, API request rates, authentication failures
- Azure Monitor / Application Insights receives traces, metrics, and logs from production
- Health check endpoints (`GET /health` detail, `GET /alive` liveness) on all services
- Aspire Dashboard (`https://localhost:18888`) displays traces/logs during development

**Rationale:** Multi-service architecture (AppHost + ServiceDefaults + 8 service projects) requires end-to-end observability to diagnose issues. Development team needs local tracing; operations team needs production telemetry.

**Impact:**
- **Ripley:** Health checks + OpenTelemetry automatic via ServiceDefaults; custom metrics added to critical paths
- **Lambert:** Health checks + OTel automatic via ServiceDefaults
- **Parker:** Azure Monitor pricing; no setup cost for OTel export (built into Azure Container Apps)
- **Kane:** Test health check endpoints; validate trace propagation in integration tests

---

## NFR-2: Developer Experience

**Requirement:** CFP Compass development environment must launch all services with a single command.

**Details:**
- `dotnet run` in AppHost directory orchestrates all services/containers
- Aspire Dashboard automatically opens at `https://localhost:18888` showing service status, logs, traces
- No manual port mapping or environment variable configuration for local dev
- `dotnet workload install aspire` one-time setup documented in README
- Development mode config (no TLS, relaxed CORS) auto-applied

**Rationale:** Multi-service local dev (7–9 projects) requires coordination. Aspire AppHost eliminates boilerplate; single entry point is a huge UX improvement for onboarding and daily development. Reduces cognitive load and context switching.

**Impact:**
- **All:** Faster onboarding; reduced setup friction
- **Parker:** Dev setup docs simplified; workload installation is a single line
- **Kane:** Simpler test environment orchestration via Aspire test host
- **Dallas/Ripley/Lambert:** Faster iteration cycle (start once, all services ready)

---

# ADR-014: Contract-First API and Event Design

**Status:** Accepted  
**Date:** 2026-03-01  
**Author:** Dallas (Lead & Architect)  
**Requested by:** Chad Green

## Summary

All REST API endpoints and all Azure Service Bus topics must have an **approved specification before implementation begins**.

- REST APIs → **OpenAPI 3.1** spec in `docs/api/openapi/`
- Service Bus topics → **AsyncAPI 3.0.0** spec in `docs/api/asyncapi/`

Approval gate: spec PR merged → implementation PR opened. No exceptions.

## Context

CFP Compass exposes a public REST API (consumed by the Blazor web app and potentially third-party integrators) and an event-driven backend via Azure Service Bus. Without a contract-first discipline, APIs and events evolve organically, leading to undocumented breaking changes, mismatched producer/consumer expectations, and difficulty onboarding new consumers.

## Decision

**Contract-first / design-first discipline is mandatory for all API and event work.**

1. OpenAPI 3.1 spec approved → REST endpoint implementation begins
2. AsyncAPI 3.0.0 spec approved → Service Bus producer/consumer implementation begins

## Spec Locations

```
docs/
  api/
    openapi/
      cfp-compass-api-v1.yaml        # REST API spec (OpenAPI 3.1)
      README.md                       # Approval workflow notes
    asyncapi/
      cfp-submissions.asyncapi.yaml  # Submission lifecycle events
      organizer-claims.asyncapi.yaml # Organizer claim events
      README.md                       # Approval workflow notes
```

## Known Topics Requiring AsyncAPI Specs

| Topic | Description |
|-------|-------------|
| `cfp-submission-created` | New CFP submission submitted via API |
| `cfp-submission-updated` | Organizer edited a pending submission |
| `cfp-submission-approved` | Admin approved/published a submission |
| `cfp-submission-rejected` | Admin rejected a submission |
| `cfp-submission-reconsideration` | Organizer requested reconsideration after rejection |
| `organizer-claim-requested` | Someone requested to claim an unverified listing |

## Tooling

| Tool | Purpose |
|------|---------|
| **Spectral** (`spectral:oas`) | OpenAPI spec linting |
| **AsyncAPI CLI** (`asyncapi validate`) | AsyncAPI spec validation |
| **oasdiff** | Breaking-change detection between OpenAPI versions |
| **Scalar / Swashbuckle** | Developer-facing spec serving (not canonical) |
| **AsyncAPI Studio** | AsyncAPI spec authoring |

## CI Enforcement

- GitHub Actions validates OpenAPI specs with Spectral on every PR touching `docs/api/openapi/`
- GitHub Actions validates AsyncAPI specs with AsyncAPI CLI on every PR touching `docs/api/asyncapi/`
- Implementation PRs touching API routes or Service Bus producers/consumers must reference the approved spec PR

---

## Blob Storage Access via Managed Identity

**Date:** 2026-03-01  
**Authors:** Ripley (Backend), Parker (Infrastructure)  
**Issue:** #1  
**Branch:** `squad/1-blob-storage-managed-identity`  
**PR:** https://github.com/TaleLearnCode/CFPCompass-squad/pull/4  
**Status:** Proposed — awaiting PR merge and Dallas architecture review

### Decision

Azure Blob Storage is accessed exclusively via Managed Identity (DefaultAzureCredential). No SAS tokens or connection strings in application code.

### Implementation Pattern

**Infrastructure (Parker):**
- Terraform module `blob-storage-rbac` assigns `Storage Blob Data Contributor` RBAC role to all three Container Apps (Api, Web, Workers) via Managed Identity
- Role assignments use `uuidv5` for deterministic naming, preventing Terraform drift
- Updated `docs/infrastructure/architecture.md` with Managed Identity wiring table and SAS→RBAC migration note

**Application (Ripley):**
- `BlobServiceClient` registered through .NET Aspire's `AddAzureBlobServiceClient("blobs")` extension
- `BlobStorageService` receives injected client via constructor — no credential instantiation in code
- Local development uses Azurite emulator with `RunAsEmulator()` in AppHost
- Azure environments (staging, production) use system-assigned Managed Identity with RBAC assigned by Parker's Terraform

### Files Created

**Infrastructure (Terraform):**
- `infrastructure/terraform/modules/blob-storage-rbac/main.tf`
- `infrastructure/terraform/modules/blob-storage-rbac/variables.tf`
- `infrastructure/terraform/modules/blob-storage-rbac/outputs.tf`
- `infrastructure/terraform/modules/blob-storage-rbac/README.md`
- `infrastructure/terraform/environments/dev/blob-storage-rbac.tf`

**Application (.NET):**
- `src/CfpCompass.Api/Services/IBlobStorageService.cs`
- `src/CfpCompass.Api/Services/BlobStorageService.cs`
- `src/CfpCompass.Api/Extensions/BlobStorageExtensions.cs`
- `src/CfpCompass.Api/Program.cs`
- `src/CfpCompass.Api/CfpCompass.Api.csproj`
- `src/CfpCompass.AppHost/Program.cs`
- `src/CfpCompass.AppHost/CfpCompass.AppHost.csproj`

---

## Blob Storage — Managed Identity (Issue #1) — Final Decision

**Date:** 2026-03-01  
**Author:** Parker (DevOps)  
**Status:** Adopted  
**Issue:** #1

### Summary

Azure Blob Storage in CFP Compass will use **Azure RBAC with Managed Identity** for all service access. SAS tokens and storage connection strings are prohibited.

### Decision

**Adopted:** `Storage Blob Data Contributor` and `Storage Blob Data Reader` RBAC roles are assigned to Container App and Azure Functions managed identities. No SAS tokens. No `Storage-ConnectionString` in Key Vault.

### Role Assignments

| Service | Role | Justification |
|---------|------|--------------|
| Container App (API) | `Storage Blob Data Contributor` | Uploads event logos via organizer submission |
| Container App (Web) | `Storage Blob Data Reader` | Reads blobs to serve event logo images |
| Azure Functions | `Storage Blob Data Contributor` | Processes uploaded blobs (validation/transformation) |
| Container Apps Jobs | _(none at MVP)_ | No blob interaction in scheduled job design |

### What Changes

**Infrastructure (Parker)**
- Add `azurerm_role_assignment` resources in `infra/modules/storage/` for each identity above
- Remove `Storage-ConnectionString` from Key Vault provisioning
- Add `Storage:AccountName` as a non-secret value in Azure App Configuration (per-environment label)

**Application (Ripley — required before staging)**
- Replace `new BlobServiceClient(connectionString)` with:
  ```csharp
  new BlobServiceClient(
      new Uri($"https://{accountName}.blob.core.windows.net"),
      new DefaultAzureCredential())
  ```
- Source `accountName` from App Configuration (not Key Vault)

### Documentation Updates

- `docs/infrastructure/overview.md` — Network diagram, Identity & Access Model table, Key Vault secret inventory
- `docs/infrastructure/architecture.md` — Managed Identity Wiring table (corrected roles: Web=Reader, API/Functions=Contributor, Jobs=none)
- `.squad/agents/parker/blob-storage-mi-plan.md` — Full Terraform planning document with HCL blocks

### Rationale

SAS tokens are time-bounded credentials that must be rotated, stored as secrets, and distributed to services. Managed Identity eliminates this entire surface area: no credential storage, no rotation, no expiry, full Azure AD audit trail.

### Cross-Agent Actions Required

- **Ripley:** Update `BlobServiceClient` registration to use `DefaultAzureCredential` + account URI via Aspire's `AddAzureStorageBlobs()`. Implement `IBlobStorageService` interface per application plan.
- **Dallas:** ADR-013 (Aspire packages) must include `Aspire.Hosting.Azure.Storage` in AppHost dependencies.
- **Kane:** Integration test plan for blob upload/download/delete once source exists.
- `src/CfpCompass.ServiceDefaults/Extensions.cs`
- `src/CfpCompass.ServiceDefaults/CfpCompass.ServiceDefaults.csproj`

### Rationale

- No secrets in code or app settings — eliminates credential leak risk
- SAS token rotation is operational burden that MI eliminates
- DefaultAzureCredential works transparently across local, CI, and cloud without code changes
- Aspire resource model makes Azurite ↔ real storage swap seamless across environments
- Forward-compatible: all three Container Apps get write permission despite current read-only patterns (prevents second RBAC change if write requirements emerge)

### Open Item

Project naming uses `CfpCompass.{Layer}` per issue spec, but architecture doc uses `CFPCompass.{Layer}`. Dallas or Chad should confirm canonical casing before remaining projects are scaffolded.

## Consequences

- Every new API endpoint requires a spec PR before implementation
- Every new Service Bus topic requires an AsyncAPI spec PR before implementation
- Design review happens at the spec level (before code is written), not the code review level
- APIM imports the OpenAPI spec directly — contract and gateway enforcement stay in sync
- Breaking change detection (oasdiff) is meaningful because the spec is the source of truth

## Alternatives Rejected

- **Code-first with auto-generated specs:** Auto-generated specs are documentation, not contracts; cannot be reviewed as design artifacts
- **OpenAPI only (no AsyncAPI):** Service Bus events are as much a public contract as REST endpoints; undocumented event schemas cause producer/consumer mismatches

## Impact by Team

| Team | Impact |
|------|--------|
| **Dallas (Lead)** | All new API and event work requires spec PR first; no implementation without approved spec |
| **Ripley (Backend)** | API endpoint implementation must conform to approved OpenAPI spec; Service Bus producer implementation must conform to approved AsyncAPI spec |
| **Lambert (Frontend)** | API consumer code generation and integration must use approved OpenAPI specs |
| **Parker (DevOps)** | API contract documentation and versioning tracking; Spectral + AsyncAPI CLI added to CI pipeline |
| **Chad (Product)** | Contract-first process now part of team workflow — protects against mid-project API breaking changes |

---


---

# 2026-03-01 Batch: App Config Decision Revised, ADR-015, MI Gaps

## Q2: Managed Identities — Are We Using Them Everywhere?

## Q2: Managed Identities — Are We Using Them Everywhere?

### Decision: Mostly yes, with three documented gaps to close.

The strong cases are already covered correctly:
- **Key Vault**: All four services (Web, API, Jobs, Functions) access Key Vault via system-assigned managed identity. ✅
- **Service Bus**: API uses MI as `Azure Service Bus Data Sender`; Functions uses MI as `Azure Service Bus Data Receiver`. ✅
- **ACR pull**: Container Apps (API) uses MI for image pull. ✅
- **Azure SQL (Jobs + Functions)**: Both already granted `db_datareader`/`db_datawriter` RBAC on the SQL database via managed identity — Entra token auth. ✅

**Three gaps to close:**

### Gap 1: Azure SQL — Web and API Container Apps (HIGH priority)
The current architecture has `AzureSql-ConnectionString` in Key Vault, accessed by the Web and API Container Apps. This means those services use SQL Server authentication credentials, not Entra-based MI auth, for the actual database connection. This is inconsistent with Jobs and Functions (which correctly use MI for SQL).

**Fix:** Add `db_datareader` + `db_datawriter` RBAC grants to the Web and API system-assigned managed identities in Terraform (`identity/` + `sql/` modules). Update the connection string in Key Vault to use `Authentication=Active Directory Managed Identity;` (or use `DefaultAzureCredential` in the EF Core SQL provider). Remove `AzureSql-ConnectionString` from Key Vault once all four services are on MI auth.

### Gap 2: Azure Blob Storage — SAS tokens (MEDIUM priority)
Blob Storage currently uses SAS tokens. SAS tokens have a fixed expiry, require rotation management, and represent a shared-credential risk if leaked.

**Fix:** Assign `Storage Blob Data Contributor` RBAC to the relevant managed identities (Jobs writes blob data; API and Web read it). Use `DefaultAzureCredential` via the Aspire `Aspire.Azure.Storage.Blobs` integration package. Remove SAS token generation from the application.

### Gap 3: Azure Communication Services (LOW priority)
ACS is accessed via connection string from Key Vault. ACS does support `ManagedIdentityCredential` via the Azure.Communication.Email SDK.

**Fix:** Assign the `Contributor` role (or the ACS-specific sender role) to the relevant managed identities on the ACS resource. Switch from `EmailClient(connectionString)` to `EmailClient(endpoint, new ManagedIdentityCredential())`. Remove `ACS-ConnectionString` from Key Vault.

**One accepted exception:**
- **Azure Managed Redis (access key auth)**: Azure Managed Redis does support Entra-based auth, but StackExchange.Redis (the client library behind Aspire's Redis integration) has incomplete support for token-refresh lifecycle management. Staying on access key from Key Vault is the pragmatic call for MVP. Revisit when StackExchange.Redis Entra support matures.

**Summary of MI coverage after gaps are closed:**

| Connection | Auth Method | Status |
|-----------|------------|--------|
| Container Apps → Key Vault | Managed Identity | ✅ Done |
| Container Apps → Service Bus | Managed Identity | ✅ Done |
| Container Apps → ACR | Managed Identity | ✅ Done |
| Container Apps → Azure SQL | Managed Identity | ⚠️ Gap 1 (Web + API) |
| Container Apps → Blob Storage | Managed Identity | ⚠️ Gap 2 |
| Container Apps → ACS | Managed Identity | ⚠️ Gap 3 |
| Container Apps → Redis | Access key from KV | ✅ Accepted exception |

---

---

# Decision: Remove /api/ Route Prefix (ADR-015)

# Decision: Remove /api/ Route Prefix (ADR-015)

**Date:** 2026-02-28
**Author:** Dallas (Lead & Architect)
**Confirmed by:** Chad Green
**Status:** Accepted
**Formal ADR:** `docs/registers/decisions/ADR-015-remove-api-route-prefix.md`

---

## Summary

Remove the `/api/` prefix from all ASP.NET Core API routes in `CFPCompass.Api`. Routes become `/v1/cfps`, `/v1/topics`, etc. instead of `/api/v1/cfps`, `/api/v1/topics`.

## Rationale

The `/api/` prefix disambiguates API routes from page routes on a shared host. `CFPCompass.Api` is a dedicated container with no page routes — disambiguation is unnecessary. APIM is the sole public ingress, and the OpenAPI spec drives APIM import automatically. Clean URLs with no noise.

## Exception

Azure Functions `HealthCheckFunction` keeps `GET /api/health` — that's a Functions host runtime convention, not an application route. Container Apps probes target this path.

## Timing

Decision made before implementation. Renaming after controllers, specs, and APIM policies are written would be significantly more disruptive.

## What Changes

- All controller route attributes: `[Route("v1/...")]` — no `/api/` prefix
- Canonical OpenAPI spec paths: `/v1/*`
- Architecture documentation route tables: `/v1/*`
- APIM: imports spec directly, no manual path config needed

## What Does NOT Change

- Azure Functions health check: `GET /api/health`
- Versioning scheme: `/v1/` retained
- APIM product/rate-limit/subscription-key policies: unaffected


---

# Revised Decision: Adopt Azure App Configuration

# Revised Decision: Adopt Azure App Configuration

**Date:** 2026-03-02
**Author:** Dallas (Lead & Architect)
**Requested by:** Chad Green
**Status:** Accepted — supersedes previous rejection
**Supersedes:** Q1 in `dallas-arch-review-config-identity-routes.md`

---

## Background

In the initial arch review (2026-03-02), I recommended against Azure App Configuration, stating that Container Apps environment variables + Key Vault references were sufficient and that App Configuration "only earns its place for dynamic feature flags." Chad Green challenged that position with four counter-arguments. After consideration, I'm revising my position. Chad is right — the original recommendation undervalued the operational benefits of centralized configuration management.

---

## Revised Decision: Adopt Azure App Configuration

Azure App Configuration is adopted as the **central configuration surface** for all CFP Compass services across all environments.

### What Goes Where

| Store | What Lives There | Access Pattern |
|-------|-----------------|----------------|
| **Azure App Configuration** | All non-sensitive configuration values: log levels, APIM base URLs, job schedules, pagination defaults, email sender addresses, external service endpoints. All feature flags. Key Vault references for secrets. | Single SDK call via `Microsoft.Extensions.Configuration.AzureAppConfiguration` — one retrieval pattern for everything |
| **Azure Key Vault** | All secrets: connection strings, OAuth client secrets, JWT signing keys, Turnstile keys, admin email list | Surfaced through App Configuration Key Vault references — code never calls Key Vault SDK directly |
| **Container Apps env vars** | Only Aspire/runtime bootstrapping values needed before App Configuration connection is established (e.g., the App Configuration endpoint itself) | Terraform-managed, minimal set |

**Key architectural benefit:** One SDK, one pattern. Sensitive and non-sensitive values are both resolved through App Configuration. Key Vault references keep secrets in Key Vault (proper access policies, audit logging, rotation support) while presenting them through the same configuration pipeline. No dual-path code — `IConfiguration["SomeKey"]` works identically whether the backing value is a plain string in App Configuration or a Key Vault reference.

### Feature Flags

Feature flags are managed through App Configuration's built-in feature management construct (`Microsoft.FeatureManagement`). This directly supports CFP Compass's trunk-based development model:

- **Trunk-based development:** All work merges to `main`. Incomplete or risky features ship behind feature flags. Flags are toggled in App Configuration without redeployment.
- **Flag lifecycle:** Active → Dormant → Deprecated. All states visible in the App Configuration portal at a glance.
- **Flag evaluation:** `IFeatureManager.IsEnabledAsync("FeatureName")` in application code. Conditional middleware, controller filters, and Blazor component rendering all supported.
- **No custom flag infrastructure required.** App Configuration's feature flag construct is purpose-built — no need to invent our own toggle table or JSON config.

### Environment Labeling Strategy

App Configuration uses **labels** to separate per-environment configuration. One App Configuration instance, multiple labeled key sets:

| Label | Environment | Applied When |
|-------|------------|--------------|
| `dev` | Development | Auto-deployed on merge to `main` |
| `staging` | Staging / UAT | Pre-production validation |
| `prod` | Production | Manual-approval gated release |

**How it works:**
- Keys are stored with environment-specific labels: `Logging:LogLevel:Default` with label `dev` = `Debug`, label `prod` = `Information`.
- Each Container App's startup configuration specifies which label to load: `.Select(KeyFilter.Any, "prod")`.
- Feature flags follow the same labeling — a flag can be active in `dev` and `staging` but inactive in `prod`.
- No Terraform duplication for per-environment values — one App Configuration resource, labeled keys managed via Terraform `azurerm_app_configuration_key` resources.

### Terraform Implications

- **New resource:** `azurerm_app_configuration` provisioned in the `infra/modules/appconfig/` Terraform module (one instance per subscription, shared across environments via labels).
- **Per-environment keys:** `azurerm_app_configuration_key` resources with label parameter matching the environment.
- **Key Vault references:** `azurerm_app_configuration_key` with `type = "vault"` and `vault_key_reference` pointing to Key Vault secret URIs.
- **Managed Identity access:** Each Container App's system-assigned MI granted `App Configuration Data Reader` RBAC role.
- **Feature flags:** `azurerm_app_configuration_feature` resources for flag definitions.
- **Estimated cost:** Azure App Configuration Free tier supports up to 10K requests/day — sufficient for MVP. Standard tier (~$1.20/day) if request volume exceeds free tier.

### Previous Guardrail Removed

The planned "no App Configuration in MVP" guardrail (which was to be added to `non-goals-and-guardrails.md`) is **cancelled**. App Configuration is an adopted, provisioned resource.

---

## Why the Original Position Was Wrong

1. **Feature flags are not speculative — they're essential for trunk-based development.** The original position treated feature flags as a future maybe. With trunk-based development confirmed as CFP Compass's branching model, feature flags are a day-one operational requirement, not a nice-to-have.

2. **Central configuration management is operational hygiene, not luxury.** Hunting through Container Apps environment variable panels across three environments to reason about system state is operationally painful. App Configuration provides a single pane of glass for all configuration across all environments.

3. **Single retrieval pattern eliminates dual-path complexity.** The original approach required two patterns: env vars for non-sensitive + Key Vault SDK for sensitive. App Configuration Key Vault references collapse this into one pattern. Less code, fewer bugs, simpler onboarding.

4. **Environment labeling is cleaner than per-environment Terraform variable duplication.** Instead of maintaining parallel `terraform.tfvars` files with every config value duplicated per environment, labels in App Configuration provide native multi-environment support.

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| App Configuration outage | LOW | SDK has built-in caching with configurable refresh interval; cached values serve requests during outage |
| Cost overrun | LOW | Free tier covers MVP; Standard tier is ~$36/month — trivial relative to APIM ($50) |
| Added dependency | LOW | One additional Azure service, but replaces the complexity of dual-path config management |
| Bootstrap chicken-and-egg | LOW | App Configuration endpoint is the one env var set on Container Apps; everything else loads from App Config |

---

## Action Items

| Item | Owner | Priority |
|------|-------|----------|
| Create `infra/modules/appconfig/` Terraform module | Parker | HIGH |
| Add `AddAzureAppConfiguration()` to ServiceDefaults | Ripley | HIGH |
| Migrate non-sensitive env vars to App Configuration keys | Parker | MEDIUM |
| Create Key Vault references in App Configuration | Parker | MEDIUM |
| Define initial feature flag set for trunk-based dev | Dallas | MEDIUM |
| Update `docs/infrastructure/overview.md` with App Config | Dallas | Done |
| Remove planned no-App-Config guardrail from docs | Dallas | Done (was never added) |


---

# Parker — Managed Identity Gap Work Items Created

# Parker — Managed Identity Gap Work Items Created

**Date:** 2026-02-28  
**Author:** Parker (DevOps)  
**Status:** Complete  

---

## Summary

Architecture review identified three Managed Identity inconsistencies across our Azure services. Created three GitHub issues to address credential management gaps:

| Issue | Priority | Link | Problem | Fix Category |
|-------|----------|------|---------|--------------|
| #2 | HIGH | [Azure SQL: Web + API MI](https://github.com/TaleLearnCode/CFPCompass-squad/issues/2) | Web/API use Key Vault secrets; Jobs/Functions use MI | Passwordless SQL auth |
| #1 | MEDIUM | [Blob Storage: Replace SAS](https://github.com/TaleLearnCode/CFPCompass-squad/issues/1) | SAS tokens expire & leak-prone | Credential rotation |
| #3 | LOW | [ACS Email: Use MI](https://github.com/TaleLearnCode/CFPCompass-squad/issues/3) | Connection string in Key Vault | Passwordless ACS access |

---

## Implementation Roadmap

### Phase 1 — SQL (HIGH)
1. Terraform: Add MI RBAC roles (db_datareader, db_datawriter) to Web + API Container Apps
2. EF Core: Update connection string pattern to use Active Directory Managed Identity
3. Verification: Test across dev, staging, prod
4. Cleanup: Remove AzureSql-ConnectionString from Key Vault

### Phase 2 — Blob Storage (MEDIUM)
1. Terraform: Identify affected Container Apps; assign Storage Blob Data Contributor role
2. Dependencies: Requires Aspire Azure Storage Blobs integration package adoption
3. Code: Refactor to DefaultAzureCredential; remove SAS token generation
4. Testing: All blob operations across environments

### Phase 3 — ACS Email (LOW)
1. Terraform: Assign ACS Email sender role to email-sending Container App
2. SDK: Update email client factory to use ManagedIdentityCredential
3. Validation: Email delivery across environments
4. Cleanup: Remove ACS-ConnectionString from Key Vault

---

## Next Steps

- **Ripley/Dallas:** Review SQL and ACS email issues for application-level implications
- **Parker:** Begin Phase 1 (SQL) as highest security priority; coordinate Terraform + secret rotation
- **Chad Green:** Confirm email sender domain (ACS issue #3) before MI assignment

---

## Labels Applied

All three issues labeled with:
- `infrastructure` — Infrastructure/deployment track
- `security` — Security & credential management
- `managed-identity` — Managed Identity authentication pattern

Labels created via GitHub API where missing.


---

# API Route Prefix Documentation Update

---
title: API Route Prefix Documentation Update
author: Ash (Technical Writer)
date: 2024-01-15
related_adr: ADR-015
status: completed
---

# API Route Prefix Documentation Update

## Summary

Updated all documentation in the `/docs` folder to reflect the route prefix change from `/api/v1/` to `/v1/` as specified in ADR-015. This change removes the redundant `/api/` prefix from application API routes while preserving it for Azure Functions runtime endpoints (e.g., `GET /api/health`).

## Files Updated

### API Contract Documents (`docs/contracts/apis/`)

| File | Replacements |
|------|--------------|
| `cfps.md` | 27 |
| `submissions.md` | 38 |
| `account.md` | 29 |
| `metadata.md` | 20 |
| `claims.md` | 18 |
| `admin.md` | 24 |
| `README.md` | 40 |
| **Subtotal** | **196** |

### Architecture Documents (`docs/architecture/`)

| File | Replacements |
|------|--------------|
| `architecture-specifications.md` | 8 |
| `system-context-and-logical-components.md` | 14 |
| **Subtotal** | **22** |

### Process Flow Documents (`docs/process-flows/`)

| File | Replacements |
|------|--------------|
| `cfp-submission.md` | 15 |
| `cfp-moderation.md` | 12 |
| `api-write-pattern.md` | 14 |
| `organizer-claim.md` | 14 |
| **Subtotal** | **55** |

### Architecture Guide

| File | Replacements |
|------|--------------|
| `architecture-guide.md` | 1 |

## Total Replacements

**276 route references** updated across **14 documentation files** (274 via bulk replacement + 2 manual edits in cfps.md).

## Changes Made

### What Changed
- All application API route references: `/api/v1/...` → `/v1/...`
- Examples updated in contract documents, sequence diagrams, and code samples
- APIM routing examples updated in architecture specifications

### What Did NOT Change
- Azure Functions health check endpoints remain as `/api/health` (Azure Functions host convention)
- HttpTrigger route examples in code snippets remain unchanged where they demonstrate Functions-specific routing
- Frontmatter metadata in all documentation files remains intact and unmodified

## Validation

All replacements were validated to ensure:
1. No `/api/health` endpoints were modified
2. No Azure Functions HttpTrigger routes in code examples were altered
3. Frontmatter metadata blocks remain intact
4. All endpoint paths follow the new `/v1/...` convention consistently

## Related Work

This documentation update supports the implementation work tracked in ADR-015, which establishes the route prefix change across the API application layer.

---

**Completed by:** Ash  
**Date:** 2024-01-15

