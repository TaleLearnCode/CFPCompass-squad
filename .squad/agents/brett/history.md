# Brett — Project Knowledge

## Project

**CFP Compass** — .NET 10 / C# web application aggregating open Calls for Papers for community speakers.

- **Stack:** .NET 10, C#, Azure Container Apps, Azure SQL / Cosmos DB, Azure Functions, Terraform, GitHub Actions, Azure AD B2C
- **Lead:** Chad Green
- **Team:** Dallas (Lead), Ripley (Backend), Lambert (Frontend), Parker (DevOps), Kane (Tester), Brett (Requirements)

## Core Context

### Personas
- **Speaker** — browses CFPs, filters by topic/date, favorites them, gets deadline reminders
- **Organizer** — submits a new CFP via public form; waits for admin approval
- **Admin** — reviews submitted CFPs, approves or rejects them; approved entries go live
- **API Consumer** — authorized third party reading/writing CFP data via the public REST API

### Core Features
- Public CFP listing with filtering, sorting, and detail pages
- Organizer submission form (no account required, or account required — TBD)
- Admin moderation workflow (approve / reject with optional feedback)
- User accounts: favorites, deadline reminder preferences
- Email: deadline reminders + weekly digest (new + closing CFPs)
- Public REST API: authenticated, versioned, GET/POST/PUT

## Learnings — Archive (v2 early work)

Early v2 work (Feb 2026): Initial requirements breakdown v1 → v2 with resolved decisions → v3 data model expansion with ISO standards + speaker tracking states + taxonomy → v3.1 submitter/organizer distinction + claim flow → v3.2 full taxonomy + multi-select categories/topics. Consolidated into Core Context above. See git history for granular change records.


### 2026-03-01 — Requirements v3.3: Observability & Developer Experience NFRs

**Task:** Chad Green directed adoption of .NET Aspire 13.1. Added NFR-1 (Observability) and NFR-2 (Developer Experience) to requirements.md.

**Key Decisions:**
- NFR-1: `/health` endpoint on every service; traces correlated by ID across boundaries; exported to Azure Monitor
- NFR-2: Full local dev stack startable with one command; telemetry dashboard available for debugging

**Patterns Applied:**
- NFRs describe observable behavior, not implementation details
- Health endpoints and distributed tracing grounded in operator/debugger needs
- Separation of concerns: requirements define "what must work", architecture covers "how with Aspire"


### 2026-03-01 — Requirements v3.5: Contract-First API and Event Design NFR

**Task:** Chad Green directed: "APIs and events are design-driven." Added NFR-3 to establish contract-first process for both REST APIs (OpenAPI 3.1) and Service Bus events (AsyncAPI 3.0.0) before implementation begins.

**Key Changes Applied:**

**1. New NFR-3: Contract-First API and Event Design:**
   - **REST API Contracts (OpenAPI 3.1):** Every REST endpoint must have an approved OpenAPI 3.1 spec before implementation begins. Spec is reviewed via PR, merged, and serves as the contract for implementation.
   - **Service Bus Event Contracts (AsyncAPI 3.0.0):** Every Service Bus topic and message schema must have an approved AsyncAPI 3.0.0 spec before producer/consumer implementation. Known topics: CFP Submission Lifecycle (created, updated, approved, rejected, reconsideration requested) and Organizer Claim Events (claim requested, claim verified, claim completed).
   - **Approval Gate:** A specification PR must be reviewed, approved, and merged into main branch before implementation PR is opened. Implementation may not begin until spec PR is merged.
   - **Conformance:** Implemented API/event must match approved spec exactly. Deviations require spec revision and re-approval (not implementation "fixes").
   - **Breaking Changes:** Any change breaking consumers requires new version (e.g., `/api/v1/` → `/api/v2/`), new spec PR with review/approval, and deprecation period for old version.
   - **Acceptance Criteria:** 6 testable scenarios covering spec proposal → review → approval → implementation conformance → breaking change handling.

**2. Metadata Updates:**
   - Version: v3.4 → v3.5
   - Last Updated: 2026-03-01 (unchanged)
   - Added v3.5 row to Revision History table with full change description

**Patterns Applied:**
   - Surgical edit: Added NFR-3 between NFR-2 and "Resolved Decisions" section
   - Added HTML comment marker for traceability: `<!-- Updated v3.5: Added NFR-3... -->`
   - All requirements stated in observable, testable language (no tool names)
   - Acceptance criteria use Given/When/Then format
   - Specification formats (OpenAPI 3.1, AsyncAPI 3.0.0) are explicit and versioned

**Rationale:**
   - Contract-first prevents consumer-breaking changes via ad-hoc implementation decisions
   - Spec-before-code enables clear team alignment and reduces implementation rework
   - Specification pull requests provide review gate and audit trail for contracts
   - Breaking change policy ensures backwards compatibility or explicit versioning
   - Identified Service Bus topics ground the requirement in team's known architecture

