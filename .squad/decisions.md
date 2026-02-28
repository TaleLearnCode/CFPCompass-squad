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
