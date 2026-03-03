---
title: Non-Goals and Guardrails Agent Guidance
summary: Rules for GitHub Copilot when generating Non-Goals and Guardrails content
tags:
  - non-goals-and-guardrails
  - agent-guidance
  - copilot
  - architecture
---

# Non-Goals and Guardrails: Agent Guidance

## Purpose

This document defines how GitHub Copilot should behave when helping architects create Non-Goals and Guardrails documents. It specifies when to infer, when to ask clarifying questions, and when to defer decisions to the architect.

---

## General Principles

### Principle 1: Non-Goals Require Architectural Judgment

**What this means**: Defining what a platform/system/service does NOT do requires strategic decisions about scope, ownership boundaries, and consumer responsibilities. The agent cannot make these decisions autonomously.

**Agent behavior**:
- NEVER invent non-goals without architect confirmation
- ALWAYS ask the architect which capabilities to exclude
- Challenge vague or incomplete non-goal descriptions
- Defer boundary decisions to the architect

### Principle 2: Rationale is Critical

**What this means**: Every non-goal and guardrail must explain WHY the boundary exists. Without rationale, stakeholders cannot understand or respect the boundary.

**Agent behavior**:
- If rationale is missing, ask: "Why is this capability intentionally excluded?"
- If rationale is weak ("we don't have time"), ask: "What architectural principle or tradeoff justifies this boundary?"
- Strengthen rationale by connecting to design principles from Architecture Guide

### Principle 3: Redirection Must Be Concrete

**What this means**: "What consumers must do instead" must provide actionable guidance, not vague suggestions.

**Agent behavior**:
- If redirection is missing, ask: "What specific steps should consumers take to solve this problem?"
- If redirection is vague ("build it yourself"), ask: "What infrastructure, tools, or patterns should consumers use?"
- Ensure redirection is a numbered list with 3-5 concrete steps

### Principle 4: Maintain Pattern Consistency

**What this means**: Non-Goals and Guardrails follow strict structural patterns. Deviation reduces document usability.

**Agent behavior**:
- ALWAYS enforce three-part pattern for non-goals (What / Why / What Instead)
- ALWAYS enforce four-part pattern for guardrails (What / Tradeoff / Implication)
- If pattern is incomplete, prompt for missing parts
- Reject free-form explanations that don't follow patterns

### Principle 5: Language Must Be Definitive, Not Apologetic

**What this means**: Non-goals are intentional decisions, not failures. Language should reflect confidence.

**Agent behavior**:
- Replace apologetic language: ❌ "Unfortunately, we don't..." → ✅ "The platform does not..."
- Replace conditional language: ❌ "We may not support..." → ✅ "The platform does not support..."
- Replace temporary language: ❌ "We don't currently..." → ✅ "The platform does not..."

---

## When to Infer vs Ask vs Defer

### Inference Allowed (Low Risk)

**Structural elements**:
- Section headings and subsection structure
- Pattern enforcement (three-part, four-part)
- Formatting and markdown syntax
- Cross-references to other architecture documents

**Language refinement**:
- Removing apologetic or defensive language
- Strengthening weak rationale (if principle is clear)
- Converting vague redirection to concrete steps (if context exists)

**Example expansion**:
- Expanding abbreviated notes into full pattern
- Elaborating on implications if guardrail is clear

### Clarification Required (Medium Risk)

**Incomplete information**:
- Non-goal stated without rationale
- Guardrail stated without tradeoff explanation
- Redirection missing or vague
- Tradeoff stated without impact description

**Ambiguous boundaries**:
- Unclear whether capability is non-goal or deferred work
- Overlapping non-goals that might be consolidated
- Guardrail that contradicts a stated capability

**Missing context**:
- Architectural principle referenced but not explained
- Consumer persona mentioned but not defined
- Design constraint stated without implication

**Questions to ask**:
- "Why is this capability intentionally excluded?"
- "What architectural principle does this boundary preserve?"
- "What should consumers build instead?"
- "What tradeoff does this constraint represent?"
- "How does this guardrail impact consumer design?"

### Deferral Mandatory (High Risk)

**Strategic decisions**:
- Which capabilities to exclude as non-goals
- How many non-goals to document
- Which guardrails to highlight
- Which tradeoffs to emphasize

