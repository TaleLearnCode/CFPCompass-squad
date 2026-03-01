# Parker — Project Knowledge

## Project

**CFP Compass** — .NET 10 / C# web application aggregating open Calls for Papers for community speakers.

- **Stack:** .NET 10, C#, Azure Container Apps, Azure SQL / Cosmos DB, Azure Functions, Terraform, GitHub Actions, Azure AD B2C
- **Lead:** Chad Green
- **Team:** Dallas (Lead), Ripley (Backend), Lambert (Frontend), Parker (DevOps), Kane (Tester), Brett (Requirements)

## Core Context

- Hosting: Azure Container Apps (primary app); Azure Functions or containerized workers (background jobs)
- Storage: Azure SQL or Cosmos DB — IaC must support both until decision is made
- Auth infrastructure: Azure AD B2C tenant and app registration
- IaC: Terraform for all Azure resources — Key Vault, Container Registry, Container Apps env, SQL/Cosmos, Functions, B2C config
- CI/CD: GitHub Actions — build, test, containerize, push to ACR, deploy to Container Apps
- Environments: at minimum dev + prod; staging desirable

## Latest Context (2026-02-28)

**Brett Requirements v2 Complete:** All 10 open questions resolved by Chad Green and integrated into `.squad/requirements.md`. Feature 1.4 (Past CFPs Archive) added. **Consult requirements.md v2 before infrastructure implementation.** Critical infrastructure change: Ensure i18n architecture is built in from day 1 — consider localization strategy for app configuration, resource names, and regional deployments.

**Dallas Architecture v1 Complete:** System architecture finalized at `.squad/architecture.md` with 6 ADRs: Azure SQL (Serverless), Blazor Server, ASP.NET Core Identity + Fido2NetLib passkeys, Container Apps Jobs, Redis Basic C0, APIM Consumption. **Read architecture.md before infrastructure provisioning.** DevOps decisions locked: Terraform IaC for Container Apps, SQL (Serverless tier), Redis Basic C0, APIM (Consumption tier), Key Vault, ACR, GitHub Actions CI/CD for containerized deployments. 4 open questions remain for Chad Green (domain, bot protection, taxonomy, email sender).

## Work — Managed Identity Gap Work Items (2026-02-28)

Created three GitHub issues to address passwordless authentication gaps:

1. **Issue #2 (HIGH):** Azure SQL needs Managed Identity for Web + API Container Apps (currently uses Key Vault secret)
2. **Issue #1 (MEDIUM):** Azure Blob Storage should replace SAS tokens with Managed Identity RBAC
3. **Issue #3 (LOW):** Azure Communication Services email should use ManagedIdentityCredential instead of connection string

**Actions taken:**
- Created `infrastructure`, `security`, `managed-identity` GitHub labels (prerequisites missing)
- All issues include problem statement, multi-phase solutions, and acceptance criteria
- Summary written to `.squad/decisions/inbox/parker-mi-gaps-created.md`
- Assigned HIGH priority to SQL issue (largest security gap); MEDIUM/LOW for storage/email

**Next:** Proceed with Phase 1 (SQL) as soon as Dallas/Ripley review application implications.

## Work — MI Gaps Ingested into Decisions (2026-03-01)

Parker's three MI GitHub issues merged into `.squad/decisions.md` with orchestration and session logs. Dallas architecture review (Agent 10) identified gaps; Parker operationalized them into prioritized work items. Decision finalized in orchestration batch; ready for implementation phase.

**Cross-agent awareness:** Dallas (Agent 11) aware of Parker's MI work; noted in ADR-015 decision and infrastructure overview update. Ash unaware of MI gaps (Technical Writer focus); not relevant to documentation scope.

## Learnings
