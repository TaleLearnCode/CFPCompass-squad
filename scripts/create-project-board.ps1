#Requires -Version 5.1
<#
.SYNOPSIS
    Creates GitHub Projects v2 board for TaleLearnCode/CFPCompass-squad with contract-first workflow stages.

.DESCRIPTION
    Sets up a GitHub Projects v2 board with 6 workflow stages that enforce the contract-first
    development approach (ADR-014). Stages: Backlog -> Spec -> Spec Review -> In Progress -> In Review -> Done

.NOTES
    Requires: GitHub CLI (gh) installed and authenticated with write access to the organization
    Run: gh auth login  (if not already authenticated)
#>

param(
    [string]$Owner = "TaleLearnCode",
    [string]$Repository = "CFPCompass-squad",
    [string]$ProjectTitle = "CFP Compass"
)

$ErrorActionPreference = "Stop"

$WorkflowStages = @("Backlog", "Spec", "Spec Review", "In Progress", "In Review", "Done")

Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "GitHub Projects v2 Board Setup: $ProjectTitle" -ForegroundColor Cyan
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host ""

# Verify gh CLI
Write-Host "[1/3] Verifying GitHub CLI..." -ForegroundColor Yellow
try {
    $ghVersion = & gh --version 2>&1 | Select-Object -First 1
    Write-Host "OK: $ghVersion" -ForegroundColor Green
} catch {
    Write-Host "FAIL: GitHub CLI not found. Install: https://cli.github.com" -ForegroundColor Red
    Write-Host "  Then run: gh auth login" -ForegroundColor Yellow
    exit 1
}

# Create the project
Write-Host "[2/3] Creating GitHub Project '$ProjectTitle'..." -ForegroundColor Yellow
$projectOutput = & gh project create --owner $Owner --title $ProjectTitle 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "FAIL: Could not create project:" -ForegroundColor Red
    Write-Host $projectOutput
    exit 1
}

# Parse project number
$projectNumber = $null
if ($projectOutput -match '#(\d+)') {
    $projectNumber = $matches[1]
} elseif ($projectOutput -match '/projects/(\d+)') {
    $projectNumber = $matches[1]
} elseif ($projectOutput -match '(\d+)$') {
    $projectNumber = $matches[1]
}

if (-not $projectNumber) {
    Write-Host "FAIL: Could not parse project number from output:" -ForegroundColor Red
    Write-Host $projectOutput
    Write-Host "  Run manually: gh project field-create <number> --owner $Owner --name Status --data-type SINGLE_SELECT --single-select-options 'Backlog,Spec,Spec Review,In Progress,In Review,Done'"
    exit 1
}

Write-Host "OK: Project created: #$projectNumber" -ForegroundColor Green

# Configure Status field with workflow stages via GraphQL
# (GitHub Projects V2 "Status" is a built-in reserved field — it must be updated, not created)
Write-Host "[3/3] Configuring Status field with workflow stages..." -ForegroundColor Yellow

$fieldData = & gh project field-list $projectNumber --owner $Owner --format json 2>&1 | ConvertFrom-Json
$statusField = $fieldData.fields | Where-Object { $_.name -eq "Status" }

if (-not $statusField) {
    Write-Host "FAIL: Status field not found on project #$projectNumber" -ForegroundColor Red
    exit 1
}

$token = & gh auth token
$headers = @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
}

$optionColors = @("GRAY","BLUE","YELLOW","ORANGE","PURPLE","GREEN")
$optionDescriptions = @(
    "Not yet started or prioritized"
    "OpenAPI/AsyncAPI spec being authored"
    "Spec PR open, awaiting approval"
    "Implementation underway; spec approved"
    "PR open, awaiting code review"
    "Merged and complete"
)
$options = for ($i = 0; $i -lt $WorkflowStages.Count; $i++) {
    @{ name = $WorkflowStages[$i]; color = $optionColors[$i]; description = $optionDescriptions[$i] }
}

$body = @{
    query = 'mutation($fieldId:ID!,$options:[ProjectV2SingleSelectFieldOptionInput!]!){updateProjectV2Field(input:{fieldId:$fieldId,singleSelectOptions:$options}){projectV2Field{... on ProjectV2SingleSelectField{name options{name}}}}}'
    variables = @{ fieldId = $statusField.id; options = $options }
} | ConvertTo-Json -Depth 10 -Compress

$response = Invoke-RestMethod -Uri "https://api.github.com/graphql" -Method POST -Headers $headers -Body $body

if ($response.errors) {
    Write-Host "WARN: Could not update Status field via API. Configure manually in the GitHub Projects UI." -ForegroundColor Yellow
    Write-Host "  Stages to add: $($WorkflowStages -join ', ')" -ForegroundColor Yellow
} else {
    Write-Host "OK: Status field configured with stages:" -ForegroundColor Green
    $WorkflowStages | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
}

# Link to repository
Write-Host "Linking project to repository $Owner/$Repository..." -ForegroundColor Yellow
& gh project link $projectNumber --owner $Owner --repo $Repository 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "OK: Linked to $Owner/$Repository" -ForegroundColor Green
} else {
    Write-Host "WARN: Auto-link skipped -- link manually at: https://github.com/orgs/$Owner/projects" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "===============================================================" -ForegroundColor Cyan
Write-Host "Done! Project #$projectNumber" -ForegroundColor Green
Write-Host "  URL: https://github.com/orgs/$Owner/projects/$projectNumber" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open the URL above and verify the 6 Status columns" -ForegroundColor White
Write-Host "  2. Add issues and track them through the workflow:" -ForegroundColor White
Write-Host "     Backlog -> Spec -> Spec Review -> In Progress -> In Review -> Done" -ForegroundColor White
Write-Host "===============================================================" -ForegroundColor Cyan
