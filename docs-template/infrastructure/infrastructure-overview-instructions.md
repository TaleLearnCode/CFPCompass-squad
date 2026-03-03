# Infrastructure Overview Instructions

This document provides section-by-section guidance for authoring the Infrastructure Overview. It defines the intent, expected inputs, and constraints for each section. Use these instructions to ensure consistency, clarity, and reviewability.

---


## YAML Frontmatter
- **Intent:** Every Infrastructure Overview document must begin with a YAML frontmatter block specifying the document title, a one-sentence summary, and a set of tags.
- **Inputs:**
	- `title`: The document title (e.g., "Infrastructure Overview")
	- `summary`: A one-sentence description of the infrastructure overview's scope
	- `tags`: A list of tags including:
		- `infrastructure-overview` (Required)
		- `architecture` (Required)
		- [domain-specific tags] (e.g., integration, cloud, platform)
		- [capability tags] (e.g., governance, security, observability)
- **Constraints:** Do not add section content or instructions in the YAML block. Follow the canonical format used in other architecture documents.

## Section Prompts
- **Intent:** Each section should include a comment with the recommended prompt for agent-assisted population, referencing the instructions and agent guidance.
---

## Purpose & Scope
- **Intent:** State the overall purpose of the infrastructure overview and its intended audience. Define what is covered and what is explicitly out of scope.
- **Inputs:** Business context, architectural goals, audience roles.
- **Constraints:** Do not include deployment procedures or implementation details.

## Deployment Model & Environments
- **Intent:** Describe the deployment topology, environment progression (e.g., DEV, QA, PROD), and rationale for environment separation.
- **Inputs:** Environment definitions, deployment strategies, region selection.
- **Constraints:** Avoid step-by-step deployment instructions.

## Azure Subscription & Resource Group Strategy
- **Intent:** Explain how resources are organized into subscriptions and resource groups, including naming and tagging conventions.
- **Inputs:** Subscription model, resource group patterns, governance requirements.
- **Constraints:** Do not include subscription IDs or sensitive details.

## Core Infrastructure Components
- **Intent:** List and categorize all major infrastructure resources, distinguishing between owned and shared components. Provide rationale for each.
- **Inputs:** Resource inventory, ownership boundaries, architectural decisions.
- **Constraints:** Avoid implementation specifics or code references.

### Owned Resources
- **Intent:** Detail resources provisioned and operated by the owning team.
- **Inputs:** Resource types, purpose, operational responsibility.
- **Constraints:** No service-specific configuration.

### Shared Platform Resources
- **Intent:** Describe resources managed centrally or shared across services.
- **Inputs:** Shared services, platform-managed components.
- **Constraints:** No implementation or access details.

## Network & Connectivity Model
- **Intent:** Summarize network architecture, connectivity patterns, and security boundaries.
- **Inputs:** Network diagrams, connectivity requirements, security controls.
- **Constraints:** Do not include IP addresses or firewall rules.

## Identity & Access Model
- **Intent:** Explain authentication and authorization models, including use of managed identities and RBAC.
- **Inputs:** Identity types, access boundaries, permission models.
- **Constraints:** No user lists or credential details.

## Observability & Diagnostics Strategy
- **Intent:** Describe monitoring, logging, and alerting strategies for the infrastructure.
- **Inputs:** Observability tools, telemetry flows, alerting policies.
- **Constraints:** Avoid operational runbooks or alert recipient lists.

## Data Retention & Compliance
- **Intent:** Define data retention policies, compliance requirements, and data protection measures.
- **Inputs:** Retention periods, compliance standards, data types.
- **Constraints:** No sensitive data or legal advice.

## Scalability & Performance Characteristics
- **Intent:** Explain how the infrastructure scales and meets performance requirements.
- **Inputs:** Scaling strategies, performance targets, bottleneck considerations.
- **Constraints:** No benchmarking data or tuning scripts.

## Disaster Recovery & Business Continuity
- **Intent:** Outline recovery objectives, backup strategies, and failover procedures.
- **Inputs:** RTO/RPO targets, backup mechanisms, recovery plans.
- **Constraints:** No step-by-step recovery instructions.

## Non-Goals & Constraints
- **Intent:** Explicitly state what is not covered or intended by the infrastructure, and document key constraints.
- **Inputs:** Out-of-scope items, architectural boundaries, known limitations.
- **Constraints:** Avoid negative language; focus on clarity.

## Security & Compliance
- **Intent:** Summarize security controls, authentication, authorization, and compliance mechanisms.
- **Inputs:** Security standards, compliance frameworks, access models.
- **Constraints:** No confidential or implementation-specific details.

## Related Documents
- **Intent:** Reference supporting or related architecture artifacts.
- **Inputs:** Document titles, links, or locations.
- **Constraints:** Do not duplicate content from referenced documents.

---

**General Guidance:**
- Use canonical architectural vocabulary.
- Avoid service-specific or implementation details.
- Ensure each section is reviewable and self-contained.
- Do not embed tool-specific instructions or behavior.
