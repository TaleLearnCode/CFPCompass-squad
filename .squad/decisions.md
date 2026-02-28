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
