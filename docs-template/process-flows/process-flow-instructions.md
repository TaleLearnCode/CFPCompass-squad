---
title: Process Flow Instructions
summary: Authoring guidance for creating Process Flow documents
tags:
  - process-flow
  - architecture
---

# Process Flow: Authoring Instructions


## Document Overview

The Process Flow document set describes the end-to-end flow of one or more key business or technical processes for a given system or service. Each process flow document provides a clear, reviewable, and implementation-ready description of how a specific process works, including all major branches, alternatives, and error states, using both narrative and sequence diagrams.

**How many process flows?**
- Most architectures require multiple process flow documents—one for each distinct business or technical process that must be understood, implemented, or governed independently.
- Each process flow should focus on a single, well-bounded process (e.g., "Order Submission", "Backfill Orchestration", "Scan and Log").
- Do not combine unrelated processes into a single document. If a process is complex and has major sub-flows, consider separate documents for each sub-flow.

**Who uses these documents?**
- Architects: To define and communicate process boundaries, logic, and integration points.
- Developers: To understand the expected system behavior, sequence of operations, and error handling.
- QA/Testers: To derive test cases for all major flows and exceptions.
- Stakeholders: To review and approve process logic, alternatives, and error handling.

**What makes a process flow document complete?**
- All actors and systems are clearly defined and used consistently.
- The happy path (main flow) is described in detail, with a required sequence diagram.
- All primary alternatives (major branches, options, or requirement-driven variations) are described and diagrammed separately.
- All major error and exception flows are described and diagrammed separately.
- Preconditions, assumptions, and state/data considerations are explicit.
- The document is reviewable section-by-section, and each diagram is focused and readable.

---

## YAML Frontmatter

### Purpose
Provides metadata for documentation systems and enables discovery, tagging, and summary presentation.

### Required Fields
- **title**: Always "Process Flow"
- **summary**: One sentence (≤20 words) describing the process flow's scope
- **tags**: Always include `process-flow` and `architecture`, plus domain/capability tags as appropriate

---

## Section Guidance


### Purpose and Scope
- **Intent**: Clearly state which process is being documented, why it is important, and what is included/excluded from the scope.
- **Inputs**: Process name, business/technical context, boundaries, related processes (if any).
- **Guidance**:
  - Write a concise summary of the process and its business or technical value.
  - Explicitly state what is in scope for this document and what is not (e.g., "This document covers the Scan and Log process only; error handling for device failures is covered in a separate process flow.").
  - If this is one of several process flows for the system, reference the others.
- **Constraints**: No implementation or code details; focus on process logic and boundaries.


### Actors and Systems
- **Intent**: List every participant (system, service, application, human role, or external entity) that interacts in the process, and describe their responsibilities.
- **Inputs**: Actor/system names, roles/descriptions, integration points.
- **Guidance**:
  - Use a table to define each actor/system, with a clear, unique name and a short description of its role in the process.
  - Use the same names for actors/systems in all diagrams and throughout the document.
  - Include both initiating actors (who start the process) and responding actors (who receive, process, or store information).
  - If an actor is optional or only appears in certain branches, note this in the description.
- **Constraints**: No implementation details (e.g., do not specify technology or code); focus on logical roles.


### Preconditions and Assumptions
- **Intent**: Specify all conditions, states, or data that must be true or available before the process can begin.
- **Inputs**: Required system states, data, external conditions, dependencies on other processes.
- **Guidance**:
  - List all preconditions explicitly (e.g., "User is authenticated", "Device is online", "Inventory is available").
  - Include assumptions about data, system state, or environment (e.g., "Network connectivity is stable").
  - If the process depends on the completion of another process, reference it here.
- **Constraints**: Do not describe process steps or logic here; focus only on starting conditions.


### Process Overview
- **Intent**: Provide a high-level, narrative summary of the process from start to finish, including the main goal and key phases.
- **Inputs**: High-level description of the flow, main objectives, and any key transitions.
- **Guidance**:
  - Write 1-2 paragraphs summarizing the process, its purpose, and its main phases.
  - Mention the happy path, primary alternatives, and error handling at a high level.
  - Do not include step-by-step details; save those for later sections.
- **Constraints**: Keep concise and focused on the big picture.


### Happy Path
- **Intent**: Describe the main, expected flow of the process from initiation to successful completion, including all primary alternatives identified in requirements.
- **Inputs**: Short narrative description, required sequence diagram, accessibility label, and numbered steps.
- **Guidance**:
  - Write a short, clear narrative (1-2 paragraphs) describing the happy path flow and its business value.
  - Create a required sequence diagram using Mermaid syntax showing only the main flow and primary alternatives (not error states).
  - Include an HTML accessibility label above the diagram: `<div align="center" aria-label="[Diagram Description]"><strong>Figure N: [Title]</strong></div>`
  - List each step in the happy path in order, using clear, numbered steps that correspond to the diagram.
  - For each step, specify the actor/system involved and the action taken.
  - Include all primary alternatives (e.g., user cancels, optional steps) as numbered steps if they are part of the main requirements.
  - Keep the diagram focused and readable; do not overload with every possible branch.
  - Reference the diagram in the narrative (e.g., "See Figure 1").
