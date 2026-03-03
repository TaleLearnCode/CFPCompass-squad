---
title: "ADR-013: .NET Aspire 13.1 for Local Orchestration and Observability"
description: .NET Aspire 13.1 AppHost and ServiceDefaults are adopted to provide single-command local development startup, automatic service discovery, and consistent OpenTelemetry observability across all service projects.
tags:
  - adr
  - architecture-decision-record
  - dotnet-aspire
  - opentelemetry
status: accepted
---

# .NET Aspire 13.1 for Local Orchestration and Observability

- **Status:** Accepted
- **Date:** 2026-03-01
- **Work Item:** [*arch-013* — local development orchestration and observability baseline]

## Context and Problem

CFP Compass is a multi-service distributed application consisting of up to nine .NET projects: `CFPCompass.Api`, `CFPCompass.Web`, `CFPCompass.Workers`, `CFPCompass.Functions`, `CFPCompass.Domain`, `CFPCompass.Application`, `CFPCompass.Infrastructure`, plus infrastructure dependencies (Azure SQL, Redis, Service Bus). Without a developer orchestration layer, each developer must manually start all services, configure port assignments, set connection strings in `appsettings.Development.json`, and manage inter-service discovery. This is error-prone and creates high onboarding friction. Additionally, observability (structured logs, distributed traces, health checks) must be applied consistently across all service projects without per-project boilerplate. A single mechanism is needed to solve both local orchestration and observability baseline.

## Decision Drivers

- Single command to start the full local development stack — no manual service-by-service startup
- Automatic service discovery and connection string injection for all services and containers
- Consistent OpenTelemetry setup (traces, metrics, logs) across all service projects without per-project boilerplate
- Consistent health check endpoints (`/health`, `/alive`) across all services
- Aspire Dashboard for distributed trace correlation and log viewing during local development
- .NET 10 version alignment — must target the same runtime as the production stack
- Azure integration packages for Redis, Service Bus, and SQL to replace manual SDK configuration
- AppHost must NOT be deployed to production — dev orchestration only

## Considered Options

- .NET Aspire 13.1 (AppHost + ServiceDefaults)
- Docker Compose for local service orchestration
- Manual startup scripts with `appsettings.Development.json` configuration

## Decision Outcome

Chosen option: **.NET Aspire 13.1 (AppHost + ServiceDefaults)**, because it provides a .NET-native single-command local startup, automatic service discovery and connection injection, and consistent OpenTelemetry + health check baselines via `ServiceDefaults` without any per-project boilerplate. Aspire 13.1 targets .NET 10, ensuring version alignment. The Aspire Dashboard provides distributed tracing during development at no additional setup cost. Production hosting remains unchanged (Azure Container Apps + Terraform).

#### Consequences

- Good, because `dotnet run --project src/apphost/CFPCompass.AppHost` launches all services, containers (Redis, SQL, Service Bus emulator), and the Aspire Dashboard in a single command.
- Good, because Aspire service discovery injects service URLs and connection strings automatically — no manual configuration of `appsettings.Development.json` for inter-service communication.
- Good, because `ServiceDefaults` enforces OpenTelemetry, health checks, and Polly resilience across all service projects via a single `builder.AddServiceDefaults()` call.
- Good, because Aspire Dashboard at `https://localhost:18888` gives each developer distributed traces and log correlation for free.
- Good, because `Aspire.Azure.*` integration packages provide configuration injection, health checks, and telemetry for Redis, Service Bus, and SQL without manual SDK wiring.
- Good, because AppHost is excluded from production Docker builds and CI/CD — no production impact.
- Good, because Aspire 13.1 targets .NET 10 — version-aligned with the production stack.
- Bad, because two additional projects added to the solution (`CFPCompass.AppHost`, `CFPCompass.ServiceDefaults`).
- Bad, because developers must install the .NET Aspire workload: `dotnet workload install aspire` (one-time setup, documented in README).
- Bad, because AppHost must be actively excluded from all Dockerfiles and CI/CD deployment pipelines to prevent accidental production deployment.

#### Implementation

1. Dallas/Ripley adds `CFPCompass.AppHost` project to the solution (references `Aspire.Hosting.Azure.*` packages).
2. Dallas/Ripley adds `CFPCompass.ServiceDefaults` project to the solution (references `Microsoft.Extensions.ServiceDiscovery`, `OpenTelemetry.Extensions.Hosting`, `Aspire.Azure.*` integration packages).
3. All service projects (`CFPCompass.Api`, `CFPCompass.Web`, `CFPCompass.Workers`, `CFPCompass.Functions`) add a project reference to `CFPCompass.ServiceDefaults` and call `builder.AddServiceDefaults()` as the first line in `Program.cs`.
4. AppHost `Program.cs` wires the full local stack:
   ```csharp
   var builder = DistributedApplication.CreateBuilder(args);
   var sql = builder.AddAzureSqlServer("sql").RunAsContainer();
   var redis = builder.AddAzureRedis("redis").RunAsContainer();
   var serviceBus = builder.AddAzureServiceBus("servicebus").RunAsEmulator();
   builder.AddProject<CFPCompass_Api>("api")
       .WithReference(sql).WithReference(redis).WithReference(serviceBus);
   builder.AddProject<CFPCompass_Web>("web")
       .WithReference("api");
   builder.AddProject<CFPCompass_Workers>("workers")
       .WithReference(sql).WithReference(redis);
   builder.AddProject<CFPCompass_Functions>("functions")
       .WithReference(serviceBus).WithReference(sql).WithReference(redis);
   builder.Build().Run();
   ```
