# Copilot Instructions — CFPCompass

This project uses **Squad v0.5.3** — an AI team framework that coordinates specialist agents for structured development work. The Squad coordinator agent lives at `.github/agents/squad.agent.md`.

## Squad Workflow

### Issue Routing
- Adding the `squad` label to a GitHub issue triggers the Lead to triage it.
- The Lead assigns a `squad:{member}` or `squad:copilot` label based on the capability profile in `.squad/team.md`.
- When `squad:copilot` is assigned and auto-assign is enabled, Copilot picks up the issue autonomously.

### Branch Naming
```
squad/{issue-number}-{kebab-case-slug}
```
Example: `squad/42-fix-login-validation`

### Pull Requests
- Reference the issue: `Closes #{issue-number}`
- If the issue had a `squad:{member}` label, note: `Working as {member} ({role})`
- If it's a 🟡 needs-review task, add: `⚠️ Needs squad member review before merging`

### Decisions
Write decisions that affect other team members to:
```
.squad/decisions/inbox/copilot-{brief-slug}.md
```
The Scribe merges these into the shared decisions file.

## File Ownership

| Path | Owner | Notes |
|------|-------|-------|
| `.squad/` | User | Never overwrite during init; only upgrade touches Squad-owned files |
| `.squad-templates/` | Squad | Overwritten on `create-squad` upgrade |
| `.github/agents/squad.agent.md` | Squad | Overwritten on upgrade |

## Key `.squad/` Files

- `.squad/team.md` — Team roster and Copilot capability profile. The `## Members` section header is hardcoded in workflows (`squad-heartbeat.yml`, `squad-issue-assign.yml`, `squad-triage.yml`, `sync-squad-labels.yml`) — do not rename it.
- `.squad/decisions.md` — Shared team decisions (maintained by Scribe)
- `.squad/identity/wisdom.md` — Accumulated team patterns and anti-patterns
- `.squad/routing.md` — Work routing rules

## Git Merge Strategy

`.gitattributes` sets union merge on Squad state files so parallel agents don't create conflicts:
```
.squad/decisions.md merge=union
.squad/agents/*/history.md merge=union
```

## Build & Test

Not yet configured — update `.github/workflows/squad-ci.yml` with the project's build and test commands once the stack is chosen.

## Squad Ceremonies

- **Design Review** — runs automatically before multi-agent tasks touching 2+ shared systems
- **Retrospective** — runs automatically after build failure, test failure, or reviewer rejection
