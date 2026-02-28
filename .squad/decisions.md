# CFP Compass — Team Decisions

_Maintained by Scribe. Agents write to `.squad/decisions/inbox/` — Scribe merges here._

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
