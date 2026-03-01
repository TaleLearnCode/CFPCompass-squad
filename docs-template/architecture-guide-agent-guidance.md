# Architecture Guide – Agent Guidance

This guidance is intended for use with GitHub Copilot (in VS Code and Visual Studio 2026) to enable consistent, agent-assisted authoring of Architecture Guide documents. It specifies which sections require recall-based content (from provided sources), which permit reasoning-based synthesis, when inference is allowed, and when to request human clarification or defer to architects.

---

## General Principles

**Recall vs. Reasoning:**
- **Recall-based sections** should synthesize content directly from provided sources (requirements documents, business briefs, existing systems). Do not invent or assume content.
- **Reasoning-based sections** permit the agent to synthesize, analyze, and propose architectural perspectives based on provided inputs. However, reasoning must remain grounded in provided context.
- **When in doubt, defer to human architects.** Architecture is ultimately a human decision; the agent's role is to organize, clarify, and synthesize—not to make irreversible commitments.

**Handling Incomplete Inputs:**
- If critical information is missing, the agent should ask clarifying questions rather than assume or fill gaps.
- If the user provides minimal context, suggest a structured approach (e.g., "Please provide: business problem, key constraints, external systems").
- If contradictions arise in provided information, flag them and ask the user to clarify.

**Deferral Decisions:**
- Defer when:
  - Business context or strategy is unclear.
  - Requirements are contradictory or under-specified.
  - Security or compliance implications are uncertain.
  - Architectural trade-offs have significant cost or risk implications.
  - The service's relationship to other systems is ambiguous.

---

## Section-by-Section Guidance

### YAML Header (Front Matter)
**Type:** Recall-based  
**Agent Behavior:**
- Ask the user to provide: document title, plain-language summary, and relevant tags.
- Tags should be canonical (e.g., `architecture`, `guide`, `[service-name]`, `[domain]`).
- Do not invent tags; use only those provided or suggested by the user.

**When to Defer:**
- If the user cannot articulate a summary, ask them to describe the service's primary purpose first.

---

### Purpose & Audience
**Type:** Mixed (recall + reasoning)  
**Agent Behavior:**
- **Recall:** Ask the user to identify which stakeholders/roles are the primary audience (e.g., architects, developers, ops, management).
- **Reasoning:** Synthesize a brief statement of the document's role in the architecture set based on the audience identified.
- Inference is permitted: if the user identifies "developers and architects," you can infer that the guide should balance business context with technical clarity.

**Constraints:**
- Do not assume the audience without asking. Different services have different stakeholder groups.
- Keep the purpose statement brief and role-focused; do not duplicate content from Business Purpose.

**When to Defer:**
- If the user is uncertain about the primary audience, suggest a canonical set and ask them to confirm.

---

### Business Purpose
**Type:** Mixed (recall + reasoning)  
**Agent Behavior:**
- **Recall:** Ask the user for: business problem, target users/customers, strategic value, key business outcomes.
- **Reasoning:** Synthesize these inputs into a cohesive narrative that explains *why the service exists*.
- Inference is permitted: if the user states "reduce order processing time by 40%," you can infer this is a performance and efficiency driver.

**Constraints:**
- Focus on business outcomes, not technical solutions. (e.g., "enable faster order fulfillment" vs. "use event-driven architecture").
- Avoid assuming business context if not provided. Ask clarifying questions.
- Keep this section non-technical and accessible to product and business stakeholders.

**When to Defer:**
- If business strategy or direction is unclear, ask the user to consult with product/business leadership.
- If competitive or market dynamics are relevant, ask the user to provide that context.

---

### Architectural Overview
**Type:** Primarily reasoning-based (grounded in provided inputs)  
**Agent Behavior:**
- **Input Requirements:** The user should provide or confirm: business requirements, external systems/dependencies, key constraints (performance, availability, cost).
- **Reasoning:** Synthesize a high-level architecture (patterns, design principles, major components) that addresses the provided requirements.
- **Inference is permitted:** Based on typical patterns (event-driven for async workflows, microservices for scalability), propose architecture that fits the requirements. However, always ask the user to confirm or refine.

**Constraints:**
- Architecture should be justified by requirements stated in the guide, not assumed.
- Avoid detailed implementation specifics; stay at the "major structural elements" level.
- If requirements are contradictory or unclear, flag this and ask the user for clarification before proposing architecture.

**When to Defer:**
- If requirements are ambiguous (e.g., "we need to be scalable" without targets), ask for specificity.
- If multiple architectural approaches seem equally valid, present options and defer choice to the architect.
- If the architecture implies significant cost, risk, or operational complexity, flag this for architect review.

---

### Solution Context
**Type:** Mixed (recall + reasoning)  
**Agent Behavior:**
- **Recall:** Ask the user to provide a map of external systems, their roles, and integration points. Ask: "What systems does this service depend on? What systems depend on this service?"
- **Reasoning:** Synthesize system boundaries and context relationships based on the provided information.
- **Inference is permitted:** If the user identifies external systems, you can infer which are upstream (inputs to this service) and downstream (consumers). You can suggest what should be within vs. outside the service boundary.

**Constraints:**
- Base boundaries on the service's responsibility, not implementation convenience.
- Do not assume integrations; ask the user to confirm external dependencies.
- Keep this section high-level; detailed API contracts belong elsewhere.

**When to Defer:**
- If the user is uncertain about system boundaries or relationships, suggest a context diagram conversation and defer until that is clear.
- If external systems are under-specified, ask the user to provide more detail or confirm assumptions with system owners.

---

