---
title: Non-Goals and Guardrails Instructions
summary: Authoring guidance for creating Non-Goals and Guardrails documents
tags:
  - non-goals-and-guardrails
  - instructions
  - documentation
  - architecture
---

# Non-Goals and Guardrails: Authoring Instructions

## Document Overview

### What This Document Is

The Non-Goals and Guardrails document establishes **clear, durable boundaries** around your platform/system/service scope. It explicitly defines what your solution does NOT attempt to do and the intentional architectural constraints that shape how it behaves.

This is not a failure inventory or a list of future work. These are **deliberate design decisions** that preserve focus, operational simplicity, and long-term maintainability.

### When to Create This Document

Create this document **after** completing:
- Architecture Guide (understand the vision and purpose)
- System Context & Logical Components (understand what the system IS)
- Architecture Specifications (understand how it's built)

At this point, you have enough context to articulate what the system does NOT do and why those boundaries exist.

### Prerequisites

Before authoring, you should have:
- **Completed System Context** - Clear understanding of what capabilities the system provides
- **Completed Architecture Specifications** - Deep knowledge of how the system is implemented
- **Stakeholder feedback history** - List of requests that were declined or deferred
- **Architectural principles** - Core design philosophy (e.g., simplicity over convenience, eventual consistency, consumer-agnostic)
- **Consumer personas** - Understanding of who uses the system and what they might expect

### Terminology: Platform vs System vs Service

Use this guidance to choose terminology:

**Platform**: Multi-consumer infrastructure service that provides foundational capabilities (e.g., Infinity Bus, Item Master Publisher)
- Emphasizes: Reusability, governance, consumer-agnostic design
- Use when: Service has multiple independent consumers

**System**: Broader scope comprising multiple services working together
- Emphasizes: Coordinated behavior, integration boundaries
- Use when: Documenting boundaries for a suite of related services

**Service**: Single-purpose application component
- Emphasizes: Specific business capability, focused scope
- Use when: Single service with well-defined responsibility

Choose one term and use it consistently throughout the document.

---

## YAML Frontmatter

### Purpose

The YAML frontmatter provides structured metadata for documentation systems (e.g., MkDocs) and enables:
- Discovery and navigation
- Tagging and categorization
- Summary presentation

### Required Fields

```yaml
---
title: Non-Goals and Guardrails
summary: [1-sentence description of scope boundaries]
tags:
  - non-goals-and-guardrails  # Required
  - architecture               # Required
  - [domain-specific tags]     # e.g., event-driven, integration
  - [capability tags]          # e.g., publishing, orchestration
---
```

### Field Guidance

**title**: Always "Non-Goals and Guardrails"

**summary**: One sentence (≤20 words) describing the boundaries being established
- Focus on what's being bounded, not what's included
- Example: "Establishes scope boundaries and design constraints for the Notification Service platform"
- Example: "Defines intentional limitations and architectural guardrails for the Infinity Bus"

**tags**: Always include:
- `non-goals-and-guardrails` (required)
- `architecture` (required)
- Domain tags (e.g., `event-driven`, `messaging`, `integration`, `data-platform`)
- Capability tags (e.g., `publishing`, `orchestration`, `resilience`)

### When to Complete

Complete the YAML frontmatter **after** finishing all content sections so the summary and tags accurately reflect the documented boundaries.

---

## Section 1: Purpose and Audience

### Purpose

This section establishes why the document exists and sets expectations for readers. It frames non-goals and guardrails as **intentional** design decisions, not accidental omissions or future work.

### What to Include

1. **What this document defines**
   - State that it defines what the platform/system/service does NOT do
   - Establish that boundaries are intentional, not limitations to overcome
   - Explain that boundaries preserve focus, simplicity, and maintainability

2. **Who should read this document**
   - Architects and platform stakeholders (who make scope decisions)
   - Consumer teams (who need to understand what to build themselves)
   - Product and business owners (who prioritize capabilities)
   - Future maintainers (who need to understand why boundaries exist)

3. **Framing non-goals as design decisions**
   - Explicitly state that non-goals are **intentional decisions**, not deficiencies
   - Emphasize that these decisions inform feature requests, architecture reviews, and governance

### What NOT to Include

- Service-specific technical implementation details
- Apologies or defensive language about limitations
- Promises of future work
- Technical jargon without explanation

### Completeness Criteria

✅ Document purpose is clear  
✅ Audience list includes architects, consumers, product owners, and maintainers  
✅ Non-goals are framed as intentional, not apologetic  
✅ Language is accessible to non-technical stakeholders  

### Example Opening

> "This document defines what the Notification Service platform **explicitly does not attempt to do**. Its purpose is to establish clear boundaries around platform scope, prevent scope creep, and ensure that stakeholders understand the deliberate limits of this capability.
>
> Non-goals and guardrails are not failures or limitations to be overcome. They represent *intentional design decisions* that preserve platform focus, operational simplicity, and long-term maintainability."

---

## Section 2: Core Non-Goals

### Purpose

This is the **heart of the document**. Each non-goal explicitly excludes a capability, explains why the boundary exists, and redirects consumers to the correct solution path.

### Number of Non-Goals

Typical range: **8-12 non-goals**

Too few (<6): Likely missing important boundaries  
Too many (>15): Boundaries may be too granular; consider consolidation

Quality over quantity: Each non-goal should represent a meaningful architectural boundary.

### Non-Goal Pattern (Three-Part Structure)

Every non-goal **must** follow this pattern:

#### **✗ Non-Goal: [Capability Name]**

**What we do NOT do:**  
[1-3 sentences: Explicit statement of excluded capability]

**Why this matters:**  
[2-4 sentences: Business/technical rationale for the boundary]

**What consumers must do instead:**  
[Numbered list: 3-5 concrete steps consumers take to solve the problem themselves]

### Three-Part Pattern Explained

#### Part 1: What we do NOT do

State the excluded capability clearly and unambiguously. Use strong, definitive language.

**Good examples:**
- "The platform does not optimize event payloads or emit multiple event variants based on consumer needs."
- "The platform does not guarantee sub-second event delivery or real-time ordering across all items."
- "The platform does not provide query APIs, search capabilities, or read-optimized views."

**Avoid vague statements:**
- ❌ "The platform may not support..." (sounds conditional)
- ❌ "We don't currently provide..." (sounds temporary)
- ❌ "Low-latency delivery is not prioritized" (sounds negotiable)

#### Part 2: Why this matters

Explain the **rationale** for the boundary. This is critical for governance—stakeholders need to understand *why* the boundary exists to respect it.

Focus on:
- **Architectural principle violations**: "Would create tight coupling between platform and consumers"
- **Operational complexity**: "Requires sophisticated state management that increases failure modes"
- **Scope creep**: "Turns the platform into a consumer-specific service rather than a neutral transport"
- **Misaligned ownership**: "Forces the platform to own business logic that belongs in consuming applications"

#### Part 3: What consumers must do instead

Provide **concrete redirection**. Consumers should know exactly where to go or what to build.

Use numbered lists:
1. Receive canonical events from the platform
2. Project the data into your own storage model
3. Build your own indexes and aggregations
4. Expose query APIs tailored to your needs

### Common Non-Goal Categories

Use these categories to brainstorm non-goals:

#### Category: Consumer-Specific Behavior
- Consumer-specific data shapes, projections, or transformations
- Consumer-specific filtering, routing, or prioritization
- Consumer-specific optimization or performance tuning

#### Category: Guarantees Not Provided
- Real-time or low-latency guarantees
- Exactly-once delivery
- Transactional guarantees or atomicity
- Global ordering across all events

#### Category: Bi-Directional or Write-Back
- Bi-directional synchronization
- Reverse updates or change propagation back to source systems
- Event retraction or change reversal

#### Category: Query or Read Patterns
- Query APIs, search, or retrieval endpoints
- Historical reconstruction or time-travel queries
- Full-text search, fuzzy matching, or advanced query semantics

#### Category: Operational Automation
- Consumer state management or subscription lifecycle automation
- Filtered or partial backfill/replay
- Automatic onboarding or provisioning

#### Category: End-User Features
- UI, dashboards, visualizations
- Direct end-user consumption

### Brainstorming Non-Goals

To identify non-goals, ask:
1. **What have stakeholders requested that we intentionally declined?**
2. **What would add complexity without core value?**
3. **What belongs in consumers, not the platform?**
4. **What guarantees would require architectural changes we've rejected?**
5. **What creates coupling or violates our design principles?**

### Completeness Criteria

✅ Each non-goal follows the three-part pattern  
✅ "What we do NOT do" is clear and definitive  
✅ "Why this matters" explains architectural or operational rationale  
✅ "What instead" provides concrete consumer guidance  
✅ Non-goals cover common capability categories  
✅ Total count is 8-12 non-goals  

---

## Section 3: Guardrails and Constraints by Design

### Purpose

Guardrails define **how the platform behaves** within its scope. Unlike non-goals (which exclude capabilities), guardrails shape how included capabilities work.

### Guardrail vs Non-Goal

**Non-Goal**: "We don't provide query APIs"  
**Guardrail**: "At-least-once delivery, not exactly-once"

Guardrails are constraints you've **accepted** to achieve simplicity, scalability, or operational benefits.

### Number of Guardrails

Typical range: **4-6 guardrails**

Focus on the most impactful constraints that consumers must understand.

### Guardrail Pattern (Four-Part Structure)

#### **Guardrail: [Constraint Name]**

**What this means:**  
[1-2 sentences: Description of the constraint]

**Tradeoff accepted:**  
[2-3 sentences: What is gained and what is sacrificed]

**Design implication:**  
[2-4 sentences: Impact on consumers and system design]

### Common Guardrail Topics

#### Event Semantics
- Snapshot semantics vs delta semantics
- Full-state events vs incremental changes
- Self-contained vs reference-based events

#### Event Independence
- Events are independent; no co-emission guarantees
- No correlation across event families
- No guaranteed ordering between related events

#### Delivery Guarantees
- At-least-once delivery (duplicates possible)
- No exactly-once guarantees
- Idempotency required for consumers

#### Ordering Guarantees
- Partition-level ordering only
- No global ordering across channels/topics
- Temporal ordering not guaranteed

#### Freshness Constraints
- Upstream system coupling on freshness
- Latency depends on source system behavior
- Event lag is architectural reality, not defect

#### Publisher Coordination
- Single publisher per domain
- No parallel extraction or bypass allowed
- Centralized coordination to protect source systems

### Completeness Criteria

✅ Each guardrail follows the four-part pattern  
✅ "What this means" clearly states the constraint  
✅ "Tradeoff accepted" explains both benefits and costs  
✅ "Design implication" shows impact on consumers  
✅ Guardrails cover delivery, ordering, and freshness constraints  

---

## Section 4: Tradeoffs Accepted

### Purpose

This section provides **transparency** about deliberate design choices. It helps stakeholders understand not just *what* boundaries exist, but *why* you chose one path over another.

### Number of Tradeoffs

Typical range: **3-5 tradeoffs**

Focus on high-level strategic tradeoffs, not tactical implementation details.

### Tradeoff Pattern (Three-Part Structure)

#### **Tradeoff #N: [Choice A] vs [Choice B]**

**Decision:** [Which path was chosen and why]

**Impact:** [Consequences for platform and consumers]

### Common Strategic Tradeoffs

#### Tradeoff 1: Platform Simplicity vs Consumer Convenience

**Decision**: Prioritize platform simplicity over consumer convenience

**Impact**: Consumers must build their own specialized infrastructure (indexes, aggregations, query APIs), but the platform remains focused and maintainable. This is the right choice for a platform serving multiple consumers with diverse needs.

#### Tradeoff 2: Broadcast Publishing vs Targeted Delivery

**Decision**: Publish events to all subscribers; do not target events to specific consumers

**Impact**: Consumers must filter events on their side. However, this keeps the publisher simple and allows new consumers to be added without affecting publisher behavior.

#### Tradeoff 3: Eventual Consistency vs Strong Consistency

**Decision**: Accept eventual consistency

**Impact**: Consumers may briefly have different views of data and must handle eventual consistency in their business logic. However, this allows the platform to scale and operate reliably without complex coordination.

#### Tradeoff 4: Event-Driven Publishing vs Query APIs

**Decision**: Publish events; do not provide query APIs

**Impact**: Consumers must maintain read models and cannot rely on the platform for ad-hoc queries. However, this keeps the platform stateless and scalable.

### Completeness Criteria

✅ Each tradeoff clearly states two competing options  
✅ Decision explains which path was chosen  
✅ Impact describes consequences for both platform and consumers  
✅ Language is transparent, not defensive  

---

## Section 5: Problems the Platform Does Not Solve

### Purpose

This section provides a **quick-reference list** of specific problems explicitly out of scope. Unlike Core Non-Goals (which require detailed rationale), this is a concise inventory.

### Format

Use **category headings** (###) with brief explanations:

### Consumer Onboarding Automation

The platform publishes events; it does not automatically detect new consumers or set up subscriptions for them.

### Common Problem Categories

- Consumer onboarding automation
- Data quality governance
- Duplicate detection and consolidation
- Hierarchical or aggregate views
- Lifecycle workflow enforcement
- Cross-domain correlation
- Migration strategies or legacy system sunsets
- Performance tuning for specific workloads

### Completeness Criteria

✅ 6-10 specific problem categories listed  
✅ Each problem has 1-2 sentence explanation  
✅ Problems are clearly out-of-scope, not deferred work  

---

## Section 6: Future Expansion (What *Might* Be Added)

### Purpose

This section shows where the architecture is **intentionally flexible** for future evolution, while making it clear that nothing listed is a commitment.

### What to Include

List 3-5 areas where expansion is architecturally possible (though not planned):
- New event families or channels
- Additional source systems
- Enhanced governance automation
- Consumer-managed filtering options
- Backfill scheduling or orchestration

### Critical Language

Always include:
- **Opening**: "While the platform has clear non-goals, it is designed to be extensible. Future evolution is possible in these areas (though not committed):"
- **Closing**: "These possibilities are **not commitments**. Any expansion would require architecture review and governance approval."

### What NOT to Include

- Specific timelines or roadmap items
- Features that violate core non-goals
- Consumer-specific requests

### Completeness Criteria

✅ 3-5 potential expansion areas listed  
✅ Opening and closing disclaimers included  
✅ No expansion violates core non-goals  
✅ No timelines or commitments implied  

---

## Section 7: Implications for Architecture and Governance

### Purpose

This section makes the document **operationally useful** by showing how to use non-goals in decision-making.

### Subsection 1: Feature Requests

**Guidance**: When someone asks "Can the platform provide X?", the first question is: "Does X fall into one of our non-goals?"

Explain:
- If yes → The answer is no. Redirect to consumer ownership.
- If no → Evaluate against platform principles and governance.

### Subsection 2: Architecture Reviews

**Guidance**: Architecture reviews must validate that changes do not creep into non-goal territory.

Explain:
- Proposals that move toward excluded capabilities are rejected or reshaped
- Non-goals are a checklist during design review

### Subsection 3: Consumer Guidance

**Guidance**: Consumer teams must understand non-goals to design correctly.

Explain:
- Consumer documentation references non-goals
- Onboarding includes non-goal review
- Consumers build with boundaries in mind from day one

### Subsection 4: Platform Evolution

**Guidance**: Platform evolution must remain aligned with non-goals.

Explain:
- Evolution is additive and horizontal, not creeping into excluded territory
- New capabilities are evaluated against non-goal boundaries

### Completeness Criteria

✅ All four subsections present  
✅ Each subsection explains HOW to use non-goals  
✅ Practical guidance for stakeholders provided  

---

## Section 8: Summary: Platform Scope Lens

### Purpose

This section provides a **quick-reference decision tool** for daily use. Stakeholders can quickly categorize a request or question.

### Three Categories

#### In Scope (Platform Owns)
4-6 bullets listing capabilities the platform provides

Example:
- Event detection and publication from authoritative sources
- Canonical event contract definition and versioning
- Operational reliability and observability
- Backfill orchestration and coordination

#### Out of Scope (Consumers Own)
4-6 bullets listing capabilities consumers must provide

Example:
- Data projection and read models
- Query APIs and search infrastructure
- Business rule enforcement
- Application-specific optimization

#### By Design (Accepted Constraints)
4-6 bullets listing architectural constraints

Example:
- Snapshot semantics only
- At-least-once delivery
- Event independence
- Eventual consistency

### Closing Statement

End with a sentence about maintaining boundaries, e.g.:

> "By maintaining these clear boundaries, the [platform/system/service] remains focused, maintainable, and valuable over time."

### Completeness Criteria

✅ Three categories present (In Scope, Out of Scope, By Design)  
✅ Each category has 4-6 concise bullets  
✅ Closing statement reinforces boundary maintenance  

---

## Authoring Workflow

### Recommended Sequence

1. **Preparation** (30-60 min)
   - Review Architecture Guide, System Context, and Architecture Specifications
   - Collect stakeholder feedback and declined feature requests
   - List architectural principles and design constraints

2. **Purpose and Audience** (15 min)
   - Draft why the document exists
   - List target audiences
   - Frame non-goals as intentional decisions

3. **Brainstorm Non-Goals** (30-45 min)
   - Use common categories as starting point
   - Review declined requests and scope discussions
   - Identify 8-12 candidate non-goals

4. **Detail Each Non-Goal** (2-3 hours)
   - For each non-goal, complete three-part pattern
   - Ensure rationale is clear
   - Provide concrete redirection for consumers

5. **Identify Guardrails** (30-60 min)
   - List architectural constraints accepted by design
   - Complete four-part pattern for each
   - Focus on delivery, ordering, freshness constraints

6. **Articulate Tradeoffs** (30 min)
   - Identify 3-5 strategic design choices
   - Explain decision and impact for each

7. **List Problems Not Solved** (15 min)
   - Quick inventory of out-of-scope problems

8. **Future Expansion** (15 min)
   - List 3-5 possible evolution areas
   - Include disclaimers

9. **Governance Implications** (30 min)
   - Complete four subsections with practical guidance

10. **Summary Lens** (15 min)
    - Categorize capabilities into In/Out/By Design

11. **YAML Frontmatter** (10 min)
    - Finalize based on completed content

12. **Review and Validation** (30-60 min)
    - Verify all patterns followed
    - Check completeness criteria
    - Request peer review from architects

### Total Time Estimate

**2-4 hours** for a typical platform/service

---

## Common Pitfalls

### Pitfall 1: Apologizing for Non-Goals

❌ "Unfortunately, we don't provide real-time guarantees"  
✅ "The platform does not guarantee real-time delivery. This design choice preserves operational simplicity."

### Pitfall 2: Vague Non-Goals

❌ "We don't optimize for every use case"  
✅ "The platform does not provide consumer-specific data shapes or projections"

### Pitfall 3: Missing Redirection

❌ Just stating what's not provided  
✅ Always include "What consumers must do instead"

### Pitfall 4: Treating Non-Goals as Future Work

❌ "We don't currently support query APIs [implies coming soon]"  
✅ "The platform does not provide query APIs [implies intentional exclusion]"

### Pitfall 5: Too Many or Too Few Non-Goals

- <6 non-goals: Likely missing important boundaries
- >15 non-goals: Boundaries too granular; consolidate related items

### Pitfall 6: Mixing Non-Goals with Guardrails

- Non-Goal = Excluded capability
- Guardrail = Constraint on included capability

---

## Quality Checklist

Before finalizing, verify:

**Structure:**
- [ ] YAML frontmatter complete and accurate
- [ ] All 8 sections present
- [ ] All patterns followed (three-part, four-part, etc.)

**Non-Goals:**
- [ ] 8-12 non-goals documented
- [ ] Each follows three-part pattern
- [ ] Categories well-distributed

**Guardrails:**
- [ ] 4-6 guardrails documented
- [ ] Each follows four-part pattern

**Tradeoffs:**
- [ ] 3-5 tradeoffs documented
- [ ] Strategic, not tactical

**Governance:**
- [ ] All four governance subsections complete
- [ ] Practical guidance provided

**Summary Lens:**
- [ ] Three categories present
- [ ] 4-6 bullets each

**Language:**
- [ ] Definitive, not apologetic
- [ ] Accessible to non-technical stakeholders
- [ ] Consistent terminology (platform/system/service)

**Rationale:**
- [ ] Every non-goal explains "Why this matters"
- [ ] Every guardrail explains tradeoffs
- [ ] Every tradeoff explains impact

---

## Next Steps After Completion

1. **Peer Review**: Share with architects and senior engineers for validation
2. **Stakeholder Review**: Review with product owners and consumer teams
3. **Publish**: Add to architecture documentation repository
4. **Socialize**: Reference in consumer onboarding and feature request processes
5. **Maintain**: Update when architectural boundaries change (should be rare)
