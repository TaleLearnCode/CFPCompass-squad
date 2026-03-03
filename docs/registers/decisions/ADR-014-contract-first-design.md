---
title: "ADR-014: Contract-First API and Event Design"
description: Approved OpenAPI 3.1 and AsyncAPI 3.0.0 specifications must be merged before any REST or Service Bus implementation begins, establishing specs as the authoritative contract reviewed at design time.
tags:
  - adr
  - architecture-decision-record
  - openapi
  - asyncapi
status: accepted
---

# Contract-First API and Event Design

- **Status:** Accepted
- **Date:** 2026-03-01
- **Work Item:** [*arch-014* — API and event contract discipline]

## Context and Problem

CFP Compass exposes a public REST API consumed by the Blazor Server web app and available to third-party integrators, as well as an event-driven backend using Azure Service Bus topics with multiple subscribers. Without a contract-first discipline, API endpoints and Service Bus event schemas evolve organically based on whatever an implementation PR happens to produce. This leads to undocumented breaking changes, mismatched producer/consumer expectations (especially for Service Bus topics where multiple Functions subscribe to the same event), difficulty onboarding new API consumers, and APIM configuration drifting from the actual API behaviour. A formal gate — approved specification before implementation begins — is required to establish the contract as the source of truth.

## Decision Drivers

- API and event contracts must be agreed upon by all consumers before any implementation begins
- Breaking changes must be detectable — the spec, not generated documentation, is the source of truth
- APIM gateway configuration must stay in sync with the API contract automatically
- Contract review must happen at design time, not during code review when changes are costly
- All team members (frontend, backend, testers, API consumers) must align on the contract before writing code
- Both REST and event-driven contracts must be governed — Service Bus topics are as much a public interface as REST endpoints

## Considered Options

- Contract-first: approved OpenAPI 3.1 spec (REST) + approved AsyncAPI 3.0.0 spec (Service Bus) before implementation
- Code-first with auto-generated specifications (Swashbuckle / NSwag)
- OpenAPI-only contract governance (no AsyncAPI for Service Bus)

## Decision Outcome

Chosen option: **Contract-first / design-first discipline with OpenAPI 3.1 for REST and AsyncAPI 3.0.0 for Service Bus**, because it establishes specs as authoritative design artefacts reviewed before code is written, enables APIM to import the OpenAPI spec directly (closing the contract-gateway gap), and governs both REST and event-driven interfaces. The approval gate (spec PR merged → implementation PR opened) makes the contract review workflow explicit and enforceable via CI.

#### Consequences

- Good, because every new REST endpoint requires a spec PR before implementation — design review happens at the contract level, not the code review level.
- Good, because every new Service Bus topic requires an AsyncAPI spec PR before implementation — event schemas are agreed upon before producers or consumers are coded.
- Good, because APIM imports the OpenAPI spec directly during `terraform apply` — contract and gateway enforcement stay in sync automatically.
- Good, because breaking change detection via `oasdiff` is meaningful because the spec is the source of truth (not generated from code).
- Good, because all team members (frontend consumer, backend implementer, tester) align on the contract before any code is written.
- Bad, because every new endpoint or topic introduces a spec PR step before implementation — adds a workflow step that requires discipline to enforce.
- Bad, because new tooling required: Spectral (OpenAPI linting), AsyncAPI CLI (AsyncAPI validation), oasdiff (breaking change detection) — added to CI pipeline.

#### Implementation

1. **Spec file locations:**
   ```
   docs/
     api/
       openapi/
         cfp-compass-api-v1.yaml        # REST API spec (OpenAPI 3.1)
         README.md                       # Approval workflow and versioning notes
       asyncapi/
         cfp-submissions.asyncapi.yaml  # CFP submission lifecycle events (AsyncAPI 3.0.0)
         organizer-claims.asyncapi.yaml # Organizer claim events (AsyncAPI 3.0.0)
         README.md                       # AsyncAPI approval workflow notes
   ```

2. **Approval gate workflow:**
   - Author creates a spec PR modifying a file under `docs/api/`
   - PR is reviewed by Dallas (Lead) and at minimum one consumer/implementer
   - On spec PR merge, the corresponding implementation PR may be opened
   - Implementation PRs touching API routes or Service Bus producers/consumers must reference the approved spec PR in the PR description

3. **CI enforcement (Parker adds to `ci.yml`):**
   ```yaml
   - name: Lint OpenAPI spec
     run: npx @stoplight/spectral-cli lint docs/api/openapi/cfp-compass-api-v1.yaml --ruleset spectral:oas
     if: steps.changed-files.outputs.openapi_any_changed == 'true'

   - name: Validate AsyncAPI specs
     run: npx @asyncapi/cli validate docs/api/asyncapi/*.asyncapi.yaml
     if: steps.changed-files.outputs.asyncapi_any_changed == 'true'

   - name: Check for breaking changes
     run: npx oasdiff breaking docs/api/openapi/cfp-compass-api-v1.yaml HEAD~1:docs/api/openapi/cfp-compass-api-v1.yaml
     if: steps.changed-files.outputs.openapi_any_changed == 'true'
   ```

4. **APIM spec import (Parker adds to `infra/modules/apim/` Terraform module):**
   ```hcl
   resource "azurerm_api_management_api" "cfp_api" {
     import {
       content_format = "openapi"
       content_value  = file("${path.root}/../docs/api/openapi/cfp-compass-api-v1.yaml")
     }
   }
   ```

