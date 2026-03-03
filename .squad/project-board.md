# GitHub Projects v2 Board: CFP Compass

## Overview

This document defines the GitHub Projects v2 board for **TaleLearnCode/CFPCompass-squad** with workflow stages aligned to the **contract-first development approach** (ADR-014: OpenAPI 3.1 + AsyncAPI 3.0.0 specs must be approved before implementation).

## Workflow Stages (Columns)

The board enforces a contract-first workflow with six stages:

| # | Column | Description |
|---|--------|-------------|
| 1 | **Backlog** | Items not yet started or prioritized; awaiting grooming |
| 2 | **Spec** | OpenAPI/AsyncAPI specification being authored or revised |
| 3 | **Spec Review** | Spec submitted via PR, awaiting approval; Spectral/AsyncAPI CLI validation passing |
| 4 | **In Progress** | Implementation underway; spec approved and merged; code under development |
| 5 | **In Review** | PR open for code review; awaiting maintainer/lead approval and merge |
| 6 | **Done** | PR merged and closed; item complete and in production or staging |

## Why This Workflow?

CFP Compass enforces **contract-first API and event design** (ADR-014):
- No REST endpoint in `CfpCompass.Api` may be implemented without an approved OpenAPI 3.1 spec
- No Azure Service Bus topic may be used without an approved AsyncAPI 3.0.0 spec
- Specs are authored in `docs/api/openapi/` and `docs/api/asyncapi/`
- Approval gate: Spec PR merged → implementation PR opened (no exceptions)

The **Spec** and **Spec Review** columns explicitly model this gate, making contract-first workflows visible in project tracking and preventing inadvertent implementation-before-spec.

## Creating the Board

### Prerequisites
- GitHub CLI (`gh`) installed and authenticated with write access to `TaleLearnCode/CFPCompass-squad`
- Run from `C:\Repos\CFPCompass\` (or any directory with network access)

### Quick Start

Run the PowerShell script from `C:\Repos\CFPCompass`:

```powershell
# Option 1: Create scripts directory first and place create-project-board.ps1 there, then run:
.\scripts\create-project-board.ps1

# Option 2: Or run the commands directly (see Manual Creation below)
```

**PowerShell Script Content:** See section "Setup Script (create-project-board.ps1)" below for the full script.

### Manual Creation (if script fails)

```bash
# 1. Create the project
gh project create --owner TaleLearnCode --title "CFP Compass"

# This returns the project number (e.g., 5). Use it in the next step.

# 2. Add the Status field with 6 options
gh project field-create {project-number} --owner TaleLearnCode --name "Status" --data-type "SINGLE_SELECT" --single-select-options "Backlog,Spec,Spec Review,In Progress,In Review,Done"

# 3. Link to repository (if not auto-linked)
gh project link {project-number} --owner TaleLearnCode --repo CFPCompass-squad
```

Replace `{project-number}` with the number returned by the `project create` command.

### Verifying the Board

After creation:
1. Visit https://github.com/orgs/TaleLearnCode/projects
2. Click "CFP Compass"
3. Verify the 6 status columns are present: Backlog → Spec → Spec Review → In Progress → In Review → Done
4. Add issues to the board and test moving them between columns

## Integration with Issues & PRs

- **Issues:** When creating a GitHub issue for a new feature/API endpoint, start it in **Backlog**
- **Spec PR:** Move to **Spec** when spec work begins; move to **Spec Review** when the PR is opened
- **Implementation PR:** Move to **In Progress** after spec is merged
- **Code Review:** Move to **In Review** when implementation PR is opened
- **Complete:** Move to **Done** when implementation PR is merged

## Future Enhancements

- Add custom fields for epic/feature grouping (optional)
- Add assignee automation via GitHub Actions workflow
- Add automated transitions (e.g., PR merged → move to Done)
- Link to ADR-014 in project description via GitHub Projects UI

---

## Setup Script (create-project-board.ps1)

If you create a `scripts\create-project-board.ps1` file at the root of the repository, use the following PowerShell script:

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Creates GitHub Projects v2 board for TaleLearnCode/CFPCompass-squad with contract-first workflow stages.

.NOTES
    Requires: GitHub CLI (gh) authenticated with write access to the organization
    Author: Dallas (Lead Architect)
    Date: 2026-03-01
#>

param(
    [string]$Owner = "TaleLearnCode",
    [string]$Repository = "CFPCompass-squad",
    [string]$ProjectTitle = "CFP Compass"
)

$ErrorActionPreference = "Stop"

# Define workflow stages
$WorkflowStages = @(
    "Backlog",
    "Spec",
    "Spec Review",
    "In Progress",
    "In Review",
    "Done"
)

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "GitHub Projects v2 Board Setup: $ProjectTitle" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Verify gh CLI is installed and authenticated
Write-Host "[1/3] Verifying GitHub CLI..." -ForegroundColor Yellow
try {
    $ghVersion = & gh --version 2>&1
    Write-Host "✓ GitHub CLI found: $ghVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ GitHub CLI not found or not authenticated." -ForegroundColor Red
    Write-Host "  Install: https://cli.github.com" -ForegroundColor Yellow
    Write-Host "  Authenticate: gh auth login" -ForegroundColor Yellow
    exit 1
}

# Step 1: Create the project
Write-Host "[2/3] Creating GitHub Project '$ProjectTitle'..." -ForegroundColor Yellow
try {
    $projectOutput = & gh project create --owner $Owner --title $ProjectTitle 2>&1
    
    if ($projectOutput -match '#(\d+)') {
        $projectNumber = $matches[1]
        Write-Host "✓ Project created: #$projectNumber" -ForegroundColor Green
    } else {
        Write-Host "✗ Could not parse project number from output:" -ForegroundColor Red
        Write-Host $projectOutput
        exit 1
    }
} catch {
    Write-Host "✗ Failed to create project: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Add the Status field with workflow stages
Write-Host "[3/3] Adding Status field with workflow stages..." -ForegroundColor Yellow
try {
    $statusOptions = $WorkflowStages -join ","
    
    & gh project field-create $projectNumber `
        --owner $Owner `
        --name "Status" `
        --data-type "SINGLE_SELECT" `
        --single-select-options $statusOptions 2>&1 | Out-Null
    
    Write-Host "✓ Status field created with 6 stages:" -ForegroundColor Green
    $WorkflowStages | ForEach-Object { Write-Host "  • $_" -ForegroundColor Green }
} catch {
    Write-Host "✗ Failed to create Status field: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Link to repository
Write-Host "Linking project to repository..." -ForegroundColor Yellow
try {
    & gh project link $projectNumber `
        --owner $Owner `
        --repo $Repository 2>&1 | Out-Null
    Write-Host "✓ Project linked to $Owner/$Repository" -ForegroundColor Green
} catch {
    Write-Host "⚠ Repository link: $_" -ForegroundColor Yellow
    Write-Host "  (Manually link at: https://github.com/orgs/$Owner/projects)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✓ Setup Complete!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Project Number: $projectNumber" -ForegroundColor Cyan
Write-Host "Dashboard URL: https://github.com/orgs/$Owner/projects/$projectNumber" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open the dashboard link above and verify the Status columns" -ForegroundColor White
Write-Host "2. Add issues to the project and move between columns" -ForegroundColor White
Write-Host "3. Reference the project in your GitHub issue templates" -ForegroundColor White
```

---

**Created:** 2026-03-01  
**By:** Dallas (Lead Architect)  
**Related:** ADR-014 (Contract-First API & Event Design)
