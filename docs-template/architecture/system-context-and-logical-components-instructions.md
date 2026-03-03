# System Context & Logical Components – Authoring Instructions

This document provides section-by-section guidance for authoring a System Context & Logical Components document. It explains the intent, required inputs, assumptions, and prohibited content for each section to ensure consistency, clarity, and architectural rigor.

---

## Document Purpose and Scope

The System Context & Logical Components document establishes **where a service fits within its ecosystem** and **how it is logically decomposed**. It focuses on **structural clarity**, not behavioral flows or implementation details.

**Key Principles:**

- **Boundaries over behavior**: Define what's in-scope vs. out-of-scope, not how things work
- **Logical over physical**: Describe conceptual responsibilities, not deployment topology
- **Durable over transient**: Capture the architectural intent that survives implementation changes
- **Explicit over implicit**: State assumptions, exclusions, and ownership clearly

This document supports architectural review, cross-team alignment, and governance. It should be written **before** detailed specifications, process flows, or infrastructure definitions.

---

## Section 1: Purpose

### Intent

Establish what this document is, what it intentionally excludes, and who should read it. Set clear expectations about scope and provide navigational context to companion documents.

### Required Inputs

- Service name and acronym
- High-level service role (platform vs. domain, publisher vs. consumer, etc.)
- List of excluded topics (process flows, schemas, deployment, operations, etc.)
- List of companion documents with links
- Target audience (architects, developers, stakeholders)

### Assumptions

- Readers understand the broader ecosystem context
- Companion documents exist or are planned
- The service has a defined, bounded responsibility

### Guidance

- **Opening**: Define the service and the document's purpose clearly and concisely
- **Focus statement**: Describe what the document focuses on (structural clarity, boundaries)
- **Exclusions list**: Use bullet points, be explicit about all major topics intentionally not covered
- **Companion documents**: Link to Architecture Guide, contracts, operations, etc.
- **Audience statement**: Who needs this document and why
- **Closing question**: "What is [Service], where does it sit, what are its responsibilities?"

### Prohibited Content

- Step-by-step process flows or operational procedures
- Implementation details or technology choices
- Event schemas or API contracts
- Deployment topology or infrastructure configuration

---

## Section 2: System Context Overview

### Intent

Position the service within its ecosystem. Clarify whether it's a platform service, domain service, publisher, consumer, or broker. Establish integration boundaries and delivery semantics that shape downstream design.

### Required Inputs

- Service classification (platform-level vs. domain-level, publisher vs. consumer, etc.)
- Ecosystem name and key characteristics
- Upstream interaction pattern (where data/signals originate)
- Downstream interaction pattern (who consumes from this service)
- Delivery semantics (at-least-once, eventual consistency, sync vs. async, etc.)
- Clear separation of concerns (what upstream/this service/downstream each own)

### Assumptions

- The service has clearly defined upstream and downstream dependencies
- Integration patterns are intentional and architecturally significant
- Delivery semantics are known and documented

### Guidance

- **Opening**: State service type and ecosystem positioning clearly
- **Bullet list**: List key characteristics from a system context perspective
- **Upstream description**: Describe who produces data/signals this service depends on with sufficient context to understand the integration pattern
- **Downstream description**: Describe who consumes from this service with sufficient context to understand consumption patterns
- **Delivery semantics**: Describe at-least-once, ordering, replay, backfill, etc. (if applicable)
- **Separation of concerns**: Explicitly state what upstream/service/downstream each own
- **Strategic outcome**: Explain what this positioning enables
- **Diagram**: Include a high-level Mermaid system context diagram showing upstream, this service, and downstream

### Prohibited Content

- Internal component details (covered in Logical Component Model)
- Process flows or sequence diagrams
- API signatures or event schemas
- Infrastructure or deployment details

---

## Section 3: Upstream Systems (Sources)

### Intent

Identify the authoritative sources this service depends on. Establish clear responsibility boundaries: what upstream systems own vs. what this service owns.

### Required Inputs

- List of upstream systems with descriptions
- Each system's role and what it is authoritative for
- Source system responsibilities (table or bullet list)
- Explicit non-responsibilities for source systems
- Rationale for integration boundaries (e.g., why connect to System A not System B)

### Assumptions

- Upstream systems are external to this service (not internal components)
- Upstream systems have defined ownership and accountability
- Integration boundaries are architecturally significant

### Guidance

