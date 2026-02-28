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

## Learnings
