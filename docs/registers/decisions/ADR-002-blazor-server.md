---
title: "ADR-002: Blazor Server with .NET 10 SSR for Web Frontend"
description: Selects Blazor Server with .NET 10 interactive SSR as the web frontend, providing server-side rendering for SEO on public pages and rich C# interactivity for authenticated dashboards and admin tools within a single codebase.
tags:
  - adr
  - architecture-decision-record
  - blazor
  - dotnet
  - aspnet-core
status: accepted
---
# Blazor Server with .NET 10 SSR for Web Frontend

- **Status:** Accepted
- **Date:** 2026-02-28
- **Work Item:** [*arch-002* — web frontend framework selection]

## Context and Problem

CFP Compass requires a web frontend that serves two distinct audiences with conflicting needs: public browsing of CFP listings (SEO-critical, server-rendered), and authenticated speaker dashboards and admin tools (rich interactivity, complex forms, cascading dropdowns, real-time moderation workflows). A single frontend technology must accommodate both. The team is C#-first and prefers to avoid a JavaScript-heavy frontend stack that would require separate language expertise and duplicate domain model definitions.

## Decision Drivers

- SEO for public CFP listing and browse pages (search engine crawlability)
- Rich interactivity for authenticated dashboards, admin moderation tools, and multi-step forms
- Single programming language (C#) across frontend and backend to avoid cognitive overhead and duplicate model definitions
- .NET 10 compatibility and active Microsoft support
- Direct access to shared domain models and application services without a separate API layer for internal pages
- Reduced operational complexity (one deployment unit for the web experience)

## Considered Options

- Blazor Server with .NET 10 interactive server-side rendering (SSR)
- Razor Pages (ASP.NET Core, server-rendered)
- Blazor WebAssembly (WASM)

## Decision Outcome

Chosen option: **Blazor Server with .NET 10 interactive SSR**, because it uniquely satisfies both SEO (server-side pre-rendering of public pages) and rich interactivity (SignalR-powered components for dashboards and forms) within a single C# codebase. Razor Pages cannot provide the rich interactive experience needed for admin tools and tracking dashboards without significant JavaScript additions. Blazor WASM cannot provide server-side rendering for SEO and introduces cold-start and download-size concerns.

#### Consequences

- Good, because public CFP listing, browse, and search pages are server-rendered — fully crawlable by search engines.
- Good, because rich interactivity (tracking buttons, filtering, admin moderation, cascading dropdowns) is handled in C# without JavaScript.
- Good, because shared domain models and application services are accessible directly from Blazor components — no separate BFF or API client for internal pages.
- Good, because single programming language (C#) for the entire application stack reduces context switching and onboarding friction.
- Good, because .NET 10 Blazor SSR with interactivity granularity allows mixing static SSR pages with interactive components on the same page.
- Bad, because Blazor Server requires a persistent SignalR WebSocket connection per active session — adds latency for geographically distant users and memory per connected user.
- Bad, because server memory scales with concurrent connected users — must monitor and configure auto-scaling thresholds appropriately.

#### Implementation

1. Lambert implements the web frontend as `CFPCompass.Web`, a Blazor Server project targeting .NET 10.
2. Public pages (`/`, `/cfps`, `/cfps/{id}`, `/past-cfps`) use static SSR rendering mode for SEO.
3. Authenticated pages (speaker dashboard, tracking, admin tools) use interactive server rendering with SignalR.
4. Lambert configures Azure Container Apps ingress with WebSocket support enabled (required for Blazor Server SignalR).
5. Azure Front Door is configured to support WebSocket pass-through for the Container App origin.
6. `CFPCompass.Web` calls `builder.AddServiceDefaults()` at startup for health checks and OpenTelemetry.
7. Anti-forgery tokens are configured for non-Blazor forms (e.g., the CFP submission form with Turnstile integration).

#### Confirmation

- Public CFP listing pages return full HTML in initial response (confirmed by checking HTTP response body without JavaScript).
- Blazor interactive components function correctly in authenticated sessions (tracking state updates, admin approval/rejection).
- WebSocket connectivity confirmed through Azure Front Door and Container Apps ingress.
- SEO audit confirms public pages are crawlable (title, meta description, structured data present in SSR output).

#### Stakeholders

- **Dallas (Lead & Architect):** Decision owner; defined frontend architecture requirements
- **Lambert (Frontend):** Implements all Blazor Server components, pages, and forms
- **Parker (DevOps):** Configures Container Apps WebSocket ingress and Front Door WebSocket pass-through
- **Kane (Tester):** Tests both SSR page rendering and interactive component behaviour; validates SEO output

## Pros and Cons of the Options

### Blazor Server with .NET 10 SSR

- Good, because server-side rendering satisfies SEO requirements for public listing pages.
- Good, because interactive server components handle dashboard complexity in C# — no JavaScript required.
- Good, because shared domain models and services are accessible directly from components.
- Good, because .NET 10 introduces fine-grained interactivity modes (static SSR per page, interactive per component).
- Good, because C#-only stack; no TypeScript/JavaScript expertise needed.
- Neutral, because SignalR WebSocket dependency requires Container Apps WebSocket support (supported by default).
- Bad, because persistent SignalR connections consume server memory proportional to concurrent users.
- Bad, because geographically distant users may experience higher interaction latency vs. WASM (mitigated by Azure Front Door edge presence).

### Razor Pages (ASP.NET Core)

- Good, because mature, battle-tested server-rendering model.
- Good, because excellent SEO — all pages are fully server-rendered.
- Good, because simple mental model for request/response pages.
- Neutral, because C# for page handlers and view models.
- Bad, because limited interactivity without JavaScript; admin tools, dashboards, and cascading forms require significant JavaScript additions.
- Bad, because no component model — UI code reuse requires partial views and tag helpers, which are less composable than Blazor components.
- Bad, because rich interactivity (real-time tracking, live moderation queue) would require a separate JavaScript framework alongside Razor Pages.

### Blazor WebAssembly (WASM)

- Good, because runs entirely in the browser — no persistent server connection required.
- Good, because offline capability (PWA-style) if needed.
- Good, because C# for all UI logic.
- Neutral, because can share domain models with backend via shared class library.
- Bad, because no server-side rendering — public pages are not crawlable by search engines without additional pre-rendering infrastructure.
- Bad, because initial download of .NET runtime and WASM payload (~5–10 MB) introduces first-load latency.
- Bad, because requires a separate API (or BFF) for all data access — cannot directly call application services.
- Bad, because cold start on first load is significant, especially on low-bandwidth connections common in some geographies.

## More Information

.NET 10 Blazor SSR interactivity modes documentation: https://learn.microsoft.com/en-us/aspnet/core/blazor/components/render-modes

The `@rendermode InteractiveServer` directive on individual components allows mixing static SSR (for SEO-critical public pages) with interactive server components (for authenticated features) in the same application. This is the key capability that makes Blazor Server the right choice for CFP Compass — it eliminates the false choice between SEO and interactivity.

Azure Container Apps supports WebSocket connections by default on HTTP/1.1 ingress. No additional configuration is needed beyond ensuring the ingress policy allows WebSocket upgrades.

## Follow-On Information

If Blazor Server memory pressure becomes a concern at scale (many concurrent speakers during peak CFP season), the following options are available without changing the fundamental technology choice:
- Increase Container App replicas (auto-scaling via KEDA)
- Move static/public pages to a CDN-cached static HTML strategy (pre-generated)
- Evaluate Blazor Auto render mode (switches between server and WASM per user session) in .NET 11+

## Record History

* **Proposed**: 2026-02-28
* **Accepted**: 2026-02-28
* **Last Reviewed**: 2026-02-28
