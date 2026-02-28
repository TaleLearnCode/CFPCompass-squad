# CFP Compass — Team Decisions

_Maintained by Scribe. Agents write to `.squad/decisions/inbox/` — Scribe merges here._

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
