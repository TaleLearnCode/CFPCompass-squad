# Infrastructure Architecture Document Instructions

## Overview
- Intent: Summarize the purpose and context of the infrastructure architecture for the specific system/service.
- Expected Inputs: Brief description of the system/service, its goals, and architectural context.
- Constraints: Avoid technical implementation details; focus on high-level context.
- Prohibited: Procedural language, details unrelated to the system/service, IaC configuration specifics.

## Scope
- Intent: Define the boundaries and extent of the infrastructure covered for the specific system/service.
- Expected Inputs: List of included/excluded systems, environments, and interfaces.
- Constraints: Be explicit about what is not covered.
- Prohibited: Implicit assumptions, ambiguous scope statements, IaC configuration specifics.

## Architecture Diagram
- Intent: Provide a visual representation of the infrastructure architecture for the specific system/service.
- Expected Inputs: Diagram illustrating major components, connections, and flows.
- Constraints: Use canonical architecture notation; ensure clarity and completeness.
- Prohibited: Unlabeled diagrams, proprietary symbols, IaC configuration specifics.

## Logical Components
- Intent: Describe the logical building blocks of the infrastructure for the specific system/service.
- Expected Inputs: List and brief description of logical components (e.g., compute, storage, network).
- Constraints: Maintain abstraction; avoid implementation specifics.
- Prohibited: Vendor-specific features unrelated to the system/service, IaC configuration specifics.

## Physical Components
- Intent: Detail the physical or deployed elements of the infrastructure for the specific system/service, including relevant Azure services.
- Expected Inputs: Inventory of physical resources, deployment locations, environment details.
- Constraints: Use generic terms; avoid proprietary resource IDs or confidential deployment details.
- Prohibited: Proprietary resource IDs, confidential deployment details, IaC configuration specifics.

## Data Flow
- Intent: Explain how data moves through the infrastructure for the specific system/service.
- Expected Inputs: Description of data sources, sinks, and flow paths.
- Constraints: Use canonical terminology; ensure flows are traceable and reviewable.
- Prohibited: Undocumented flows, IaC configuration specifics.

## Security and Compliance
- Intent: Summarize security controls and compliance requirements for the specific system/service.
- Expected Inputs: List of security mechanisms, compliance standards, and risk mitigations.
- Constraints: Reference architectural standards; avoid implementation details and IaC configuration specifics.
- Prohibited: Confidential compliance data, IaC configuration specifics.

## Operations and Monitoring
- Intent: Describe operational processes and monitoring strategies for the specific system/service.
- Expected Inputs: Overview of operational roles, monitoring tools, and alerting mechanisms.
- Constraints: Use generic descriptions; ensure reviewability.
- Prohibited: Proprietary operational procedures, IaC configuration specifics.

## Non-Goals and Guardrails
- Intent: Clarify what is intentionally excluded and define architectural guardrails for the specific system/service.
- Expected Inputs: List of non-goals, constraints, and boundaries.
- Constraints: Be explicit and concise; avoid ambiguity.
- Prohibited: Implicit exclusions, vague guardrails, IaC configuration specifics.

## References
- Intent: Provide supporting documentation and authoritative sources for the specific system/service.
- Expected Inputs: List of relevant documents, standards, and references.
- Constraints: Use stable, accessible sources; avoid ephemeral links and IaC configuration specifics.
- Prohibited: Unverified or confidential references, IaC configuration specifics.