5. **AsyncAPI specs required for known Service Bus topics:**
   | Topic | AsyncAPI Spec File |
   |-------|-------------------|
   | `cfp-submission-created` | `cfp-submissions.asyncapi.yaml` |
   | `cfp-submission-updated` | `cfp-submissions.asyncapi.yaml` |
   | `cfp-submission-approved` | `cfp-submissions.asyncapi.yaml` |
   | `cfp-submission-rejected` | `cfp-submissions.asyncapi.yaml` |
   | `cfp-submission-reconsideration` | `cfp-submissions.asyncapi.yaml` |
   | `organizer-claim-requested` | `organizer-claims.asyncapi.yaml` |

#### Confirmation

- CI fails on PR if Spectral lint finds violations in OpenAPI spec files under `docs/api/openapi/`.
- CI fails on PR if AsyncAPI CLI validation fails for files under `docs/api/asyncapi/`.
- CI reports breaking changes detected by oasdiff on any OpenAPI spec modification.
- APIM `terraform apply` succeeds and imports the latest OpenAPI spec automatically.
- No implementation PR for a new endpoint is merged without a referenced, merged spec PR.

#### Stakeholders

- **Dallas (Lead & Architect):** Decision owner; enforces spec-before-implementation gate on all PRs; authors or reviews all spec PRs
- **Chad Green (Product Owner):** Contract-first process is now part of the team workflow; approved ADR-014
- **Ripley (Backend):** All API endpoint implementations conform to the approved OpenAPI spec; all Service Bus producers conform to the approved AsyncAPI spec
- **Lambert (Frontend):** API consumer code and integration use the approved OpenAPI spec as the source of truth
- **Parker (DevOps):** Adds Spectral, AsyncAPI CLI, and oasdiff to CI pipeline; configures APIM spec import in Terraform
- **Kane (Tester):** Test cases are written against the approved spec; API contract tests validate responses match spec schemas

## Pros and Cons of the Options

### Contract-First: OpenAPI 3.1 + AsyncAPI 3.0.0

- Good, because specs are design artefacts reviewed before code — design review at the right time.
- Good, because APIM imports OpenAPI spec directly — gateway and contract stay in sync automatically.
- Good, because breaking change detection is meaningful — spec is the source of truth.
- Good, because all team members align on the contract before implementation — reduces mismatched expectations.
- Good, because both REST and event-driven contracts are governed — complete interface coverage.
- Good, because Spectral and AsyncAPI CLI validation are automated in CI — spec quality enforced.
- Neutral, because spec PR step adds workflow discipline — acceptable trade-off for correctness.
- Bad, because requires new tooling (Spectral, AsyncAPI CLI, oasdiff) to be installed and maintained.
- Bad, because workflow change for the team — spec PR must precede implementation PR; requires enforcement culture.

### Code-First with Auto-Generated Specifications

- Good, because no separate spec authoring step — spec is always in sync with implementation.
- Good, because less tooling and process overhead.
- Neutral, because Swashbuckle/NSwag can produce readable OpenAPI docs.
- Bad, because auto-generated specs are documentation, not contracts — they cannot be reviewed as design artefacts.
- Bad, because breaking changes are only visible after code is written — design review is too late.
- Bad, because APIM importing an auto-generated spec means the gateway reflects whatever the implementation happens to produce, not a reviewed contract.
- Bad, because consumer (Lambert) and implementer (Ripley) may have different mental models until the code is actually running.
- Bad, because Service Bus event schemas are not expressed in OpenAPI — async contracts would remain undocumented.

### OpenAPI-Only (No AsyncAPI)

- Good, because OpenAPI 3.1 is widely understood and tooling is mature.
- Good, because REST contract governance provides significant value.
- Neutral, because reduces tooling to Spectral + oasdiff only.
- Bad, because Service Bus event schemas are undocumented — producers and consumers rely on shared knowledge or code comments.
- Bad, because producer/consumer mismatch on event schemas causes silent failures in the Functions layer.
- Bad, because partial governance — REST is covered, events are not — creates a false sense of contract completeness.

## More Information

OpenAPI 3.1 specification: https://spec.openapis.org/oas/v3.1.0

AsyncAPI 3.0.0 specification: https://www.asyncapi.com/docs/reference/specification/v3.0.0

Spectral OpenAPI linting: https://docs.stoplight.io/docs/spectral/

oasdiff breaking change detection: https://github.com/Tufin/oasdiff

AsyncAPI CLI: https://www.asyncapi.com/tools/cli

**AsyncAPI Studio** (https://studio.asyncapi.com/) is recommended for authoring AsyncAPI specs — provides visual editing and real-time validation.

The approval gate is enforced culturally (PR description must reference spec PR) and technically (CI validates spec quality). A CODEOWNERS file should designate Dallas as a required reviewer for all files under `docs/api/`.

## Follow-On Information

As the API evolves, a versioning strategy is needed before any breaking changes are introduced:
- Non-breaking changes (additive) are permitted in `cfp-compass-api-v1.yaml` with a `CHANGELOG` section in the spec.
- Breaking changes require a new spec file (`cfp-compass-api-v2.yaml`) and a new APIM API version, with a deprecation notice in v1.
- The oasdiff CI check enforces this by failing the build on breaking changes detected in an existing spec file.

## Record History

* **Proposed**: 2026-03-01
* **Accepted**: 2026-03-01
* **Last Reviewed**: 2026-03-01