**Impact:**
   - **Dallas (Lead):** All new API and event work now requires spec PR first; no implementation without approved spec
   - **Ripley (Backend):** API endpoint implementation must conform to approved OpenAPI spec; Service Bus producer implementation must conform to approved AsyncAPI spec
   - **Lambert (Frontend):** API consumer code generation and integration must use approved OpenAPI specs
   - **Parker (DevOps):** API contract documentation and versioning tracking
   - **Chad (Product):** Contract-first process now part of team workflow — protects against mid-project API breaking changes



### 2026-03-01 — Requirements v3.4: Expanded NFR-1 Health Check Requirements

**Task:** Chad Green directed: "Health check endpoints must verify both service availability AND connectivity to all required dependencies." Expanded NFR-1 with per-service dependency coverage, status semantics, HTTP codes, and Container Apps integration.

**Key Directive:**
Health endpoints must not only report "up/down" but expose per-dependency status and appropriate HTTP codes for orchestration (200 for operational, 503 for unhealthy).

**Changes Applied:**

**1. NFR-1 Complete Rewrite — Health Checks Now Include Per-Service Dependency Verification:**
   - **CfpCompass.Api:** SQL Database, Redis Cache, Service Bus
   - **CfpCompass.Web:** API service reachability
   - **CfpCompass.Workers:** SQL Database, Service Bus, Redis Cache
   - **CfpCompass.Functions:** SQL Database, Service Bus (plus `/api/health` HTTP function endpoint requirement)

**2. Health Status Semantics (3-State Model):**
   - **Healthy:** All required dependencies reachable
   - **Degraded:** Non-critical dependencies unreachable; service continues operating
   - **Unhealthy:** One or more critical dependencies unreachable; service cannot operate correctly

**3. HTTP Status Code Mapping:**
   - **200 OK:** Returned for Healthy or Degraded status
   - **503 Service Unavailable:** Returned for Unhealthy status
   - Ensures Container Apps liveness/readiness probes can correctly evaluate service state

**4. Container Apps Integration Requirement:**
   - Health endpoints must respond within ≤5 seconds
   - Compatible with Azure Container Apps probe evaluation
   - No authentication headers required

**5. New Acceptance Criteria (9 detailed scenarios):**
   - Per-service healthy state with all dependencies OK (HTTP 200)
   - Degraded state when non-critical dependency (Redis) fails (HTTP 200)
   - Unhealthy state when critical dependency (SQL) fails (HTTP 503)
   - Web service health check behavior (API reachability)
   - Functions service health check endpoint (`/api/health`)
   - Container Apps liveness probe integration (restart on 503)
   - Distributed trace correlation (end-to-end visibility)

**6. Metadata Updates:**
- Version: v3.3 → v3.4
- Last Updated: 2026-03-01
- Added HTML comment marker for traceability: `<!-- Updated v3.4: Expanded NFR-1 health checks... -->`
- Added comprehensive Revision History table (v1.0 through v3.4)

**Patterns Applied:**
- Surgical edit to NFR-1 requirement section — expanded without removing existing trace/logging requirements
- Per-service dependency lists organized in clear bulleted format
- Status semantics defined operationally (what "healthy" means to each service)
- HTTP codes tied directly to orchestration use case (probes)
- Acceptance criteria cover both happy path (all healthy) and failure modes (degraded, unhealthy)
- All new ACs follow Given/When/Then structure

**Rationale:**
- Container Apps requires explicit HTTP status codes to drive orchestration decisions (liveness restart, readiness drain)
- Per-dependency reporting enables operators to diagnose which specific resource is unhealthy without false positives
- Degraded state allows graceful degradation (e.g., cache failure shouldn't kill the service)
- Function Apps health endpoint is a new requirement — must be HTTP-triggered (not middleware) due to Functions runtime limitations

**Impact:**
- **Ripley (Backend):** Implement `/health` endpoint on API, Workers with per-dependency checks (SQL ping, Redis PING, Service Bus peek); report Healthy/Degraded/Unhealthy with HTTP 200/503; Web service must check API reachability; Functions must expose `/api/health` HTTP function
- **Lambert (Frontend):** Blazor Server health endpoint checks API reachability
- **Parker (DevOps):** Configure Container Apps liveness/readiness probes to use `/health` endpoint with appropriate timeout; verify 503 responses trigger restarts; verify 200 responses keep containers running
- **Dallas (Lead):** Review health endpoint architecture with Ripley; confirm Functions runtime compatibility with HTTP function approach
- **Kane (Tester):** Test all 9 acceptance criteria; verify dependency failure scenarios return correct HTTP codes; verify probe integration with local Container Apps emulation
- **Chad (Product):** Health endpoints now fully specified for MVP release


