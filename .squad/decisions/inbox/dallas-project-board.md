## 2026-03-01: Project board workflow stages defined

**By:** Chad Green (via Dallas, Lead Architect)

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
