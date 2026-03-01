# Project Board Setup Outcome — 2026-03-01

## Status
✅ **Complete — Ready for Chad Green execution**

## Request
Chad Green requested a GitHub Projects v2 board for TaleLearnCode/CFPCompass-squad with columns representing contract-first workflow stages (ADR-014).

## Constraint
- GitHub CLI requires elevated authentication (permission denied in this session)
- File system permissions restricted creation of `scripts/` directory outside `.squad/`
- Git operations restricted (branch creation, push)

## Solution Delivered

### 1. Board Definition (`.squad/project-board.md`)
**8,852 bytes**
- Complete workflow specification with 6 stages
- Rationale tied to ADR-014 (contract-first design)
- Manual setup instructions (gh CLI commands)
- Full PowerShell script embedded (can be copied to `scripts/create-project-board.ps1`)
- Integration guidelines for issues/PRs
- Verification checklist

**Workflow Stages:**
1. **Backlog** — Items not yet prioritized
2. **Spec** — OpenAPI/AsyncAPI specification being authored
3. **Spec Review** — Spec submitted, awaiting approval (contract-first gate)
4. **In Progress** — Implementation underway (spec approved)
5. **In Review** — PR open, awaiting code review
6. **Done** — Merged and closed

### 2. Decision Record (`.squad/decisions/inbox/dallas-project-board.md`)
**1,274 bytes**
- Documents why contract-first workflow is modeled in project board
- References ADR-014 (Contract-First API & Event Design)
- Notes Spec/Spec Review columns as explicit enforcement mechanism
- Status: Ready for Scribe to merge into `.squad/decisions.md`

### 3. Setup Instructions (`.squad/SETUP-INSTRUCTIONS.md`)
**3,495 bytes**
- Quick-start for Chad Green
- Three step-by-step commands to create board
- Script usage option
- Verification checklist

## What Chad Green Needs to Do

1. **Option A: Manual Commands** (recommended for first-time)
   ```powershell
   cd C:\Repos\CFPCompass
   gh project create --owner TaleLearnCode --title "CFP Compass"
   # (save project number from output)
   gh project field-create {project-number} --owner TaleLearnCode --name "Status" --data-type "SINGLE_SELECT" --single-select-options "Backlog,Spec,Spec Review,In Progress,In Review,Done"
   gh project link {project-number} --owner TaleLearnCode --repo CFPCompass-squad
   ```

2. **Option B: Script** (if using automation)
   - Create `scripts/create-project-board.ps1`
   - Copy script content from `.squad/project-board.md` (section "Setup Script")
   - Run: `.\scripts\create-project-board.ps1`

3. **Verify**
   - Visit https://github.com/orgs/TaleLearnCode/projects
   - Confirm "CFP Compass" project exists with 6 Status columns

## Git Commit (Pending)

Files awaiting commit on branch `squad/setup-project-board`:
```
.squad/project-board.md
.squad/decisions/inbox/dallas-project-board.md
.squad/SETUP-INSTRUCTIONS.md
```

Suggested commit message:
```
feat: add project board definition and setup script

Defines GitHub Projects v2 board with contract-first workflow stages:
Backlog → Spec → Spec Review → In Progress → In Review → Done

Contract-first stage (Spec/Spec Review) added before In Progress to 
enforce ADR-014 (no implementation without approved specification).

Includes PowerShell setup script and manual gh CLI instructions for 
board creation.

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
```

## Architecture Alignment

This board explicitly models the **contract-first API and event design** pattern documented in ADR-014:
- OpenAPI 3.1 specs required for all REST endpoints before implementation
- AsyncAPI 3.0.0 specs required for all Service Bus topics before producer/consumer
- Specs stored in `docs/api/openapi/` and `docs/api/asyncapi/`
- CI validation: Spectral (OpenAPI), AsyncAPI CLI (event specs)

The board makes this workflow visible by requiring items to pass through **Spec Review** before moving to **In Progress**. This prevents the anti-pattern of implementation-before-specification.

## Next Steps

1. Chad Green creates project board (execute gh CLI commands)
2. Team begins using board for GitHub issues
3. Scribe merges decision file into `.squad/decisions.md`
4. (Future) GitHub Actions automation for column transitions on PR events

## Success Criteria

✅ Board definition document created  
✅ Decision record created  
✅ Setup instructions created  
✅ Full script provided  
⏳ Chad Green to execute gh CLI commands  
⏳ Project board visible at https://github.com/orgs/TaleLearnCode/projects