**Scope boundaries**:
- Whether a capability is in-scope or out-of-scope
- Whether a requested feature violates a non-goal
- Whether a guardrail should be relaxed or maintained

**Architectural judgment**:
- Whether a boundary preserves simplicity or harms usability
- Whether consumer redirection is reasonable or excessive
- Whether a tradeoff is acceptable for the domain

**How to defer**:
- State the decision that needs to be made
- Present options with pros/cons
- Ask architect to choose
- Document the choice in the rationale

---

## YAML Frontmatter

### Agent Behavior

**title**: Always set to "Non-Goals and Guardrails" (no inference needed)

**summary**: 
- DEFER until content is complete
- ASK: "What is the primary scope boundary this document establishes?"
- Ensure ≤20 words, focuses on boundaries, not capabilities

**tags**:
- ALWAYS include: `non-goals-and-guardrails`, `architecture`
- INFER domain tags from System Context and Architecture Specifications
- ASK if domain is ambiguous: "What domain does this platform/system/service belong to? (e.g., event-driven, integration, data-platform)"

---

## Section 1: Purpose and Audience

### Recall vs Reasoning

**Recall**: Standard structure and audience list (from instructions and examples)

**Reasoning**: Tailoring language to match the platform/system/service type

### What Agent Can Infer

- Document serves to establish boundaries and prevent scope creep
- Audience includes architects, consumers, product owners, maintainers
- Non-goals are intentional, not accidental

### What Agent Must Ask

- Whether to use "platform", "system", or "service" terminology
- If additional audiences exist beyond standard list

### Critical Checks

- ✅ Language frames non-goals as intentional design decisions
- ✅ No apologetic language
- ✅ Audience list includes both technical and business stakeholders

### Interaction Pattern

1. INFER standard structure from template
2. ASK for terminology choice if ambiguous
3. GENERATE section matching chosen terminology
4. VERIFY no apologetic framing

---

## Section 2: Core Non-Goals

### Recall vs Reasoning

**Recall**: Three-part pattern structure (What / Why / What Instead)

**Reasoning**: Identifying which capabilities to exclude and articulating rationale

### What Agent CANNOT Infer

- Which capabilities to exclude as non-goals
- Number of non-goals to document
- Specific rationale for each boundary
- Consumer redirection steps

### What Agent Must Ask

**Initial brainstorming**:
- "What capabilities have stakeholders requested that you intentionally declined?"
- "What features would add complexity without core value?"
- "What responsibilities belong in consumers, not the platform?"
- "What guarantees would violate your architectural principles?"

**For each non-goal**:
- "What is the excluded capability?" (What we do NOT do)
- "Why is this capability intentionally excluded?" (Why this matters)
- "What should consumers do to solve this problem?" (What instead)

**Completeness**:
- "Are there any other significant capabilities that should be explicitly excluded?"
- "Should any non-goals be combined or split?"

### Critical Checks for Each Non-Goal

**Pattern Completeness**:
- ✅ "What we do NOT do" is clear and definitive
- ✅ "Why this matters" explains architectural or operational rationale
- ✅ "What consumers must do instead" is a numbered list with 3-5 concrete steps

**Language Quality**:
- ✅ No conditional language ("may not", "might not")
- ✅ No temporary language ("currently", "at this time")
- ✅ No apologetic language ("unfortunately", "sadly")

**Rationale Strength**:
- ✅ Connects to architectural principle (simplicity, decoupling, ownership)
- ✅ Explains consequences of violating boundary (coupling, complexity, scope creep)
- ✅ Not just "lack of resources" or "haven't built it yet"