### Key Requirements
**Type:** Recall-based  
**Agent Behavior:**
- Ask the user to provide or reference source requirements documents. This section should *summarize* requirements that have architectural impact, not list all requirements.
- Organize by category (functional, scalability, reliability, integration).
- Always reference the source document; e.g., "Per [requirements document], the service must support 10K orders/min".

**Constraints:**
- Do not invent requirements. All content must come from provided sources.
- Do not include implementation-level requirements (e.g., "use Redis for caching"); focus on outcomes (e.g., "sub-100ms response time").
- Only include requirements that *shape the architecture*; operational SLAs or project constraints belong elsewhere.

**When to Defer:**
- If requirements are missing or unclear, ask the user to consult the source requirements document or stakeholders.
- If requirements seem unrealistic or contradictory, flag this and ask the architect to clarify priorities.

---

### Security and Compliance
**Type:** Mixed (recall + reasoning)  
**Agent Behavior:**
- **Recall:** Ask the user for: applicable compliance standards (e.g., GDPR, PCI DSS, SOC 2), security policies, and data sensitivity.
- **Reasoning:** Synthesize a summary of how compliance and security shape architectural decisions. E.g., "because customer data must be encrypted at rest, all databases use service-managed encryption keys."
- **Inference is permitted:** Based on compliance standards, you can propose typical security patterns (encryption, audit logging, access control). However, non-standard or high-stakes decisions should be deferred.

**Constraints:**
- Do not invent compliance requirements; base this on provided standards.
- Focus on architectural implications, not operational procedures. (e.g., "encryption at rest" vs. "backup procedures").
- Avoid cryptographic or security design details; those belong in a dedicated security architecture document.

**When to Defer:**
- If compliance or security standards are unclear, ask the user to consult security/legal teams.
- If security decisions involve significant trade-offs (cost, performance, complexity), defer to the security architect.
- If the service handles sensitive data (PII, payment info, classified), defer detailed security design to a security architecture specialist.

---

### Non-Functional Requirements
**Type:** Recall-based (with reasoning for implications)  
**Agent Behavior:**
- **Recall:** Ask the user to provide performance, scalability, availability, and maintainability targets. E.g., "What response time targets? What peak throughput? What availability SLA?"
- **Reasoning:** Briefly note how these requirements drive architecture. E.g., "99.9% availability requires multi-zone deployment and failover."
- **Inference is limited:** You can note implications, but targets themselves must come from the user or source documents.

**Constraints:**
- Only include non-functional requirements that *influence architectural choices*.
- Provide specific targets (measurable, testable) rather than vague statements (e.g., "sub-100ms for p99 response time" not "fast").
- Operational metrics and SLAs are secondary; focus on architectural drivers.

**When to Defer:**
- If targets are missing or seem unrealistic, ask the user for clarification.
- If a non-functional requirement creates a tension with another, flag this for architect review.

---

### Appendices / References
**Type:** Recall-based  
**Agent Behavior:**
- Ask the user to identify which companion documents exist for this service (e.g., System Context, Security Architecture, Operations Guide).
- For each document, confirm the file name, location, or reference.
- Ask the user to identify the names/locations of the risk register, assumption register, and ADR register.
- Create a structured list with brief annotations of each reference.

**Constraints:**
- Do not invent or assume document names or locations. Confirm with the user.
- This is a *reference only section*; do not duplicate register content here.
- Use consistent naming and link formats for future document consumption.

**When to Defer:**
- If some documents haven't been authored yet, note this (e.g., "Security Architecture: [pending]") and defer to the user to add references later.

---

## Interaction Patterns for Copilot

### Initial Conversation
When a user requests an Architecture Guide, Copilot should:
1. Ask the user for the service name.
2. Ask for a brief description of what the service does.
3. Ask which sections the user wants to focus on or whether they want to author the full document.
4. Suggest an order: start with Purpose & Audience, then Business Purpose, then gather requirements before proposing architecture.

### Iterative Refinement
- After drafting a section, ask the user for feedback: "Does this capture the business purpose accurately?" or "Should we add/remove any architectural principles?"
- If the user revises inputs (e.g., new requirements), propagate the implications through downstream sections.
- Offer to re-synthesize sections if upstream context changes.

### Handling Gaps
- When critical information is missing, pause and ask before synthesizing. E.g., "I have security and compliance requirements, but I don't see non-functional requirements. Should I assume a generic SLA, or do you have targets?"
- Suggest structured prompts if the user seems stuck: "To build the Architectural Overview, I need to understand: (1) What's the primary scalability driver? (2) What's the reliability/availability requirement? (3) Are there integration constraints?"

### Clarity and Alternatives
- When proposing architecture, present the reasoning: "Based on your requirement to handle 10K orders/min *and* integrate with external warehouses asynchronously, I'm suggesting an event-driven architecture. Does this align with your strategy?"
- Offer alternatives when multiple approaches are viable, but make a recommendation grounded in the requirements.

---

## Prohibited Actions

Copilot should **not:**
- Invent requirements, business context, or compliance standards without user confirmation.
- Make irreversible architectural decisions without explicit user approval.
- Assume technology choices (databases, frameworks, platforms) are fixed for this service.
- Duplicate content from companion documents (e.g., copy requirements from a detailed requirements doc).
- Fill in missing inputs with plausible-sounding but unconfirmed assumptions.
- Override explicit guidance from architects or product stakeholders.

---

## Summary

The Architecture Guide is a **navigational and contextual document**—it should help readers understand *why* a service exists and *how* it's logically structured, without prescribing implementation details. Copilot's role is to organize, synthesize, and clarify provided context, not to make architectural strategy decisions. Always defer when in doubt.
