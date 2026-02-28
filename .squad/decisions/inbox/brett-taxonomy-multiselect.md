# CFP Taxonomy & Multi-Select Category/Topic Fields

**Date:** 2026-02-28  
**Author:** Brett (Requirements Analyst)  
**Requested by:** Chad Green  
**Status:** Merged into requirements v3.2  

---

## Summary

Requirements v3.2 introduces the full authoritative taxonomy for Event Category (Primary Domains) and Event Topics (Secondary Tags). Both fields are multi-select, with at least 1 Primary Domain required and 0+ Secondary Tags optional. Filters work against multi-value sets.

---

## Authoritative Taxonomy

### Primary Domains (Event Category — Multi-Select, 1+ Required)

Seeded from this list; admin-extensible (not free-text):

1. **Software Development & Engineering** — General programming, languages, frameworks, tooling, architecture, testing, DevOps
2. **Cloud & Infrastructure** — Cloud platforms, distributed systems, networking, SRE, observability, infrastructure automation
3. **Data, AI & Machine Learning** — Data engineering, analytics, ML/AI, LLMs, MLOps, data science
4. **Security & Privacy** — Application security, cloud security, governance, compliance, identity, threat detection
5. **Web, Mobile & Frontend** — Web technologies, frontend frameworks, UX/UI, mobile development
6. **DevOps, Platform Engineering & Automation** — CI/CD, platform teams, IaC, GitOps, automation, reliability
7. **Enterprise & Architecture** — Software architecture, system design, integration, enterprise platforms, modernization
8. **Open Source & Community** — OSS ecosystems, maintainership, community governance, tooling
9. **Product, Design & Innovation** — Product management, design systems, research, innovation practices
10. **Specialized Domains** — Niche or vertical-specific tech (e.g., fintech, health tech, IoT, robotics, gaming)

### Secondary Tags (Event Topics — Multi-Select, 0+ Optional)

Seeded from these tag groups; admin-extensible (not free-text):

- **Programming Languages** — .NET, Java, JavaScript/TypeScript, Python, Go, Rust, C++, etc.
- **Frameworks & Ecosystems** — React, Angular, Vue, ASP.NET Core, Spring, Django, Node.js, etc.
- **Cloud Providers** — Azure, AWS, GCP, multi-cloud, hybrid cloud
- **AI/ML Focus Areas** — LLMs, generative AI, MLOps, applied ML, AI ethics
- **Architecture Styles** — Event-driven, microservices, serverless, monolith modernization, domain-driven design
- **Infrastructure Practices** — IaC, Terraform, Kubernetes, containers, networking, observability
- **Security Topics** — AppSec, cloud security, identity, zero trust, red/blue/purple team
- **Data Topics** — Data engineering, warehousing, analytics, BI, streaming, databases
- **Developer Experience** — Tooling, productivity, documentation, testing, automation
- **Community & Career** — Speaking, leadership, mentoring, DEI, community building

---

## Multi-Select Field Behavior

### Event Category (Primary Domain)
- **Multi-select:** Organizers can select 1 or more categories
- **Required:** At least 1 category must be selected to submit
- **Use case:** A conference on Cloud + Security selects both "Cloud & Infrastructure" AND "Security & Privacy"
- **On listing:** All selected categories appear and are filterable

### Event Topics (Secondary Tags)
- **Multi-select:** Organizers can select 0 or more tags
- **Optional:** No tags required; no maximum limit — select all that apply
- **On listing:** All selected topics appear and are filterable

---

## Filter Behavior

**Multi-value set membership:**
- When a speaker filters by a Primary Domain or Secondary Tag, any CFP that includes that category/tag in its multi-value set is returned
- A CFP with multiple categories will appear in results for **any** of its selected categories (OR logic)
- Example: A CFP tagged with ["Cloud & Infrastructure", "Security & Privacy"] appears in results when filtering by Cloud OR Security

---

## Impact by Team

| Team | Impact |
|------|--------|
| **Ripley (Backend)** | Many-to-many relationships for categories and topics; seeded taxonomy data in migration; filter queries handle multi-value set membership (OR logic) |
| **Lambert (Frontend)** | Multi-select UI controls for both fields; validation enforces at least 1 category; filter UI supports multi-select with OR logic |
| **Kane (Tester)** | Test multi-select validation; test filter behavior with CFPs having multiple categories/topics; verify at least 1 category required, topics optional |
| **Dallas (Lead)** | Taxonomy is locked for MVP; admin extension mechanism can be deferred to post-MVP |

---

## Traceability

- **Feature 2.1 (Organizer Submission Form):** Categorization section replaced with full taxonomy; field descriptions updated to multi-select
- **Story 2.1.1 (Submit a New CFP):** ACs added for multi-select category/topic behavior and validation
- **Feature 1.1 (Public CFP Listing):** Description updated to note multi-value filtering
- **Feature 1.2 (Filtering & Sorting):** Description updated to note multi-value set behavior
- **Story 1.2.1 (Filter by Topic):** AC added for multi-value set membership filter logic

---