- **Opening**: Define what upstream systems are in the context of this service
- **Per-system subsection**: Describe each upstream system's role, what it owns, and how it relates to this service with enough detail to understand the integration boundary
- **Responsibility table**: List what source systems ARE responsible for and what they are NOT responsible for
- **Rationale** (optional): Explain architectural decisions like "why connect to JET Enterprise instead of DataFlex"

### Prohibited Content

- Internal component dependencies (those go in Logical Component Model)
- Detailed API contracts or schemas
- Deployment topology or network configuration
- Consumer-facing behavior

**Note**: Platform services (like publishers or brokers) typically provide more detail here than domain services.

---

## Section 4: Downstream Consumers

### Intent

Identify who consumes from this service and establish clear consumer responsibilities. Demonstrate that the service supports independent, decoupled consumers.

### Required Inputs

- List of initial consumers with descriptions
- Each consumer's usage pattern
- Future consumer strategy
- Consumer responsibilities (table or bullet list)
- Explicit non-responsibilities for consumers

### Assumptions

- Consumers are external to this service (not internal components)
- Consumers operate independently and do not coordinate with each other
- The service is designed for multiple consumers, not shaped around one

### Guidance

- **Opening**: Define downstream consumers in the context of this service
- **Initial Consumers subsection**: Describe each consumer, their usage pattern, and how they benefit with enough context to understand their relationship to this service
- **Future Consumers subsection**: Explain how new consumers onboard without changing upstream or existing consumers
- **Responsibility table**: List what consumers ARE responsible for and what they are NOT responsible for
- **Optional reference**: Link to detailed consumer guidance or contract documentation

### Prohibited Content

