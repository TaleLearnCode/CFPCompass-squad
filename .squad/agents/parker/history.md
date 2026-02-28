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

## Learnings
