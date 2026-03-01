# Infrastructure Overview — Agent Guidance

This document provides agent-specific guidance for generating Infrastructure Overview documents using GitHub Copilot or similar tools. It defines reasoning, inference, and deferral rules for each section, ensuring outputs are reviewable, deterministic, and architecturally sound.

---


## YAML Frontmatter
- Always begin the document with a YAML frontmatter block specifying:
	- `title`: The document title (e.g., "Infrastructure Overview")
	- `summary`: A one-sentence description of the infrastructure overview's scope
	- `tags`: A list of tags including:
		- `infrastructure-overview` (Required)
		- `architecture` (Required)
		- [domain-specific tags] (e.g., integration, cloud, platform)
		- [capability tags] (e.g., governance, security, observability)
- Do not generate section content or instructions in the YAML block. Follow the canonical format used in other architecture documents.

## Section Prompts
- Each section should include a comment with the recommended prompt for agent-assisted population, referencing the instructions and agent guidance.

---

## General Principles
- Always follow the deterministic template structure and section order.
- Never introduce service-specific or implementation details unless explicitly provided.
- Use only canonical architectural vocabulary and patterns.
- When uncertain, defer to human architects and request clarification.
- Ensure each section is self-contained and reviewable.

---

## Section-by-Section Guidance

### Purpose & Scope
- **Recall-based:** Use provided context or prompt. If unclear, request clarification.
- **Inference:** Do not infer business context; defer to human input.

### Deployment Model & Environments
- **Recall-based:** Use explicit environment definitions if available.
- **Inference:** May infer standard environment progression (DEV, QA, PROD) if not specified, but flag assumptions.
- **Deferral:** If environment strategy is ambiguous, request clarification.

### Azure Subscription & Resource Group Strategy
- **Recall-based:** Use provided naming/tagging conventions.
- **Inference:** May suggest standard patterns if none are given, but highlight as assumptions.
- **Deferral:** Do not invent subscription details; defer if not provided.

### Core Infrastructure Components
- **Recall-based:** List only resources described in the prompt or context.
- **Inference:** May suggest typical resource categories (compute, storage, networking) if context is generic, but mark as assumptions.
- **Deferral:** Do not invent resource specifics; request input if unclear.

#### Owned Resources
- **Recall-based:** Populate only with resources explicitly owned by the team.
- **Inference:** If ownership is unclear, request clarification.

#### Shared Platform Resources
- **Recall-based:** Populate only with resources managed by platform or shared teams.
- **Inference:** If sharing model is unclear, request clarification.

### Network & Connectivity Model
- **Recall-based:** Use provided network architecture.
- **Inference:** May suggest standard Azure connectivity patterns if not specified, but flag as assumptions.
- **Deferral:** Do not invent network details; defer if ambiguous.

### Identity & Access Model
- **Recall-based:** Use explicit identity and access models.
- **Inference:** May suggest managed identity and RBAC if not specified, but highlight as assumptions.
- **Deferral:** Request clarification if access boundaries are unclear.

### Observability & Diagnostics Strategy
- **Recall-based:** Use provided observability tools and policies.
- **Inference:** May suggest standard Azure monitoring/logging if not specified, but flag as assumptions.
- **Deferral:** Defer if observability requirements are ambiguous.

### Data Retention & Compliance
- **Recall-based:** Use explicit retention and compliance requirements.
- **Inference:** May suggest standard retention periods if not specified, but mark as assumptions.
- **Deferral:** Request clarification if compliance needs are unclear.

### Scalability & Performance Characteristics
- **Recall-based:** Use provided scaling and performance strategies.
- **Inference:** May suggest standard Azure scaling mechanisms if not specified, but flag as assumptions.
- **Deferral:** Defer if performance requirements are ambiguous.

### Disaster Recovery & Business Continuity
- **Recall-based:** Use explicit recovery objectives and strategies.
- **Inference:** May suggest standard Azure DR patterns if not specified, but highlight as assumptions.
- **Deferral:** Request clarification if DR/BC requirements are unclear.

### Non-Goals & Constraints
- **Recall-based:** Use only explicit non-goals and constraints.
- **Inference:** Do not invent non-goals; defer to human input if not provided.

### Security & Compliance
- **Recall-based:** Use provided security and compliance mechanisms.
- **Inference:** May suggest standard Azure security practices if not specified, but flag as assumptions.
- **Deferral:** Defer if security requirements are ambiguous.

### Related Documents
- **Recall-based:** Reference only documents explicitly provided or linked.
- **Inference:** Do not invent related documents.

---

## Handling Uncertainty & Incomplete Inputs
- Clearly flag any assumptions made in the absence of explicit information.
- When required information is missing, request clarification from the human author or architect.
- Never fabricate details or invent content beyond standard architectural patterns.

## Review & Approval
- Ensure all agent-generated content is reviewable section-by-section.
- Defer final approval and ownership to human architects.
- Follow any additional review criteria or checklists provided in the instructions.
