# Dallas — Project Knowledge

## Project

**CFP Compass** — .NET 10 / C# web application aggregating open Calls for Papers for community speakers.

- **Stack:** .NET 10, C#, Azure Container Apps, Azure SQL / Cosmos DB, Azure Functions, Terraform, GitHub Actions, Azure AD B2C
- **Lead:** Chad Green
- **Team:** Dallas (Lead), Ripley (Backend), Lambert (Frontend), Parker (DevOps), Kane (Tester), Brett (Requirements)

## Core Context

- Public listing of open CFPs: filtering, sorting, detail pages
- Organizer submission workflow with admin moderation — no auto-publish
- User accounts: favorites, deadline reminder preferences
- Email notifications: deadline reminders + weekly digest (new and closing CFPs)
- Public REST API: authenticated, GET/POST/PUT for CFPs, submissions, and metadata
- IaC via Terraform; CI/CD via GitHub Actions; hosted on Azure Container Apps
- Clean, cloud-native architecture with clear separation of concerns

## Learnings