- **Constraints**: Do not include error or exception flows here; those go in later sections.


### Primary Alternatives
- **Intent**: Document each major branch, option, or requirements-driven variation in the process that is not part of the main happy path.
- **Inputs**: Short narrative description, sequence diagram, accessibility label, and numbered steps for each alternative.
- **Guidance**:
  - Create a separate subsection for each primary alternative (e.g., "User Cancels Order", "Optional Approval Step").
  - Write a short, clear narrative (1-2 paragraphs) describing this alternative flow.
  - Create a required sequence diagram using Mermaid syntax showing this alternative branch.
  - Include an HTML accessibility label above the diagram: `<div align="center" aria-label="[Diagram Description]"><strong>Figure N: [Alternative Name]</strong></div>`
  - List numbered steps for this alternative that correspond to the diagram.
  - Only include alternatives that are significant and driven by requirements or business rules.
  - Do not document minor variations or edge cases here; use the Notes section for those.
  - Reference the diagram in the narrative.
- **Constraints**: Each alternative must be reviewable and understandable on its own.


### Error and Exception Flows
- **Intent**: Document each major error, failure, or exception state that can occur during the process, with a separate description and diagram for each.
- **Inputs**: Short narrative description, sequence diagram, accessibility label, and numbered steps for each error/exception.
- **Guidance**:
  - Create a separate subsection for each error or exception (e.g., "Device Offline", "Validation Failure").
  - Write a short, clear narrative (1-2 paragraphs) describing this error/exception flow and its handling.
  - Create a required sequence diagram using Mermaid syntax showing this error/exception path.
  - Include an HTML accessibility label above the diagram: `<div align="center" aria-label="[Diagram Description]"><strong>Figure N: [Error/Exception Name] Exception Flow</strong></div>`
  - List numbered steps for this error/exception that correspond to the diagram.
  - Focus on errors that are meaningful for implementation, testing, or governance.
  - Do not combine error flows with the happy path or alternatives; keep diagrams focused.
  - Reference the diagram in the narrative.
- **Constraints**: Each error/exception must be a distinct, reviewable branch.


### State and Data Considerations
- **Intent**: Describe any relevant state transitions, persistence, or data storage considerations that affect the process.
- **Inputs**: State transitions, persistence, data dependencies, data handoffs (if applicable).
- **Guidance**:
  - Only include this section if the process involves stateful operations, data storage, or significant data dependencies.
  - Describe how state is managed, what data is persisted, and any important data handoffs between actors/systems.
  - If the process is stateless, state this explicitly (e.g., "This process is stateless; no data is persisted.").
- **Constraints**: Omit if not relevant to the process.


### Notes and Comments
- **Intent**: Capture edge cases, clarifications, rationale for design choices, or implementation notes that do not fit elsewhere.
- **Inputs**: Any additional information, rationale, or context not covered in other sections.
- **Guidance**:
  - Use this section for minor variations, rare edge cases, or clarifications that are not significant enough for their own alternative or error flow.
  - Provide rationale for any unusual design decisions or process choices.
  - Do not use this section for requirements, process steps, or major branches.
  - **Notes and Comments must always precede the References section.**
- **Constraints**: No requirements or process steps here.


### References
- **Intent**: List all related requirements, upstream/downstream documentation, or other authoritative references that inform or constrain the process.
- **Inputs**: Document names, links, requirement IDs, related process flows.
- **Guidance**:
  - Reference all requirements that drive the process logic, including IDs or links.
  - Include links to upstream/downstream system documentation, interface contracts, or related process flows.
  - Only reference authoritative, version-controlled sources.
- **Constraints**: No informal or non-authoritative references.

---


## Prohibited Content
- No service-specific implementation details (e.g., do not mention specific technologies, endpoints, or code)
- No procedural or instructional language in the template (instructions belong only in this file)
- No code, pseudo-code, or implementation logic

---


## Completeness Criteria
- All required sections present and populated for each process flow
- Each process flow document covers a single, well-bounded process
- All actors/systems are defined and used consistently across narrative and diagrams
- The happy path is fully described and diagrammed, including all primary alternatives
- Each major alternative and error/exception flow has its own step-by-step description and sequence diagram
- Happy path, alternatives, and errors are clearly separated (not combined in one diagram)
- Preconditions, assumptions, and state/data considerations are explicit
- All diagrams are created using Mermaid syntax
- Section ordering is correct: Notes and Comments precedes References at the end
- No implementation or code details anywhere
- Document is reviewable and maintainable section-by-section