- Consumer implementation details
- Internal component behavior
- Event schemas or API contracts (reference them, don't repeat them)
- Deployment or infrastructure details

**Note**: Platform services emphasize consumer independence and responsibility boundaries more than domain services.

---

## Section 5: Logical Component Model

### Intent

Decompose the service into logical responsibilities. Clarify what each component does and what it does NOT do. Provide a stable mental model for architectural reasoning that survives implementation changes.

### Required Inputs

- List of logical components (typically 3-6)
- For each component:
  - Primary responsibility
  - Specific scope (bullet list)
  - Operational principles or behavioral characteristics
  - Explicit out-of-scope items
  - Core question the component answers
- Logical component diagram (Mermaid)
- Diagram notes explaining architectural intent

### Assumptions

- Logical components represent conceptual responsibilities, not physical services
- Components may be combined, split, or restructured at implementation level
- The model is durable and supports governance

### Guidance

- **Opening paragraph**: Explain clearly that this is a LOGICAL decomposition, not physical
- **Diagram**: Show logical components, their relationships, and optional cross-cutting concerns (security, observability)
- **Diagram note**: Use a `> [!NOTE]` callout to explain key architectural separations shown in the diagram
- **Per-component subsection**:
  - **Responsibility statement**: What this component is responsible for
  - **Scope bullet list**: Specific responsibilities
  - **Operational description**: How it operates, what principles guide it
  - **Out-of-scope bullet list**: What it does NOT do
  - **Core question**: "This component exists to answer: [question]"

### Prohibited Content

- Physical deployment units or infrastructure
- Implementation technology choices (unless architecturally significant)
- Detailed algorithms or business rules
- Process flows or sequence diagrams

**Note**: Platform services often describe 5-6 components with cross-cutting concerns. Domain services may describe 2-3 physical components (WebAPI, Function App) plus data models and event contracts.

---

## Section 6 (Optional): Data Flow Summary

### Intent

For domain services with complex operational flows, provide a step-by-step narrative of how data moves through the system. This bridges system context and logical components for implementation-focused readers.

### When to Include

- Domain services with multi-step workflows
- Services where operational flow clarifies architectural intent
- Services with asynchronous processing, projections, or integrations

### When to Exclude

- Platform services (they describe capabilities, not flows)
- Services where flow is trivial or obvious
- Services where detailed process flows exist in separate documents

### Guidance

- **Numbered list**: Each step represents a significant data flow milestone
- **Per step**: Briefly describe what happens and identify actors/systems involved
- **Focus**: What happens, not how it's implemented
- **Cross-reference**: Link to detailed process flow documents if they exist

---

## Section 7 (Optional): Ownership & Responsibility Boundaries

### Intent

For platform services, explicitly capture who owns what across the integration boundary. This section eliminates ambiguity during failures, evolution, or governance decisions.

### When to Include

- Platform services (publishers, brokers, shared infrastructure)
- Services with complex multi-team ownership
- Services where responsibility boundaries are frequently questioned

### When to Exclude

- Domain services with clear single-team ownership
- Services where boundaries are obvious from context

### Guidance

- **Ownership statements**: "[Entity] owns [responsibility]" - cover all significant ownership boundaries
- **Team-level ownership**: Platform teams vs. publishing teams vs. consuming teams
- **Intentionality note**: "These boundaries are intentional and eliminate ambiguity..."

---

## Section 8 (Optional): Evolution

### Intent

For domain services, describe how the logical component model supports future expansion. Guide future architects on how to extend the service without violating architectural intent.

### When to Include

- Domain services expected to grow or extend
- Services with established extension patterns
- Services where future capability is partially planned

### When to Exclude

- Platform services (they describe stable capabilities)
- Services with no planned evolution
- Greenfield services without established patterns

### Guidance

- **Opening**: "The logical component model is designed for incremental expansion..."
- **Extension patterns**: Bullet list of typical extension points
- **Examples**: "New scanning workflows will require..."

---

## Section 9: Summary

### Intent

Reinforce key takeaways: boundaries, responsibilities, and the value of this architectural model. Conclude with a forward-looking statement about what this document enables.

### Required Inputs

- Restatement of separation of concerns
- Strategic outcome enabled by this model
- Value proposition of the logical components
- Forward reference to what this document supports

### Guidance

- **Concise summary**: Summarize the system context and logical component model
- **Strategic outcome**: What does this architecture enable?
- **Forward reference**: "This document provides the foundation for [specifications, operations, etc.]"

### Prohibited Content

- New information not already covered
- Implementation details
- Operational procedures

---

## Formatting and Style Conventions

### Diagrams

- Use **Mermaid** for all diagrams (flowchart LR preferred)
- Label subgraphs clearly (Upstream Systems, This Service, Downstream Consumers)
- Use dashed lines for cross-cutting concerns
- Include notes explaining architectural intent

### Headings

- Use `##` for major sections, `###` for subsections
- Keep headings concise and descriptive
- Use optional section markers: `## [Optional Section: Name]`

### Lists

- Use **bullet lists** for characteristics, responsibilities, and scope
- Use **numbered lists** for data flow steps
- Keep list items parallel in structure

### Emphasis

- **Bold** for key terms, service names, and emphasis
- *Italics* for clarification or architectural nuance
- `Code formatting` for service acronyms in diagrams only

### Completeness Guidance

- **Platform services**: Emphasize Purpose, Upstream/Downstream, and Logical Components sections
- **Domain services**: Focus on concise Purpose, add Data Flow Summary and Evolution sections
- **Document length**: Let service complexity drive content length—simple services require less detail, complex services require more

---

## Cross-References and Traceability

This document should reference:

- **Architecture Guide**: For high-level architectural overview, requirements, non-functional requirements
- **Event Contracts**: For published event schemas
- **API Specifications**: For synchronous contracts
- **Operational Guides**: For deployment, monitoring, troubleshooting
- **Consumer Guides**: For backfill coordination, consumer responsibilities

Avoid duplicating content from companion documents. Link to them and summarize only what's needed for context.

---

## Common Pitfalls to Avoid

1. **Confusing logical with physical**: Components are conceptual, not deployment units
2. **Including process flows**: Save those for separate process flow documents
3. **Duplicating schemas**: Reference event contracts, don't repeat them
4. **Missing exclusions**: Always state what's NOT covered
5. **Vague boundaries**: Be explicit about what upstream/service/downstream own
6. **Consumer-specific logic**: Services should be consumer-agnostic
7. **Implementation details**: Focus on "what" and "why", not "how"

---

## Review Checklist

Before finalizing, verify:

- [ ] Purpose section lists 5+ excluded topics
- [ ] System context diagram shows upstream, service, downstream
- [ ] Upstream and downstream sections include responsibility tables
- [ ] Logical component model includes 3-6 components with explicit scope and out-of-scope
- [ ] Each component answers a core question
- [ ] Diagrams have explanatory notes
- [ ] All companion documents are referenced
- [ ] No process flows, schemas, or infrastructure details
- [ ] Summary reinforces key boundaries and strategic outcome
