---
title: API Contract Agent Guidance
summary: Rules for GitHub Copilot when generating API Contract documents
---

# API Contract: Agent Guidance

## Purpose

This document defines how GitHub Copilot should behave when assisting architects in creating API Contract documents. It specifies when to recall, reason, infer, clarify, or defer, and how to ensure output is reviewable and complete.

---

## General Principles
- **Section Independence:** Each section must be generatable, reviewable, and updatable independently.
- **No Implementation Details:** Never invent or infer service-specific logic, code, or technology details.
- **Explicit Boundaries:** Always separate contract (what/why) from implementation (how).
- **Stable Section Order:** Use the template's section order and headings exactly.
- **Completeness:** Ensure all required sections are present and populated for each API contract.

---

## Section-by-Section Guidance

### YAML Frontmatter
- **Recall:** Always use "API Contract" as the title.
- **Infer:** Summary and tags from document content.
- **Clarify:** If domain/capability tags are ambiguous, ask the architect.

### Purpose and Scope
- **Recall:** Standard structure and intent.
- **Clarify:** If API boundaries or related artifacts are unclear, ask the architect.
- **Defer:** Never assume what is in/out of scope—always confirm.

### API Responsibilities
- **Recall:** List format, explicit boundaries.
- **Clarify:** If responsibilities are ambiguous, prompt for clarification.
- **Enforce:** No implementation logic.

### Request Model
- **Recall:** List and describe all fields, constraints, and validation rules.
- **Clarify:** If any field, constraint, or rule is missing or ambiguous, ask for details.
- **Enforce:** No implementation or code details.

### Request Validation and Governance Rules
- **Recall:** List validation and governance rules.
- **Clarify:** If any rule is missing or ambiguous, ask for details.
- **Enforce:** No implementation logic.

### Execution Semantics
- **Recall:** Describe acceptance, attachment, and rejection flows.
- **Clarify:** If any flow or guarantee is unclear, ask for clarification.
- **Enforce:** No implementation or code details.

### Response Model
- **Recall:** Describe success and error responses, observability endpoints.
- **Clarify:** If any response or endpoint is missing or ambiguous, ask for details.
- **Enforce:** No implementation or code details.

### Status and Observability
- **Recall:** Describe status endpoints and observability mechanisms.
- **Clarify:** If any status or observability detail is missing, ask for clarification.
- **Enforce:** No implementation or code details.

### Error Handling
- **Recall:** List error types and handling at the API boundary.
- **Clarify:** If any error type or handling is missing, ask for details.
- **Enforce:** No implementation or code details.

### Security and Access Control
- **Recall:** Describe authentication, authorization, and trust model.
- **Clarify:** If any security or access control detail is missing, ask for clarification.
- **Enforce:** No implementation or code details.

### Relationship to Other Artifacts
- **Recall:** List and describe related artifacts.
- **Clarify:** If any related artifact is missing or ambiguous, ask for clarification.
- **Enforce:** Only reference authoritative, version-controlled sources.

### Notes and Comments
- **Recall:** Use for clarifications or rationale only.
- **Clarify:** If a note references a requirement or process step, prompt to move it to the correct section.

### References
- **Recall:** List authoritative sources only.
- **Clarify:** If a requirement or reference is mentioned but not listed, prompt for inclusion.

---

## Inference, Clarification, and Deferral Rules
- **Inference Allowed:** Section headings, formatting, enforcing template structure, language refinement.
- **Clarification Required:** Missing fields, rules, flows, or references; ambiguous boundaries or requirements.
- **Deferral Mandatory:** Any decision about scope, responsibilities, or error handling not explicitly defined by the architect.
- **Enforcement Required:** Section ordering and headings must match the template exactly.

---

## Reviewability and Governance
- Ensure every section is reviewable and updatable independently.
- Output must be suitable for section-by-section review and approval by architects.
- Never invent or assume business logic, error handling, or responsibilities—always clarify or defer to the architect.
