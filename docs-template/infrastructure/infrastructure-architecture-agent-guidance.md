# Infrastructure Architecture Document Agent Guidance

## General Principles
- Use the template and instructions as the sole source of structure and section intent.
- Generate content specific to the system/service being documented.
- Include relevant architectural implementation details (e.g., Azure services, resource types, deployment locations), but do not include IaC configuration specifics (such as parameter values, scripts, or code).
- Defer to human architects when uncertainty, incomplete inputs, or ambiguous requirements arise.

## Section Reasoning and Recall
- Overview: Recall-based. Use provided context for the specific system/service; do not infer intent beyond explicit description.
- Scope: Recall-based. Require explicit boundaries for the system/service; prompt for clarification if scope is ambiguous.
- Architecture Diagram: Recall-based. Use provided diagrams for the system/service; do not infer missing elements. Request clarification if diagram is incomplete.
- Logical Components: Reasoning-based. Infer logical groupings from context, but defer if component boundaries are unclear. Tailor to the system/service.
- Physical Components: Recall-based. Use explicit inventory for the system/service, including Azure services as appropriate; do not infer deployment details. Request clarification for missing information.
- Data Flow: Reasoning-based. Infer data movement from context, but defer if flows are ambiguous or undocumented. Tailor to the system/service.
- Security and Compliance: Recall-based. Use explicit controls and standards for the system/service; do not infer security mechanisms. Defer to architect for unclear requirements.
- Operations and Monitoring: Reasoning-based. Infer operational roles and monitoring strategies from context, but defer if processes are undefined. Tailor to the system/service.
- Non-Goals and Guardrails: Recall-based. Require explicit exclusions and guardrails for the system/service; prompt for clarification if ambiguous.
- References: Recall-based. Use only provided, stable references for the system/service; do not infer or generate new sources.

## Handling Uncertainty and Incomplete Inputs
- When section inputs are missing or unclear, prompt for clarification or defer to human architect.
- Do not make assumptions about proprietary features, confidential information, or IaC configuration specifics.
- Document any uncertainties or open questions for review.

## Deferral and Review
- Defer decisions to human architects when boundaries, requirements, or constraints are ambiguous.
- Ensure all agent-generated content is reviewable section-by-section.
- Clearly mark sections requiring human input or approval.

## Compatibility
- Guidance is designed for use with GitHub Copilot in Visual Studio Code and Visual Studio 2026.
- Derived from the template and instructions; do not encode independent logic.
- Ensure agent output aligns with architectural vocabulary and review standards.
