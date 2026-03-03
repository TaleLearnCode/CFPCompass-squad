---
title: Process Flow
summary: [1-sentence description of process flow scope]
tags:
  - process-flow  # Required
  - architecture  # Required
  - [domain-specific tags]  # e.g., manufacturing, integration
  - [capability tags]       # e.g., orchestration, messaging
---

# [Process Name] Process Flow

## Purpose and Scope
[What this process flow covers and why it matters]

## Actors and Systems
| Actor/System | Role/Description |
|--------------|------------------|
| [Name]       | [Role]           |
| ...          | ...              |

## Preconditions and Assumptions
[List any required preconditions or assumptions]

## Process Overview
[Short narrative summary of the process]

## Happy Path
[Short narrative description of the happy path flow]

```mermaid
[Sequence diagram (Mermaid) showing the main flow]
```

<div align="center" aria-label="[Diagram Description]">
<strong>Figure N: [Happy Path Title]</strong>
</div>

[Numbered list of steps in the happy path]

## Primary Alternatives
### [Alternative Name]
[Short narrative description of this alternative flow]

```mermaid
[Sequence diagram (Mermaid) showing this alternative]
```

<div align="center" aria-label="[Diagram Description]">
<strong>Figure N: [Alternative Name]</strong>
</div>

[Numbered list of steps for this alternative]

<!-- Repeat above subsection for each major alternative -->

## Error and Exception Flows
### [Error/Exception Name]
[Short narrative description of this error/exception flow]

```mermaid
[Sequence diagram (Mermaid) showing this error/exception]
```

<div align="center" aria-label="[Diagram Description]">
<strong>Figure N: [Error/Exception Name] Exception Flow</strong>
</div>

[Numbered list of steps for this error or exception]

<!-- Repeat above subsection for each major error/exception -->

## State and Data Considerations
[Describe any relevant state or data storage considerations, if applicable]

## Notes and Comments
[Edge cases, clarifications, or implementation notes]

## References
[List related requirements, upstream/downstream docs, or other references]
