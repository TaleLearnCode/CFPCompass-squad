# Ripley — Project Knowledge

## Project

**CFP Compass** — .NET 10 / C# web application aggregating open Calls for Papers for community speakers.

- **Stack:** .NET 10, C#, Azure Container Apps, Azure SQL / Cosmos DB, Azure Functions, Terraform, GitHub Actions, Azure AD B2C
- **Lead:** Chad Green
- **Team:** Dallas (Lead), Ripley (Backend), Lambert (Frontend), Parker (DevOps), Kane (Tester), Brett (Requirements)

## Core Context

- REST API: authenticated, GET/POST/PUT for CFPs, submissions, and metadata; proper authorization and versioning
- Organizer submission workflow: submitted → moderation → approved/rejected → published
- User accounts: registration, login, favorites, notification preferences
- Email triggers: deadline reminders, weekly digest — fired from Azure Functions or background workers
- Authentication via Azure AD B2C or built-in .NET Identity
- Data: Azure SQL or Cosmos DB — final choice TBD by Dallas

## Learnings
