---
title: Data Model Instructions
summary: Authoring guidance for creating Data Model documents
tags:
  - data-model
  - architecture
---

# Data Model: Authoring Instructions

## Document Overview

The Data Model document describes the structure, purpose, and lifecycle of a specific dataset or storage entity (table, container, or document type). It defines how data is shaped, how it is stored and accessed, and how it is governed over time. This document is intended for architects, developers, and reviewers who need a clear, stable, and reviewable data contract.

**How many data models?**
- An architecture may have zero, one, or many data model documents.
- Create a separate document for each distinct data store, container, table, or projection with its own schema and access patterns.
- Do not combine unrelated datasets into one document. If two models have different partitioning, lifecycle, or governance, they should be separate documents.

**What makes a data model document complete?**
- Purpose and scope are explicit, including whether the model is a system of record or a projection.
- The schema is clearly defined with an ER diagram and field descriptions.
- Partitioning and identifiers are explained with rationale.
- Data source and lifecycle are documented, including authoritative source and ingestion flow.
- Access patterns (supported and unsupported) are explicit.
- Governance, schema evolution, and retention rules are documented.

---

## YAML Frontmatter

### Purpose
Provides metadata for documentation systems and enables discovery, tagging, and summary presentation.

### Required Fields
- **title**: Always "Data Model"
- **summary**: One sentence (<=20 words) describing the data model scope
- **tags**: Always include `data-model` and `architecture`, plus domain/capability tags as appropriate

---

## Section Guidance

### Purpose
- **Intent**: Explain why this data model exists, what it enables, and whether it is a system of record or a projection.
- **Inputs**: Business or technical purpose, scope boundaries, ownership model.
- **Guidance**:
  - State if the model is authoritative or derived from an upstream source.
  - Describe the key use cases it supports.
  - Clarify what the model does not cover if scope boundaries are important.
- **Constraints**: No implementation detail or code; focus on data contract and intent.

### Schema Definition
- **Intent**: Define the data shape and contract for this model.
- **Inputs**: Entity fields, types, descriptions, required/optional indicators.
- **Guidance**:
  - Include an ER diagram for the data model.
  - Provide a field list or table with descriptions for all fields.
  - If the model is a projection, include a field source mapping.
  - Use consistent field names and terminology across the document.
- **Constraints**: No code, ORM annotations, or tool-specific syntax beyond the diagram.

### Partitioning and Identifier Strategy
- **Intent**: Explain how data is partitioned and identified, and why.
- **Inputs**: Partition key, primary key, row key, identifiers, unique constraints.
- **Guidance**:
  - Describe the partition key and identifier(s) explicitly.
  - Explain how this strategy supports the primary access patterns.
  - Include any tradeoffs (e.g., limited cross-partition queries).
- **Constraints**: Avoid implementation specifics like SDK calls or deployment settings.

### Data Source and Lifecycle
- **Intent**: Describe where the data originates, how it is ingested, and how it evolves.
- **Inputs**: Authoritative source, ingestion mechanism, lifecycle transitions.
- **Guidance**:
  - Identify the authoritative source system.
  - Describe ingestion flow, including triggers or events.
  - Describe lifecycle states or transitions if nontrivial.
  - Use diagrams if they add clarity to ingestion or lifecycle.
- **Constraints**: No operational runbooks or deployment instructions.

### Access Patterns
- **Intent**: Define how consumers are expected to query or read the model.
- **Inputs**: Supported query patterns, expected filters, partition alignment.
- **Guidance**:
  - List supported patterns and why they are efficient.
  - List unsupported patterns explicitly to set boundaries.
  - If projections are required for unsupported patterns, call that out.
- **Constraints**: No query code or specific SDK examples.

### Governance and Retention
- **Intent**: Define ownership, access control, schema evolution, and retention.
- **Inputs**: Read/write access, schema versioning, retention or TTL rules.
- **Guidance**:
  - State who can write and who can read the model.
  - Describe schema versioning or evolution strategy.
  - Document retention rules, TTL, archival, or purge policies.
- **Constraints**: Avoid tool-specific governance mechanics.

### Design Notes
- **Intent**: Capture rationale, tradeoffs, and operational boundaries.
- **Inputs**: Design decisions, constraints, and non-obvious choices.
- **Guidance**:
  - Explain why key design choices were made (partitioning, schema shape).
  - Note any operational boundaries or constraints.
- **Constraints**: Keep focused on rationale, not implementation details.

### Related Specifications
- **Intent**: Link to relevant authoritative documents.
- **Inputs**: API specs, appendices, upstream/downstream docs, requirement IDs.
- **Guidance**:
  - Reference only authoritative sources.
  - Keep links relevant to the model and its lifecycle.
- **Constraints**: No informal references.

---

## Prohibited Content
- No service-specific implementation details or code
- No procedural or instructional language in the template
- No tool-specific diagramming requirements
- No direct dependency on runtime configurations

---

## Completeness Criteria
- All required sections are present and populated
- Purpose clearly states system of record or projection
- Schema definition includes ER diagram and field descriptions
- Partitioning/identifier strategy is explicit with rationale
- Data source and lifecycle are documented
- Access patterns include supported and unsupported usage
- Governance and retention are documented
- Document is reviewable section-by-section
