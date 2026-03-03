---
title: Process Flow Agent Guidance
summary: Rules for GitHub Copilot when generating Process Flow documents
tags:
  - process-flow
  - architecture
---

# Process Flow: Agent Guidance

## Purpose

This document defines how GitHub Copilot should behave when assisting architects in creating Process Flow documents. It specifies when to recall, reason, infer, clarify, or defer, and how to ensure output is reviewable and complete.

---

## General Principles

- **Section Independence**: Each section must be generatable, reviewable, and updatable independently.
- **No Implementation Details**: Never invent or infer service-specific logic, code, or technology details.
- **Explicit Branching**: Always separate happy path, alternatives, and error flows in both narrative and diagrams.
- **Actor Consistency**: Use actor/system names exactly as defined in the Actors and Systems section.
- **Diagram Requirement**: Every happy path, primary alternative, and error/exception flow must have its own sequence diagram using Mermaid syntax.
- **Completeness**: Ensure all required sections are present and populated for each process flow.

---

## Section-by-Section Guidance

### YAML Frontmatter
- **Recall**: Always use "Process Flow" as the title.
- **Infer**: Summary and tags from document content.
- **Clarify**: If domain/capability tags are ambiguous, ask the architect.

### Purpose and Scope
- **Recall**: Standard structure and intent.
- **Clarify**: If process boundaries or related flows are unclear, ask the architect.
- **Defer**: Never assume what is in/out of scope—always confirm.

### Actors and Systems
- **Recall**: Table format, unique names, and roles.
- **Clarify**: If an actor/system is referenced but not defined, prompt for definition.
- **Enforce**: Consistent naming across all sections and diagrams.

### Preconditions and Assumptions
- **Recall**: List format.
- **Clarify**: If any required precondition or assumption is missing or ambiguous, ask for details.

### Process Overview
- **Recall**: Narrative summary only.
- **Clarify**: If the main goal or phases are unclear, ask for clarification.

### Happy Path
- **Reasoning**: Short narrative description, sequence diagram using Mermaid syntax, accessibility label, and numbered steps.
- **Clarify**: If any step, actor, action, or flow description is missing or ambiguous, ask for specifics.
- **Enforce**: Only include primary alternatives; do not include error/exception flows here.
- **Enforce**: Include an HTML accessibility label with aria-label attribute above the diagram.
- **Defer**: Never invent steps, actors, or narrative descriptions not defined elsewhere.

### Primary Alternatives
- **Reasoning**: For each major branch, generate a short narrative description, a diagram using Mermaid syntax, an accessibility label, and numbered steps.
- **Clarify**: If a branch is referenced but not described, or if narrative/steps are ambiguous, prompt for details.
- **Enforce**: Include an HTML accessibility label with aria-label attribute above each diagram.
- **Defer**: Never combine alternatives with the happy path or with each other.

### Error and Exception Flows
- **Reasoning**: For each error/exception, generate a short narrative description, a diagram using Mermaid syntax, an accessibility label, and numbered steps.
- **Clarify**: If an error is referenced but not described, or if narrative/steps are ambiguous, prompt for details.
- **Enforce**: Include an HTML accessibility label with aria-label attribute above each diagram.
- **Defer**: Never combine error flows with the happy path or alternatives.

### State and Data Considerations
- **Recall**: Only include if relevant.
- **Clarify**: If state/data is referenced in the process but not described, ask for details.

### Notes and Comments
- **Recall**: Use for edge cases, clarifications, or rationale only.
- **Clarify**: If a note references a process step or requirement, prompt to move it to the correct section.

### References
- **Recall**: List authoritative sources only.
- **Clarify**: If a requirement or reference is mentioned but not listed, prompt for inclusion.

---

## Inference, Clarification, and Deferral Rules

- **Inference Allowed**: Section headings, formatting, enforcing template structure, language refinement.
- **Clarification Required**: Missing actors, steps, branches, diagrams, or narrative descriptions; ambiguous process boundaries or flow descriptions; unclear requirements.
- **Deferral Mandatory**: Any decision about process scope, actor responsibilities, error handling, or narrative flow not explicitly defined by the architect.
- **Enforcement Required**: Section ordering (Notes and Comments before References); all diagrams must use Mermaid syntax; all diagrams must include HTML accessibility labels with aria-label attributes.

---

## Reviewability and Governance

- Ensure every section and diagram is reviewable and updatable independently.
- Output must be suitable for section-by-section review and approval by architects.
- All diagrams must use Mermaid syntax for sequence diagrams.
- All diagrams must include HTML accessibility labels with aria-label attributes.
- Happy Path, Primary Alternatives, and Error/Exception Flows must follow the format: narrative description, diagram, accessibility label, and numbered steps.
- Section ordering is mandatory: Notes and Comments must precede References.
- Never invent or assume narrative descriptions, business logic, error handling, or actor responsibilities—always clarify or defer to the architect.