5. Parker adds `dotnet workload install aspire` to the developer setup documentation and adds AppHost to the `.dockerignore` and CI build exclusion list.
6. Production OpenTelemetry: `ServiceDefaults` configures OTLP exporter; in production, `OTEL_EXPORTER_OTLP_ENDPOINT` environment variable points to Azure Monitor OTLP endpoint. No code changes between local and production observability.

#### Confirmation

- `dotnet run --project src/apphost/CFPCompass.AppHost` starts all services without error in a fresh checkout.
- Aspire Dashboard accessible at `https://localhost:18888` showing all services as healthy.
- Distributed trace visible in Dashboard for a request flowing API → Service Bus → Functions.
- `GET /health` returns 200 with all dependency health status on all service projects.
- AppHost excluded from `docker build` command (confirmed by checking built image does not include AppHost assemblies).
- `dotnet workload install aspire` documented in `README.md` under Developer Setup.

#### Stakeholders

- **Dallas (Lead & Architect):** Decision owner; implements AppHost and ServiceDefaults projects
- **Ripley (Backend):** Adds `builder.AddServiceDefaults()` to `CFPCompass.Api` and `CFPCompass.Functions`; uses Aspire integration packages for Redis, Service Bus, SQL
- **Lambert (Frontend):** Adds `builder.AddServiceDefaults()` to `CFPCompass.Web`
- **Parker (DevOps):** Excludes AppHost from Docker builds and CI/CD; documents `dotnet workload install aspire`
- **Kane (Tester):** Can use Aspire test host for multi-service integration test scenarios

## Pros and Cons of the Options

### .NET Aspire 13.1 (AppHost + ServiceDefaults)

- Good, because single-command local startup — no manual configuration or startup scripts.
- Good, because automatic service discovery and connection injection — no environment-specific boilerplate.
- Good, because `ServiceDefaults` provides OTel, health checks, and resilience consistently across all projects.
- Good, because Aspire Dashboard provides free distributed tracing during development.
- Good, because .NET-native — integrates with all .NET project types without configuration ceremony.
- Good, because Aspire 13.1 targets .NET 10 — version-aligned.
- Good, because Azure integration packages (`Aspire.Azure.*`) simplify local emulation of Azure services.
- Neutral, because two additional projects added — small overhead, well-understood purpose.
- Bad, because `dotnet workload install aspire` one-time setup — minor onboarding step.
- Bad, because AppHost must be explicitly excluded from production builds — requires CI/CD awareness.

### Docker Compose

- Good, because widely understood by DevOps engineers.
- Good, because can orchestrate all containers including Redis, SQL Server, and Service Bus emulator.
- Good, because works with any language/runtime.
- Neutral, because configuration in YAML — separate from .NET project ecosystem.
- Bad, because no .NET-native service discovery — requires manual port mapping and environment variable configuration.
- Bad, because no built-in OpenTelemetry or health check integration — must be configured per service.
- Bad, because no Aspire Dashboard equivalent — distributed tracing requires separate Jaeger/Zipkin setup.
- Bad, because Compose file is an additional configuration artefact to maintain alongside .NET projects.

### Manual Startup Scripts

- Good, because zero additional tools or dependencies.
- Neutral, because each developer controls their own startup.
- Bad, because highly fragile — requires each developer to maintain their own configuration.
- Bad, because no automatic service discovery — connection strings must be manually set in every project.
- Bad, because no observability baseline — each project requires independent OTel setup.
- Bad, because onboarding new developers is slow and error-prone — no single authoritative setup.

## More Information

.NET Aspire 13.1 documentation: https://learn.microsoft.com/en-us/dotnet/aspire/

Aspire workload installation: `dotnet workload install aspire` (requires .NET 10 SDK)

Aspire Dashboard local URL: `https://localhost:18888` (auto-launched by AppHost)

The AppHost project references:
- `Aspire.Hosting.Azure.ServiceBus`
- `Aspire.Hosting.Azure.Redis`
- `Aspire.Hosting.Azure.Sql`
- `Aspire.Hosting.Azure.CommunicationServices`

Service projects reference:
- `Aspire.Azure.Messaging.ServiceBus`
- `Aspire.StackExchange.Redis`
- `Aspire.Azure.Data.SqlClient`

**Production note:** AppHost is NOT deployed to Azure. Production hosting uses Azure Container Apps + Terraform as defined in ADR-006 and the infrastructure overview. The AppHost is a developer convenience tool only.

## Follow-On Information

If the team grows and onboarding friction increases, consider adding a devcontainer configuration (`.devcontainer/devcontainer.json`) that includes `dotnet workload install aspire` in the post-create command, reducing setup to a single VS Code "Reopen in Container" action.

## Record History

* **Proposed**: 2026-03-01
* **Accepted**: 2026-03-01
* **Last Reviewed**: 2026-03-01
