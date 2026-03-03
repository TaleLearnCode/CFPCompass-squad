# Project Board Setup Instructions for Chad

**Status:** Ready for implementation  
**Prepared by:** Dallas (Lead Architect)  
**Date:** 2026-03-01

## Summary

Two files have been created to enable GitHub Projects v2 board setup for contract-first workflow:

1. `.squad/project-board.md` — Board definition, workflow stages, and setup instructions
2. `.squad/decisions/inbox/dallas-project-board.md` — Decision record

## What Needs to Happen

The project board and setup script creation requires **elevated permissions** (GitHub CLI authentication with write access to TaleLearnCode/CFPCompass-squad). These commands must be run by Chad Green or another authorized user with:

- GitHub CLI (`gh`) installed and authenticated
- Write access to the TaleLearnCode organization

## Quick Start (for Chad)

### Step 1: Create the Project Board

From `C:\Repos\CFPCompass\`, run:

```powershell
# Create the GitHub Project
gh project create --owner TaleLearnCode --title "CFP Compass"

# The output will show the project number (e.g., "Created project #5")
# Save this number for the next step
```

### Step 2: Add the Status Field

Replace `{project-number}` with the number from Step 1:

```powershell
gh project field-create {project-number} --owner TaleLearnCode --name "Status" --data-type "SINGLE_SELECT" --single-select-options "Backlog,Spec,Spec Review,In Progress,In Review,Done"
```

### Step 3: Link to Repository

```powershell
gh project link {project-number} --owner TaleLearnCode --repo CFPCompass-squad
```

### Step 4: Verify

Visit https://github.com/orgs/TaleLearnCode/projects and verify:
- Project "CFP Compass" exists
- Status column shows 6 options: Backlog → Spec → Spec Review → In Progress → In Review → Done

## Full Script Alternative

The `.squad/project-board.md` file contains a complete PowerShell script that can be saved as `scripts/create-project-board.ps1` for one-command setup:

```powershell
.\scripts\create-project-board.ps1
```

To use the script:

1. Create `scripts/` directory in the repo root (if it doesn't exist)
2. Copy the PowerShell script content from `.squad/project-board.md` (section "Setup Script")
3. Save it as `scripts/create-project-board.ps1`
4. Run it from the repo root

## Workflow Rationale

The board enforces **contract-first API and event design** (ADR-014):

- **Backlog:** Items not yet prioritized
- **Spec:** OpenAPI/AsyncAPI specification being authored
- **Spec Review:** Spec submitted, awaiting approval (this gate prevents implementation-before-spec)
- **In Progress:** Implementation underway (only after spec is approved)
- **In Review:** PR open, awaiting code review
- **Done:** Merged and closed

This workflow is the defining characteristic of CFP Compass development. Every REST endpoint and Service Bus topic must have an approved specification before implementation.

## Documentation

- Full board definition: `.squad/project-board.md`
- Design decision: `.squad/decisions/inbox/dallas-project-board.md`

## Next Steps for Dallas/Team

- [ ] Chad Green runs the setup commands or script
- [ ] Verify project board is created and visible in GitHub Projects
- [ ] Update GitHub issue templates to reference the project board
- [ ] Consider GitHub Actions automation for column transitions (future enhancement)
- [ ] Scribe merges the decision file from `.squad/decisions/inbox/` into `.squad/decisions.md`
