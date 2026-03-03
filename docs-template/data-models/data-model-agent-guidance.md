---
title: Data Model Agent Guidance
summary: Rules for GitHub Copilot when generating Data Model documents
tags:
  - data-model
  - architecture
---

# Data Model: Agent Guidance

## Purpose

This document defines how GitHub Copilot should behave when assisting architects in creating Data Model documents. It specifies when to recall, reason, infer, clarify, or defer, and how to ensure output is reviewable and complete.

---

## General Principles

- **Section Independence**: Each section must be generatable, reviewable, and updatable independently.
- **No Implementation Details**: Never invent or infer service-specific logic, code, or technology details.
- **Schema Fidelity**: Do not invent fields or data sources without architect confirmation.
- **Access Pattern Alignment**: Ensure partitioning and identifiers support the stated access patterns.
- **Governance Clarity**: Always include ownership, read/write access, schema evolution, and retention.

---

## Section-by-Section Guidance

### YAML Frontmatter
- **Recall**: Always use "Data Model" as the title.
- **Infer**: Summary and tags from document content.
- **Clarify**: If domain/capability tags are ambiguous, ask the architect.

### Purpose
- **Recall**: State purpose, scope, and system-of-record vs projection.
- **Clarify**: If authoritative source or ownership is unclear, ask the architect.
- **Defer**: Never assume the model is authoritative or derived without confirmation.

### Schema Definition
- **Reasoning**: Structure ER diagram and field list based on provided schema.
- **Clarify**: If field definitions, types, or required/optional status are missing, ask.
- **Defer**: Do not invent fields, types, or relationships.

### Partitioning and Identifier Strategy
- **Reasoning**: Explain partition key and identifiers based on provided access patterns.
- **Clarify**: If access patterns are unclear or missing, ask before proposing keys.
- **Defer**: Do not choose partition keys or identifiers without architect input.

### Data Source and Lifecycle
- **Recall**: Identify authoritative source and ingestion flow.
- **Clarify**: If ingestion triggers or lifecycle transitions are missing, ask.
- **Defer**: Do not invent lifecycle transitions or retention paths.

### Access Patterns
- **Reasoning**: Summarize supported and unsupported patterns.
- **Clarify**: If consumers or query needs are missing, ask for details.
- **Enforce**: Always list unsupported patterns explicitly.

### Governance and Retention
- **Recall**: Include read/write access, schema evolution, retention.
- **Clarify**: If ownership or retention rules are unclear, ask.
- **Defer**: Do not assume access rights or retention policies.

### Design Notes
- **Reasoning**: Summarize rationale and tradeoffs from provided context.
- **Clarify**: If rationale is missing, ask for the architectural reasons.

### Related Specifications
- **Recall**: Link to authoritative sources only.
- **Clarify**: If related docs are mentioned but not listed, prompt for inclusion.

---

## Inference, Clarification, and Deferral Rules

- **Inference Allowed**: Section headings, formatting, consistency checks, and language refinement.
- **Clarification Required**: Missing fields, missing authoritative sources, unclear access patterns, or governance gaps.
- **Deferral Mandatory**: Any decision about schema shape, partition keys, access rights, or retention policies without architect confirmation.

---

## Reviewability and Governance

- Ensure every section is reviewable and updatable independently.
- Output must be suitable for section-by-section review and approval by architects.
- Never invent or assume schema elements, lifecycle transitions, or ownership details.
