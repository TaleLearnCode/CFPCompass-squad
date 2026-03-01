# Architecture Guide – Authoring Instructions

These instructions define the purpose, expected content, and boundaries for each section of the Architecture Guide. They are intended for both human authors and agent-assisted generation. Use canonical architectural vocabulary and ensure content is system-agnostic and non-redundant with other documents in the architecture set.


---

## YAML Header (Front Matter)
**Intent:** Provide metadata for MkDocs navigation, search, and organization.
**Inputs:**
- `title`: The document title (e.g., "Architecture Guide").
- `summary`: A brief summary of the document’s purpose or scope.
- `tags`: A list of relevant tags (e.g., architecture, guide, overview).
**Assumptions:** The YAML header is placed at the top of the markdown file, enclosed by `---` lines.
**Prohibited Content:** Do not include architectural content or project details in the YAML header.

**Example:**
```
---
title: Architecture Guide
summary: High-level architectural overview for [System/Service Name].
tags:
	- architecture
	- guide
	- overview
---
```

---

## Purpose & Audience

**Intent:** State the overall purpose of the document and identify its intended audience.
**Inputs:** High-level summary of the document’s role in the architecture set; list of roles or groups expected to use or review the document.
**Assumptions:** The audience may include architects, developers, platform engineers, IT support, product owners, and management.
**Prohibited Content:** Do not include technical solution details or requirements.

---
## Business Purpose

**Intent:** Describe why the service exists, its strategic value, and the business outcomes it enables.
**Inputs:** Mission or strategic role of the service; key business stakeholders or users; primary business problem or opportunity it addresses; high-level business metrics or outcomes.
**Assumptions:** This section should be accessible to non-technical stakeholders and grounded in business value, not technical implementation.
**Prohibited Content:** Do not include technical architecture details, implementation specifics, or requirements lists.

---
## Architectural Overview
**Intent:** Provide a high-level summary of the system’s architecture, including its guiding principles and major structural elements.
**Inputs:** Narrative description of the architecture, key patterns or paradigms, and (where helpful) high-level diagrams embedded in context.
**Assumptions:** This section should be readable by all project participants and avoid deep technical detail.
**Prohibited Content:** Do not include detailed component breakdowns, integration specifics, or implementation details.

---

## Solution Context
**Intent:** Describe the system’s environment, boundaries, and relationships to external systems or platforms.
**Inputs:** Overview of system boundaries, major external dependencies, and context diagrams as needed.
**Assumptions:** Focus on what is external to the system and how the system fits into the broader landscape.
**Prohibited Content:** Do not duplicate content from the System Context & Logical Components document; avoid detailed interface specifications.

---

## Key Requirements
**Intent:** Summarize the most important functional and non-functional requirements that drive architectural decisions.
**Inputs:** List or summary of requirements that have significant architectural impact, referencing source documents where appropriate.
**Assumptions:** Only include requirements that shape the architecture at a high level.
**Prohibited Content:** Do not include exhaustive requirements lists or implementation-level details.

---

## Security and Compliance
**Intent:** Outline the principal security and compliance considerations relevant to the architecture.
**Inputs:** High-level security objectives, compliance standards, and key controls or constraints.
**Assumptions:** This section is not a detailed security design, but a summary of architectural security posture.
**Prohibited Content:** Do not include detailed security implementation steps or operational procedures.

---

## Non-Functional Requirements
**Intent:** Capture the main non-functional requirements (e.g., performance, scalability, availability, maintainability) that influence architectural choices.
**Inputs:** Summary of non-functional drivers, with references to source requirements as needed.
**Assumptions:** Focus on requirements that affect architecture, not operational targets or SLAs.
**Prohibited Content:** Do not include detailed test plans or operational metrics.

---

## Appendices / References
**Intent:** Provide references to supporting documents, registers, and other artifacts relevant to the architecture.
**Inputs:** Links or citations to risk register, assumption register, decision log/ADR register, and other relevant documents.
**Assumptions:** This section is for reference only; do not duplicate register content here.
**Prohibited Content:** Do not include substantive architectural content or register entries themselves.

---

**General Guidance:**
- Do not repeat information managed in other documents (e.g., risks, assumptions, decisions).
- Use clear, concise, and system-agnostic language.
- Ensure each section is reviewable and maintainable independently.
- Avoid embedding tool-specific instructions or behaviors.
