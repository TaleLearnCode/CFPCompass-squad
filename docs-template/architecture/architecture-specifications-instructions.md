# Architecture Specifications: Authoring Instructions

These instructions guide authors in completing each section of the Architecture Specifications template. The Architecture Specifications document articulates the architectural design of a service: how components are organized, how they communicate, what guarantees they maintain, and how they handle failure.

## YAML Frontmatter

**Intent:** Provide metadata for documentation systems (MkDocs, static site generators) and enable searchability.

**Required Content:**
- **title:** "Architecture Specifications" (standard title for all Architecture Specifications documents)
- **summary:** 1-sentence summary of the service's architectural design (e.g., "Architectural design specifications for the Notification Service.")
- **tags:** List of relevant tags for categorization and search:
  - Always include: `architecture-specifications`, `architecture`
  - Add domain-specific tags: `components`, `resilience`, `messaging`, `state-management`, `event-driven`, etc.
  - Add service-type tags if applicable: `publisher`, `consumer`, `broker`, `domain-service`

**Authoring Notes:**
- This section is required for all Architecture Specifications documents
- Tags improve discoverability in documentation portals and search engines
- Summary should be concise (≤20 words) and describe the architectural scope, not business purpose

---

## Document Purpose

**The Architecture Specifications answers: "How is this service built at an architectural level?"**

This document does NOT answer:
- **How do I deploy this?** (See Infrastructure Architecture)
- **How do I operate this?** (See Operations Guide)
- **How do I secure this?** (See Security Architecture)
- **What decisions led to this design?** (See Architecture Decision Records)
- **Why does this service exist?** (See System Context and Logical Components)

## Section Authoring Guidance

### Purpose and Scope

**Intent:** Establish what the document covers and what readers should expect to find.

**Required Content:**
- **Purpose:** 1-2 sentences explaining the architectural scope (what aspect of the service design this document addresses)
- **Intended Audience:** Who should read this document and why (architects, engineers, operators, etc.)
- **Document Scope - Included topics:** List 4-6 major architectural topics covered (e.g., "component boundaries," "communication patterns," "state management")
- **Document Scope - Excluded topics:** List 3-5 things NOT covered here and where to find them (e.g., "deployment procedures (see Infrastructure Architecture)," "operational runbooks (see Operations Guide)")
- **Companion Documents:** List 2-3 related documents that provide context (Architecture Guide, System Context and Logical Components, etc.)

**Authoring Notes:**
- Be explicit about what's NOT covered—this prevents readers from searching for missing information
- Excluded topics should reference where that information lives
- Avoid duplication: if content is in another document, cite it rather than repeating it

---

### Architectural Constraints and Assumptions

**Intent:** Document the fixed design boundaries and unstated assumptions that underpin all other decisions.

**Required Content:**
- **Architectural Constraints:** 5-10 design constraints that are NOT negotiable without architectural re-design:
  - Examples: "maximum component count is 3," "must use event-driven communication," "latency SLA < 100ms," "state must fit in memory," "components must be independently deployable"
  - For each constraint, include the consequence of violating it
- **Assumptions:** 5-10 assumptions about the operating environment, scale, or dependencies:
  - Examples: "database will be available >99.9% of the time," "network latency between services < 50ms," "no more than 10,000 requests/sec," "all dependent services follow async patterns"
  - Assumptions should be testable/confirmable

**Authoring Notes:**
- Constraints reflect architectural decisions; assumptions reflect operating environment
- Both should explain WHY they matter to the design
- These form the basis for all other sections—if they change, the architecture changes

---

### System Architecture Overview

**Intent:** Show how the service fits into the runtime and which artifacts implement which components.

**Required Content:**
- **Runtime Positioning:**
  - How this service receives work (API gateway, message queue, direct calls, etc.)
  - High-level processing flow (synchronous request-response, async event processing, etc.)
  - How this service delivers outcomes to consumers (HTTP response, event publication, database write, etc.)
  - Its relationship to upstream and downstream services
- **Component-to-Artifact Mapping:**
  - A table or list mapping logical components (from System Context) to deployment artifacts
  - Example: "Order Processing component → OrderService.dll," "State Manager → Redis instance"
  - Clarify 1:1 mappings vs. 1:many (one component in multiple processes) or many:1 (multiple components in one process)

**Authoring Notes:**
- This section bridges System Context (logical components) to Architecture Specifications (the design)
- Keep it visual or use clear tables
- If deployment is cloud-based, reference infrastructure documents rather than detailing it here

---

### Component Architecture Specifications

**Intent:** Define each component's responsibility, interfaces, and dependencies with sufficient detail that developers can implement or modify it.

**Required Content:** For each non-trivial component:
- **Responsibility:** 2-3 sentences declaring what the component does and its boundaries (what it is responsible for and what it is NOT)
- **Inputs and Outputs:**
  - What data does it receive and in what form? (synchronous method calls, async events, database queries, etc.)
  - What data does it produce and to whom? (return values, published events, written state, etc.)
  - Include message/data schemas or references to Event Contracts / API Contracts documents