**Redirection Quality**:
- ✅ Specific, not vague
- ✅ Achievable with reasonable effort
- ✅ Points to correct ownership (consumer's responsibility, source system, etc.)

### Interaction Pattern

1. ASK architect to identify candidate non-goals (brainstorming questions)
2. For each candidate, ASK for three-part pattern elements
3. CHALLENGE weak rationale: "How does excluding this capability preserve architectural principles?"
4. CHALLENGE vague redirection: "What specific infrastructure should consumers build?"
5. VERIFY pattern completeness and language quality
6. ASK: "Are there additional non-goals to document?"

### Red Flags to Challenge

**Vague exclusions**:
- ❌ "We don't optimize for every use case"
- Ask: "What specific capability or optimization is excluded?"

**Weak rationale**:
- ❌ "We don't have time to build this"
- Ask: "What architectural principle would be violated if we provided this capability?"

**Missing redirection**:
- ❌ Non-goal ends after "Why this matters"
- Ask: "What specific steps should consumers take to solve this problem themselves?"

**Scope confusion**:
- Architect says "not a priority" instead of "intentionally excluded"
- Ask: "Is this capability deferred (future work) or excluded (intentional boundary)?"

---

## Section 3: Guardrails and Constraints by Design

### Recall vs Reasoning

**Recall**: Four-part pattern (What / Tradeoff / Implication)

**Reasoning**: Identifying which design constraints to highlight and articulating tradeoffs

### What Agent Can Infer (From Architecture Specifications)

- Event semantics (snapshot vs delta)
- Delivery guarantees (at-least-once, at-most-once, exactly-once)
- Ordering guarantees (global, partition-level, none)
- Freshness constraints (upstream coupling, latency sources)

Read Architecture Specifications and extract constraints explicitly stated there.

### What Agent Must Ask

**Guardrail identification**:
- "Which design constraints should consumers understand to design correctly?"
- "What guarantees do you explicitly NOT provide?"
- "What constraints shape how the platform behaves?"

**For each guardrail**:
- "What is the constraint?" (What this means)
- "What is gained and what is sacrificed?" (Tradeoff accepted)
- "How does this impact consumer design?" (Design implication)

### Critical Checks for Each Guardrail

**Pattern Completeness**:
- ✅ "What this means" clearly states the constraint
- ✅ "Tradeoff accepted" explains both benefits and costs
- ✅ "Design implication" shows impact on consumers

**Tradeoff Balance**:
- ✅ Acknowledges both what is gained (simplicity, scalability) and what is lost (precision, immediacy)
- ✅ Frames tradeoff as intentional choice, not limitation

**Consumer Impact**:
- ✅ Explains what consumers must do differently because of this constraint
- ✅ Concrete, actionable guidance

### Interaction Pattern

1. READ Architecture Specifications for stated constraints
2. INFER candidate guardrails from delivery, ordering, freshness constraints
3. ASK architect to confirm which constraints are most critical
4. For each guardrail, GENERATE four-part pattern
5. VERIFY tradeoff is balanced (not apologetic)
6. VERIFY design implication is concrete

### Red Flags to Challenge

**Missing tradeoff**:
- Guardrail states constraint but doesn't explain why it was chosen
- Ask: "What benefit does this constraint provide?"

**Apologetic framing**:
- ❌ "Unfortunately, we only provide at-least-once delivery"
- Suggest: ✅ "The platform provides at-least-once delivery, which preserves operational simplicity while requiring consumers to implement idempotent processing"

**Vague implication**:
- ❌ "Consumers must handle this appropriately"
- Ask: "Specifically, what must consumers do in their design?"

---

## Section 4: Tradeoffs Accepted

### Recall vs Reasoning

**Recall**: Common strategic tradeoffs (from instructions)

**Reasoning**: Confirming which tradeoffs apply to this platform/system/service

### What Agent Can Infer

From Architecture Guide and Architecture Specifications:
- Design philosophy (simplicity vs feature-richness)
- Consistency model (eventual vs strong)
- Publishing model (broadcast vs targeted)
- Query model (event-driven vs request-response)

### What Agent Must Ask

- "Which strategic tradeoffs best characterize this platform's design?"
- "For each tradeoff, why did you choose this path?"
- "What are the consequences for both platform and consumers?"

### Common Tradeoffs (Suggest These)

1. Platform Simplicity vs Consumer Convenience
2. Broadcast Publishing vs Targeted Delivery
3. Eventual Consistency vs Strong Consistency
4. Event-Driven Publishing vs Query APIs

### Critical Checks for Each Tradeoff

**Choice Clarity**:
- ✅ Two competing options clearly stated
- ✅ Decision explains which path chosen

**Impact Transparency**:
- ✅ Consequences for platform explained
- ✅ Consequences for consumers explained
- ✅ Language is transparent, not defensive

### Interaction Pattern

1. SUGGEST common tradeoffs from instructions
2. ASK architect to confirm which apply
3. For each tradeoff, ASK: "Why did you choose this path?"
4. For each tradeoff, ASK: "What are the consequences?"
5. GENERATE tradeoff entries
6. VERIFY transparency (not defensive)

---

## Section 5: Problems the Platform Does Not Solve

### Recall vs Reasoning

**Recall**: Common problem categories (from instructions)

**Reasoning**: Confirming which problems apply to this context

### What Agent Can Suggest

From instructions:
- Consumer onboarding automation
- Data quality governance
- Duplicate detection/consolidation
- Aggregation or hierarchical views
- Lifecycle workflow enforcement
- Cross-domain correlation
- Migration strategies
- Performance tuning for consumer workloads

### What Agent Must Ask

- "Which of these problems are explicitly out of scope?"
- "Are there additional domain-specific problems to list?"

### Interaction Pattern

1. SUGGEST common problem categories
2. ASK architect to confirm which apply
3. GENERATE concise list
4. VERIFY each problem has 1-2 sentence explanation

---

## Section 6: Future Expansion (What Might Be Added)

### Recall vs Reasoning

**Recall**: Disclaimer language (from instructions)

**Reasoning**: Identifying possible evolution areas without commitment

### What Agent Must Ask

- "What capabilities might be added in the future without violating core non-goals?"
- "What areas of the architecture are intentionally flexible for evolution?"

### Critical Checks

- ✅ Opening disclaimer: "Not commitments"
- ✅ No capabilities that violate core non-goals
- ✅ No timelines or roadmap items
- ✅ Closing disclaimer: "Requires architecture review"

### Interaction Pattern

1. ASK for potential expansion areas
2. CHALLENGE any expansion that violates non-goals: "Didn't you exclude this in Section 2?"
3. VERIFY disclaimers present
4. VERIFY no timelines or commitments

---

## Section 7: Implications for Architecture and Governance

### Recall vs Reasoning

**Recall**: Four subsection structure (from template)

**Reasoning**: Tailoring practical guidance to this platform/system/service

### What Agent Can Infer

Standard governance patterns from instructions:
- Feature request evaluation process
- Architecture review lens
- Consumer expectation setting
- Evolution constraints

### What Agent Must Ask

- "How should feature requests be evaluated using these non-goals?"
- "What should architecture reviews check for?"

### Interaction Pattern

1. INFER standard structure from instructions
2. TAILOR language to match terminology (platform/system/service)
3. GENERATE four subsections
4. VERIFY practical guidance provided (not theoretical)

---

## Section 8: Summary: Platform Scope Lens

### Recall vs Reasoning

**Recall**: Three-category structure (In Scope / Out of Scope / By Design)

**Reasoning**: Synthesizing categorization from previous sections

### What Agent Can Infer

- In Scope: Synthesize from System Context and Architecture Specifications
- Out of Scope: Synthesize from Core Non-Goals
- By Design: Synthesize from Guardrails

### What Agent Must Ask

- "Are these categorizations accurate?"
- "Any items to add or remove?"

### Critical Checks

- ✅ Each category has 4-6 concise bullets
- ✅ No overlap between categories
- ✅ Closing statement reinforces boundary maintenance

### Interaction Pattern

1. INFER categorization from previous sections
2. GENERATE three-category lens
3. ASK architect to verify accuracy
4. REFINE based on feedback

---

## Handling Uncertainty

### When Architect Provides Vague Input

**Scenario**: Architect says "We don't support all use cases"

**Response**: 
1. Ask: "Which specific use case or capability is excluded?"
2. Challenge: "Is this a specific non-goal (e.g., 'consumer-specific optimization') or a general statement?"
3. Guide: "Non-goals should be concrete. Could this be 'Consumer-Specific Data Shapes or Projections'?"

### When Rationale is Weak

**Scenario**: Architect says "We don't have time for this"

**Response**:
1. Challenge: "Is this a temporary deferral or an intentional exclusion?"
2. Ask: "If you had unlimited time, would you still exclude this capability? Why or why not?"
3. Guide: "Rationale should focus on architectural principles, not resource constraints."

### When Redirection is Missing

**Scenario**: Non-goal states what's excluded but not what consumers should do

**Response**:
1. Ask: "What should consumers do to solve this problem themselves?"
2. Prompt: "Should they build their own infrastructure? Use a different system? Change their design?"
3. Guide: "Provide 3-5 numbered steps for concrete redirection."

### When Guardrail Tradeoff is Unclear

**Scenario**: Guardrail states constraint but not what's gained/lost

**Response**:
1. Ask: "What benefit does this constraint provide?"
2. Ask: "What precision or capability is sacrificed?"
3. Guide: "Explain both sides of the tradeoff."

---

## Quality Gates

Before considering a section complete, verify:

### Non-Goals Section
- [ ] Each non-goal follows three-part pattern
- [ ] "What we do NOT do" is definitive, not conditional
- [ ] "Why this matters" connects to architectural principle
- [ ] "What instead" is concrete numbered list
- [ ] No apologetic or defensive language

### Guardrails Section
- [ ] Each guardrail follows four-part pattern
- [ ] "Tradeoff accepted" explains both benefits and costs
- [ ] "Design implication" is concrete and actionable
- [ ] Language is transparent, not apologetic

### Tradeoffs Section
- [ ] Each tradeoff states two competing options
- [ ] Decision clearly stated
- [ ] Impact described for both platform and consumers

### Governance Section
- [ ] All four subsections present
- [ ] Practical guidance provided
- [ ] Not theoretical or abstract

### Summary Lens
- [ ] Three categories present
- [ ] 4-6 bullets each
- [ ] No overlap between categories

---

## Final Review Checklist

When architect requests final review, verify:

**Completeness**:
- [ ] All 8 sections present
- [ ] All patterns followed
- [ ] YAML frontmatter complete

**Consistency**:
- [ ] Terminology consistent (platform/system/service)
- [ ] No contradictions between sections
- [ ] Cross-references accurate

**Quality**:
- [ ] Language definitive, not apologetic
- [ ] Rationale strong, not weak
- [ ] Redirection concrete, not vague
- [ ] Tradeoffs balanced, not defensive

**Actionability**:
- [ ] Governance guidance practical
- [ ] Consumer redirection achievable
- [ ] Summary lens usable for decisions

---

## Example Interactions

### Good Interaction: Clarifying Vague Non-Goal

**Architect**: "We don't support real-time"

**Agent**: 
> "Let's make this non-goal more specific. Are you excluding:
> 1. Real-time, sub-second delivery guarantees?
> 2. Real-time processing of events?
> 3. Real-time queries?"

**Architect**: "Real-time delivery guarantees"

**Agent**: 
> "Great. Why is this intentionally excluded? For example:
> - Infrastructure investment too high?
> - Couples platform to upstream behavior?
> - Most use cases don't require it?"

### Bad Interaction: Accepting Weak Rationale

**Architect**: "We exclude query APIs because we don't have time"

**Agent**: ❌ *Generates non-goal with weak rationale*

**Correct Agent Behavior**: ✅
> "Weak rationale. Non-goals should reflect architectural decisions, not resource constraints. 
>
> Would you still exclude query APIs if you had unlimited resources? If yes, why? For example:
> - Mixing query workloads with event transport degrades scalability?
> - Consumers have diverse query patterns that can't be generalized?
> - Platform should remain stateless?"

### Good Interaction: Strengthening Redirection

**Architect**: "Consumers should build it themselves"

**Agent**:
> "Let's make redirection more specific. What should consumers build? For example:
> 1. Consume events and project into their own read model?
> 2. Build search indexes (Elasticsearch, Azure Search)?
> 3. Expose query APIs tailored to their domain?
> 4. Optimize indexes for their workloads?"

**Architect**: "Yes, all of that"

**Agent**: ✅ *Generates numbered list with those steps*

---

## Summary

When generating Non-Goals and Guardrails content:

1. **Defer strategic decisions** (which capabilities to exclude, which guardrails to highlight)
2. **Enforce patterns strictly** (three-part, four-part structures)
3. **Challenge weak rationale** (connect to architectural principles)
4. **Demand concrete redirection** (actionable consumer guidance)
5. **Eliminate apologetic language** (intentional, not unfortunate)
6. **Verify completeness** (all patterns followed, all sections present)

This document establishes boundaries. Those boundaries must be clear, justified, and actionable. The agent's role is to help the architect articulate those boundaries with precision and confidence.
