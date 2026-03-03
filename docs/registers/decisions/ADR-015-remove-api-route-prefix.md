---
title: "ADR-015: Remove /api/ Route Prefix"
description: Remove the /api/ prefix from all application API routes since the API is hosted on a dedicated container behind APIM with no page routes to disambiguate.
tags:
  - adr
  - architecture-decision-record
  - api-design
  - routing
  - apim
status: accepted
---
# Remove /api/ Prefix from API Routes

- **Status:** Accepted
- **Date:** 2026-02-28
- **Work Item:** [*arch-015* — remove /api/ route prefix]

## Context and Problem

The `/api/` prefix is an ASP.NET Core convention that disambiguates API controller routes from page routes when both coexist on the same host. In CFP Compass, the API (`CFPCompass.Api`) is a dedicated container with no page routes — it serves only REST API endpoints. The Blazor Server UI (`CFPCompass.Web`) is a separate container on a separate host. The `/api/` prefix carries zero disambiguating information in this deployment topology.

Additionally, `CFPCompass.Api` has no public ingress — Azure API Management (APIM) is the sole public entry point for all API traffic. APIM imports the canonical OpenAPI spec and forwards requests to the API Container App backend. The path prefix visible to external consumers is controlled by the OpenAPI spec, not by the backend controller routing.

## Decision Drivers

- No disambiguation needed — API and Web are separate containers on separate hosts
- APIM is sole public ingress — backend URL structure is not consumer-visible
- Cleaner consumer-facing URLs with no noise prefix
- Decision made before any controllers or OpenAPI specs are implemented — zero migration cost
- Local Aspire development unaffected (service discovery operates at host level, not path level)

## Considered Options

- Keep `/api/v1/` prefix (ASP.NET Core convention)
- Remove `/api/` prefix, use `/v1/` directly

## Decision Outcome

Chosen option: **Remove `/api/` prefix**, because the prefix exists solely to disambiguate API routes from page routes on a shared host, and CFP Compass has no shared host. All API routes use `/v1/` directly.

**Full route table:**

| Route | Purpose |
|-------|---------|
| `GET /v1/cfps` | List CFP listings (public) |
| `GET /v1/cfps/{id}` | CFP detail (public) |
| `POST /v1/cfps` | Submit new CFP listing |
| `PUT /v1/cfps/{id}` | Update CFP listing |
| `GET /v1/topics` | List topics (public) |
| `GET /v1/categories` | List categories (public) |
| `GET /v1/countries` | List countries (public) |
| `GET /v1/regions` | List regions (public) |
| `GET /v1/submissions` | List user's submissions |
| `GET /v1/submissions/{id}/status` | Poll submission status |
| `GET /v1/account` | Get user account |
| `PUT /v1/account` | Update user account |
| `GET /v1/claims` | List organizer claims |
| `POST /v1/claims` | Submit organizer claim |
| `GET /v1/metadata` | API metadata |
| `GET /v1/admin/*` | Admin endpoints |

**Exception — Azure Functions health check:**

Azure Functions HttpTrigger routes retain the `/api/` prefix (e.g., `GET /api/health`). This is a Functions host runtime convention — the Functions host prepends `/api/` to all HttpTrigger routes by default. The `HealthCheckFunction` lives at `GET /api/health` because that is how the Functions runtime works, not because of an application design choice. Container Apps health probes are configured to target `/api/health` for the Functions container.

#### Consequences

- Good, because consumer-facing URLs are clean and concise (`/v1/cfps` vs. `/api/v1/cfps`).
- Good, because no disambiguation prefix is needed when API and Web are separate containers.
- Good, because decision is made before implementation — zero migration cost, zero breaking changes.
- Good, because APIM imports the canonical OpenAPI spec — updating the spec automatically propagates path changes to APIM.
- Good, because local Aspire development is unaffected — service discovery is host-level, not path-level.
- Neutral, because Azure Functions health endpoint retains `/api/` by Functions host convention — this is expected and documented.
- Bad, because deviates from ASP.NET Core default convention — developers familiar with the convention may initially expect `/api/` prefix. Mitigated by team documentation and PR review.

#### Implementation

1. All ASP.NET Core controller route attributes in `CFPCompass.Api` use `[Route("v1/...")]` — no `/api/` prefix.
2. The canonical OpenAPI spec (`docs/api/openapi/cfp-compass-api-v1.yaml`) uses `/v1/` path prefix for all endpoints.
3. APIM imports the OpenAPI spec directly — no manual APIM path configuration needed.
4. Architecture documentation route tables updated to `/v1/*` notation.
5. Azure Functions `HealthCheckFunction` remains at `GET /api/health` — no change to Functions routing.

#### Confirmation

- Controller route attributes verified to use `[Route("v1/...")]` pattern in code review.
- OpenAPI spec paths validated by Spectral linting in CI.
- APIM import confirmed to serve routes at `/v1/*` after spec import.
- Functions health check confirmed accessible at `GET /api/health` via Container Apps probe.

#### Stakeholders

- **Dallas (Lead & Architect):** Decision owner; identified unnecessary prefix in topology review
- **Chad Green (Project Lead):** Confirmed decision
- **Ripley (Backend):** Implements controller route attributes
- **Parker (DevOps):** Confirms APIM import and Container Apps probe configuration

## Pros and Cons of the Options

### Keep `/api/v1/` Prefix

- Good, because follows ASP.NET Core default convention — familiar to .NET developers.
- Good, because no decision or documentation change needed.
- Bad, because prefix carries zero information in CFP Compass topology (dedicated API container, no pages).
- Bad, because adds noise to consumer-facing URLs.
- Bad, because perpetuates a convention that doesn't apply to this deployment model.

### Remove `/api/` Prefix (Chosen)

- Good, because eliminates unnecessary noise from all API paths.
- Good, because aligns URL structure with deployment topology (dedicated API container).
- Good, because zero migration cost when done before implementation.
- Good, because APIM-driven ingress means backend path structure is internal — no external breaking change risk.
- Bad, because deviates from ASP.NET Core default — requires team awareness. Mitigated by ADR documentation.

## More Information

The `/api/` prefix convention originates from ASP.NET MVC/Web API projects where API controllers and Razor page routes coexisted on the same host. In containerized, API-gateway-fronted architectures, this disambiguation is unnecessary. The prefix is a historical artifact of monolithic hosting, not a meaningful architectural constraint.

APIM is the canonical API surface for external consumers. The OpenAPI spec defines the contract. Backend route structure is an implementation detail that does not affect the consumer experience — APIM's backend URL forwarding maps the spec paths to the container paths transparently.

## Timing Note

This decision is made before any API controllers or OpenAPI specs are implemented. Renaming routes after controllers, specs, APIM policies, integration tests, and API consumer documentation are written would be significantly more disruptive and would risk introducing bugs across multiple layers. The cost of this decision now is a single ADR; the cost later would be a coordinated multi-file rename.

## Record History

* **Proposed**: 2026-02-28
* **Accepted**: 2026-02-28
* **Last Reviewed**: 2026-02-28