- **Dependencies:**
  - What other components/services does this component depend on?
  - Are those dependencies hard (required) or soft (optional)?
  - How are failures in dependencies handled?
- **Configuration:**
  - What parameters does this component require to function?
  - Examples: timeout values, retry counts, buffer sizes, feature flags

**Authoring Notes:**
- One subsection per component (use ### [Component Name])
- Avoid operational details (log levels, alert thresholds)—those belong in Operations Guide
- Focus on architectural behavior: what it promises to do, what it requires, how it fails
- If a component is very simple, combine Inputs/Outputs and Dependencies into one section

---

### Component Communication Patterns

**Intent:** Define how components interact and what guarantees are maintained during communication.

**Required Content:**
- **Synchronous Communication:**
  - Which components use request-response (method calls, HTTP)?
  - What happens if the called component is unavailable? (fail fast, queue, retry, etc.)
  - Timeout and retry strategy for synchronous calls
  - Example: "OrderProcessor calls PricingService.GetPrice() with 1-second timeout; if timeout, returns cached price"
- **Asynchronous Communication:**
  - Which components use event/message passing?
  - Event or message types, schema references
  - Delivery guarantees: at-least-once, exactly-once, best-effort?
  - Ordering guarantees: per-tenant, global, or none?
  - Example: "StateManager publishes StateUpdated events with at-least-once guarantee, ordered per aggregate ID"
- **Message Delivery Guarantees:**
  - Global statement: what delivery semantic does the service maintain?
  - Why this semantic? (is it sufficient for the domain?)
  - Consequences of the chosen semantic (e.g., "exactly-once requires handling of duplicate messages in consumers")

**Authoring Notes:**
- This section is CRITICAL for understanding service resilience—don't minimize it
- Be explicit about guarantees and consequences
- If semantics vary by component or message type, call that out
- Reference Event Contracts and API Contracts documents for specifics

---

### State Management Architecture

**Intent:** Clarify what state the service maintains, where it's stored, and how consistency is ensured.

**Required Content:**
- **Stateful Components:**
  - Which components maintain state? (list by name)
  - What state does each maintain? (concise description)
  - Why is that state needed? (caching, exactly-once processing, etc.)
- **State Storage and Lifecycle:**
  - For each stateful component:
    - Where is state stored? (in-memory, database, cache, distributed cache, etc.)
    - How long is state kept? (TTL, purged on event, manual cleanup, etc.)
    - Can state be safely recreated? (is it derived from other data sources?)
    - What happens to state during component restart?
- **State Consistency and Synchronization:**
  - If multiple components share state, how is consistency maintained?
  - Does the service offer strong consistency, eventual consistency, or weak consistency?
  - How are state conflicts resolved? (last-write-wins, merging, rejection, etc.)
  - What happens if a component's state diverges from the source of truth?

**Authoring Notes:**
- Many existing docs gloss over this section with vague statements like "maintains minimal state"
- Be explicit: WHERE, HOW LONG, and HOW CONSISTENT
- Weak consistency is OK if it's intentional and understood—vagueness is the problem
- State architecture is foundational to resilience and failure handling

---

### Cross-Cutting Concerns

**Intent:** Define architectural principles for observability, security, and resilience that apply across all components.

**Required Content:**
- **Observability Principles:**
  - What must be logged? (structured logging? what fields?)
  - What metrics are collected? (throughput, latency, errors, state sizes, etc.)
  - Are there trace points? (distributed tracing across services?)
  - How is correlation maintained? (correlation IDs in logs and events?)
- **Security Principles:**
  - How is the service authenticated? (who is calling it?)
  - How is authorization enforced? (what is each caller allowed to do?)
  - Are there data protection requirements? (encryption at rest, in transit, etc.)?
  - How are secrets managed? (where do API keys, connection strings come from?)
- **Resilience and Fault Tolerance Principles:**
  - Timeout strategy: what timeouts are used and why?
  - Bulkhead strategy: are resources isolated (thread pools, connection pools) to prevent cascading failure?
  - Backoff strategy: exponential, fixed, or adaptive?
  - Circuit breaker strategy: when to trip, when to recover?

**Authoring Notes:**
- These are architectural principles, not operational procedures
- Don't repeat security requirements that belong in Security Architecture
- These sections should reference detailed specifications in other documents (Operations Guide for logging specifics, Security Architecture for encryption standards, etc.)

---

### Failure Modes and Resilience

**Intent:** Articulate expected failure modes and how the service responds to maintain correctness or graceful degradation.

**Required Content:**
- **Expected Failure Scenarios:**
  - List 5-10 realistic failure modes (database unavailable, network timeout, dependent service down, message queue full, etc.)
  - For each: what triggers it? How often might it occur? What's the impact?
- **Retry Boundaries and Backoff Strategies:**
  - When should work be retried? (transient errors only, or permanent errors too?)
  - What's the backoff strategy? (exponential, fixed interval, etc.)
  - Maximum retry count? (avoid infinite retries)
  - Which operations are idempotent and can be safely retried?
- **Impact Isolation and Blast Radius:**
  - For each failure scenario, what's the blast radius? (only this component, all components, downstream services?)
  - How does the service prevent one component's failure from cascading?
  - What's the minimum functionality the service maintains during partial failure?
- **Data Consistency in Failure:**
  - Can failures cause data inconsistency? (duplicate messages, lost updates, etc.)
  - How is consistency restored? (reconciliation, replay, manual intervention?)
  - What are acceptable windows of inconsistency?

**Authoring Notes:**
- This section is CRITICAL for production readiness—avoid generic statements
- Pair each failure scenario with the architectural mechanism (retry, queue, in-memory state, etc.) that handles it
- If the service cannot handle a failure gracefully, say so explicitly
- Consider failure chains: what happens if retry mechanism itself fails?

---

### Integration and Messaging Architecture

**Intent:** Define how this service exchanges data with external systems and what message structures are used.

**Required Content:**
- **Event and Message Types:**
  - What events does this service publish? (list event types)
  - What events does this service consume? (list event types)
  - What commands/requests does this service accept?
  - For each: schema, purpose, and who produces/consumes it
  - Reference Event Contracts and API Contracts documents for detailed specifications
- **Integration Points (System-to-System):**
  - List all external systems this service depends on (e.g., database, cache, authorization service, message broker)
  - For each: what protocol? how is it called? what's the SLA expectation?
  - What happens if the external system is unavailable?
  - Are there rate limits or usage quotas?
- **Protocol Specifications:**
  - What protocols does this service use? (HTTP, gRPC, message queue, etc.)
  - For each protocol: what versions/standards are required?
  - Are there protocol-specific reliability guarantees? (TCP vs. UDP, message brokers with delivery guarantees, etc.)

**Authoring Notes:**
- This section focuses on ARCHITECTURE (protocols, guarantees, integration pattern)
- Configuration details (connection strings, retry counts) belong elsewhere
- Avoid duplicating Event Contracts and API Contracts—reference them instead
- Make clear what integration is within the service and what's external

---

### Relationship to Other Architecture Artifacts

**Intent:** Clarify how this document relates to other architecture and design documents to prevent duplication and confusion.

**Required Content:**
- **Architecture Guide:**
  - What aspects of the Architecture Guide does this service instantiate?
  - Are there any deviations from standard patterns?
- **System Context and Logical Components:**
  - How do the logical components in System Context map to the architecture in this document?
  - What additional design decisions were made to realize those logical components?
- **Other Standards and Specifications:**
  - Event Contracts: which specific events from the Event Contracts document does this service produce/consume?
  - API Contracts: which specific APIs from the API Contracts document does this service expose?
  - Operations Guide: what operational instrumentation (logging, metrics, alerts) is required?
  - Security Architecture: what security controls are required?
  - Infrastructure Architecture: what infrastructure assumptions underpin this design?
  - Architecture Decision Records: links to key ADRs that shaped architectural choices

**Authoring Notes:**
- This section should be BRIEF—just map to other docs
- It's a navigation aid and a check for completeness
- If a section of this Architecture Specifications seems to overlap with another document, cite the other document and avoid duplication

---

## Authoring Workflow

1. **Complete Purpose and Scope:** Establish what's included and excluded
2. **Document Constraints and Assumptions:** These ground all downstream decisions
3. **Sketch Components:** In System Architecture Overview, list the components you'll specify
4. **Detail Each Component:** Complete Component Architecture Specifications for each
5. **Define Communication:** Complete Component Communication Patterns and Integration and Messaging Architecture
6. **Address State:** Complete State Management Architecture (don't leave this vague)
7. **Plan Resilience:** Complete Failure Modes and Resilience and Retry Strategies
8. **Define Principles:** Complete Cross-Cutting Concerns
9. **Map to Artifacts:** Complete Relationship to Other Architecture Artifacts as a final check
10. **Review:** Verify no duplication with other documents and all assumptions are testable

## Review Checklist

- [ ] Purpose and Scope clearly states what IS and IS NOT covered
- [ ] All constraints are non-negotiable architectural boundaries
- [ ] All assumptions are testable/confirmable
- [ ] Each component has clear responsibility, inputs/outputs, and dependencies
- [ ] Communication patterns are explicit (synchronous/asynchronous, delivery guarantees)
- [ ] State management is detailed: WHERE, HOW LONG, consistency model
- [ ] Failure modes are realistic and resilience mechanisms are specified for each
- [ ] Cross-cutting concerns (observability, security, resilience) have clear architectural principles
- [ ] Integration points reference Event Contracts, API Contracts, and Infrastructure Architecture
- [ ] No duplication with Operations Guide, Security Architecture, or Infrastructure Architecture
- [ ] Related documents are cited in Relationship to Other Architecture Artifacts section

