---
title: "ADR-004: Azure Container Apps Jobs for Background Workers"
description: Selects Azure Container Apps Jobs with scheduled CRON triggers for all background workers, keeping jobs in the same container ecosystem as the web and API deployments with Terraform-managed infrastructure and pay-per-execution cost efficiency.
tags:
  - adr
  - architecture-decision-record
  - azure-container-apps
  - background-workers
  - scheduling
status: accepted
---
# Azure Container Apps Jobs for Background Workers

- **Status:** Accepted
- **Date:** 2026-02-28
- **Work Item:** [*arch-004* — background worker execution model selection]

## Context and Problem

CFP Compass requires several scheduled background jobs: archiving expired CFPs, sending deadline reminder emails to speakers, sending weekly digest emails, and assigning UN M.49 world regions to CFP listings. These jobs need to run on defined schedules (daily, weekly, every 6 hours), must be reliable with retry on failure, and should fit naturally into the existing containerised infrastructure. The team is already deploying Container Apps for the web and API; a decision is needed on whether to use Azure Functions, Azure Container Apps Jobs, or another mechanism for background work.

## Decision Drivers

- Consistent container ecosystem with the web and API deployments (single Dockerfile per project, shared codebase)
- No platform-specific abstractions or binding models to learn beyond what is already used
- Terraform-managed alongside all other Container Apps resources
- Cost-efficient — jobs should only consume compute when they are actually running
- Reliable retry behaviour on failure without building retry infrastructure from scratch
- CRON scheduling support with minute-level granularity

## Considered Options

- Azure Container Apps Jobs (scheduled trigger)
- Azure Functions (timer trigger, Consumption plan)
- Long-running background services within the API Container App (IHostedService)

## Decision Outcome

Chosen option: **Azure Container Apps Jobs with scheduled triggers**, because they share the same container ecosystem as the web and API apps (no new runtime or abstraction), are managed via the same Terraform `container-apps/` module, and run cost-efficiently (only during job execution). The team avoids learning Azure Functions trigger bindings and host.json configuration just for scheduled work, keeping the background jobs as standard .NET hosted processes in a familiar container.

#### Consequences

- Good, because Container Apps Jobs use the same `cfpcompass-workers` Docker image and Dockerfile as the rest of the app — no separate build pipeline or language runtime.
- Good, because Terraform manages jobs alongside all other Container Apps resources — no separate IaC module or deployment pipeline.
- Good, because cost-efficient: jobs only consume compute during execution; no idle cost between runs.
- Good, because CRON scheduling at 1-minute granularity is sufficient for all four jobs.
- Bad, because no built-in retry/poison-queue mechanism as with Azure Functions trigger bindings — Polly retry policies must be implemented in each job implementation.
- Bad, because Container Apps Jobs have a minimum schedule granularity of 1 minute — sufficient for current jobs but not sub-minute triggers if needed in future.

#### Implementation

1. Parker provisions four Container Apps Jobs via the `infra/modules/container-apps/` Terraform module:
   - `cfpcompass-job-cfpexpiry`: schedule `0 0 * * *` (daily midnight UTC)
   - `cfpcompass-job-deadlinereminder`: schedule `0 6 * * *` (daily 6AM UTC)
   - `cfpcompass-job-weeklydigest`: schedule `0 8 * * 0` (Sunday 8AM UTC)
   - `cfpcompass-job-worldregion`: schedule `0 */6 * * *` (every 6 hours UTC)
2. All jobs are packaged in the `cfpcompass-workers` container image, differentiated by entry point arguments (e.g., `--job CfpExpiryJob`).
3. Ripley implements each job as a class implementing `IJob` (or equivalent interface) in `CFPCompass.Workers`, with Polly retry policies (`WaitAndRetryAsync` with exponential backoff) wrapping the core logic.
4. Failed job executions are logged to both the Log Analytics Workspace and the `AuditLog` SQL table.
5. Each job calls `builder.AddServiceDefaults()` at startup for consistent health checks and OpenTelemetry instrumentation.
6. Secrets (SQL connection, Redis, ACS) are resolved from Key Vault via managed identity at job startup.

#### Confirmation

- All four jobs execute successfully in the dev environment on their scheduled triggers.
- Polly retry policies confirmed to retry on transient failures (simulated by temporarily blocking SQL access in integration tests).
- Container Apps Jobs execution history visible in Azure Portal and Log Analytics.
- No idle cost between job runs confirmed via Azure Cost Analysis.

#### Stakeholders

- **Dallas (Lead & Architect):** Decision owner; defined background worker requirements
- **Ripley (Backend):** Implements job logic, Polly retry policies, and `CFPCompass.Workers` project
- **Parker (DevOps):** Provisions Container Apps Jobs via Terraform; configures CRON schedules and managed identity
- **Kane (Tester):** Tests job execution, retry behaviour, and idempotency (safe to run twice)

## Pros and Cons of the Options

### Azure Container Apps Jobs (Scheduled Trigger)

- Good, because same container ecosystem — `cfpcompass-workers` image is built and deployed identically to web/API.
- Good, because Terraform-managed alongside all other Container Apps — no separate IaC or deployment pipeline.
- Good, because pay-per-execution — no idle cost between runs.
- Good, because standard .NET hosted process — no platform-specific binding model or host.json.
- Good, because CRON scheduling built into Container Apps Jobs.
- Neutral, because minimum schedule granularity is 1 minute (all current jobs are daily/weekly/every-6h — well within limits).
- Bad, because no built-in retry/poison handling; Polly retry must be implemented manually.

### Azure Functions (Timer Trigger, Consumption Plan)

- Good, because built-in timer trigger with CRON expression support.
- Good, because Consumption plan is pay-per-execution with no idle cost.
- Good, because built-in retry policies configurable in host.json.
- Neutral, because Azure Functions isolated process model supports .NET 10.
- Bad, because requires separate Functions runtime, host.json configuration, and trigger binding model — introduces a new abstraction for what is otherwise standard scheduled work.
- Bad, because Functions cold start adds latency to job execution starts (Consumption plan).
- Bad, because `CFPCompass.Functions` project already exists for Service Bus processors — adding scheduled jobs here conflates two different execution patterns in one project.

### IHostedService within the API Container App

- Good, because no additional infrastructure — jobs run inside the existing API process.
- Good, because full access to all DI services without additional configuration.
- Neutral, because can use `BackgroundService` base class for simple implementation.
- Bad, because jobs run on the same compute as the API — a runaway job can impact API performance.
- Bad, because multiple API replicas would each run the jobs, causing duplicate executions unless leader election is implemented.
- Bad, because job failures can affect API availability — tight coupling of concerns.
- Bad, because no scheduling granularity control beyond what is implemented in code.

## More Information

Azure Container Apps Jobs documentation: https://learn.microsoft.com/en-us/azure/container-apps/jobs

All four jobs must be idempotent — they may be re-run safely if a previous execution failed partway through. Ripley must design each job's database operations to handle partial completion (e.g., archiving CFPs that are not yet archived, not all CFPs).

The `WorldRegionAssignmentJob` runs every 6 hours to handle newly submitted CFPs that lack a world region assignment. It queries for CFPs with a null `WorldRegion` and attempts to assign one based on the CFP's country code using the UN M.49 lookup service.

## Follow-On Information

Post-MVP: if sub-minute scheduling or complex workflow orchestration is needed, consider Azure Durable Functions or Azure Logic Apps. For current requirements, Container Apps Jobs are the right level of complexity.

## Record History

* **Proposed**: 2026-02-28
* **Accepted**: 2026-02-28
* **Last Reviewed**: 2026-02-28
