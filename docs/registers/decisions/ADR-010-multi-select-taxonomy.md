---
title: "ADR-010: Multi-Select Taxonomy with Junction Tables"
description: Many-to-many junction tables are used to model CFP categories and topics, enabling accurate multi-domain tagging and OR-logic filter queries via EF Core.
tags:
  - adr
  - architecture-decision-record
  - entity-framework-core
  - sql
status: accepted
---

# Multi-Select Taxonomy with Junction Tables

- **Status:** Accepted
- **Date:** 2026-02-28
- **Work Item:** [*arch-010* — CFP taxonomy data model selection]

## Context and Problem

CFP listings must be tagged with domain categories (Primary Domains, e.g., "Cloud & Infrastructure", "Security & Privacy") and topic tags (Secondary Tags, e.g., "Azure", "Terraform", ".NET") to enable speakers to filter and discover relevant CFPs. The original data model used a single foreign key (`CategoryId`) on the `Cfp` entity, limiting each CFP to exactly one category. Real-world CFPs frequently span multiple domains (e.g., a cloud security conference spans both "Cloud & Infrastructure" and "Security & Privacy") and apply to multiple technology tags. A data model that accurately represents multi-category, multi-topic CFPs is required.

## Decision Drivers

- A single CFP must be accurately representable across multiple domains and multiple topics
- Filter queries must return a CFP when a speaker filters by any of its selected categories or topics (OR logic)
- EF Core must support the many-to-many model cleanly without significant query complexity
- The seeded taxonomy must be admin-extensible without a code deployment
- Submission form must accommodate multi-select for both fields
- At least one category must be required; topics are optional

## Considered Options

- Many-to-many via junction tables (`CfpListingCategory`, `CfpTopic`)
- Single `CategoryId` FK on `Cfp` (one category per CFP)
- Comma-delimited string column for categories and topics

## Decision Outcome

Chosen option: **Many-to-many via junction tables (`CfpListingCategory` and `CfpTopic`)**, because it accurately models the multi-domain, multi-topic nature of real CFPs, enables OR-logic multi-value filter queries without data denormalisation, and is natively supported by EF Core 10's many-to-many relationship configuration. The seeded taxonomy (10 Primary Domains, 10 Secondary Tag groups) provides immediate filtering value and is admin-extensible via a simple admin UI.

#### Consequences

- Good, because CFPs can be accurately tagged across multiple domains and topics — reflects real-world conference scope.
- Good, because OR-logic filter queries use standard `EXISTS` / `JOIN` against junction tables — well-supported by EF Core.
- Good, because EF Core 10 natively configures many-to-many relationships without explicit junction entity classes (unless custom payload data is needed).
- Good, because seeded taxonomy (10 Primary Domains, 10 Secondary Tag groups) provides immediate browsing value.
- Good, because admin-extensible — new categories and topics are added via admin UI without a code deployment.
- Bad, because filter queries are slightly more complex than a simple equality check on a single FK — mitigated by the EF Core Specification pattern encapsulating query logic.
- Bad, because multi-select UI on the submission form adds complexity for Lambert compared to a single dropdown — acceptable given the requirement.

#### Implementation

1. Ripley removes the `CategoryId` FK from the `Cfp` entity.
2. Ripley adds the following to the EF Core schema:
   - `Category` entity: `Id` (int), `Name` (string), `Slug` (string), `IsActive` (bool)
   - `Topic` entity: `Id` (int), `Name` (string), `GroupName` (string), `Slug` (string), `IsActive` (bool)
   - `CfpListingCategory` junction: `CfpId` (FK → `Cfp`), `CategoryId` (FK → `Category`) — composite PK
   - `CfpTopic` junction: `CfpId` (FK → `Cfp`), `TopicId` (FK → `Topic`) — composite PK
3. EF Core `OnModelCreating` configures the many-to-many relationships:
   ```csharp
   modelBuilder.Entity<Cfp>()
       .HasMany(c => c.Categories)
       .WithMany(cat => cat.Cfps)
       .UsingEntity<CfpListingCategory>();

   modelBuilder.Entity<Cfp>()
       .HasMany(c => c.Topics)
       .WithMany(t => t.Cfps)
       .UsingEntity<CfpTopic>();
   ```
4. A seeding migration inserts all 10 Primary Domains and all 10 Secondary Tag groups (and their tags) into `Category` and `Topic` tables.
5. Ripley implements filter query using the Specification pattern:
   ```csharp
   // OR logic: CFP matches if ANY of its categories match the filter
   query = query.Where(c => c.Categories.Any(cat => categoryIds.Contains(cat.Id)));
   ```
6. Lambert implements multi-select UI controls for both fields on the CFP submission form. At least one `Category` selection is required (client and server validation). `Topic` selections are optional.
7. API filter endpoint `GET /api/v1/cfps?categories=1,3&topics=5` returns CFPs matching any of the specified categories AND any of the specified topics.

#### Confirmation

- A CFP with multiple categories appears in filter results for each of its categories independently.
- A CFP with zero topics selected appears in results when no topic filter is applied (topics are optional).
- Submission form validation rejects a CFP with no category selected.
- Admin UI can add a new `Category` and it immediately appears in the submission form.
- EF Core `EXPLAIN` on filter queries confirms index usage on junction table FKs.

#### Stakeholders

- **Dallas (Lead & Architect):** Decision owner; defined taxonomy model and filter requirements
- **Ripley (Backend):** Removes `CategoryId` FK; implements junction tables, EF Core configuration, seeding migration, and filter queries
- **Lambert (Frontend):** Implements multi-select UI for categories and topics; enforces at least-one-category validation
- **Kane (Tester):** Tests multi-select validation, filter query behaviour with multiple categories/topics, and admin extensibility

## Pros and Cons of the Options

### Many-to-Many via Junction Tables

- Good, because accurately models multi-domain, multi-topic CFPs.
- Good, because OR-logic filter queries are standard SQL `EXISTS`/`JOIN` — performant with FK indexes.
- Good, because EF Core 10 many-to-many is clean and well-supported.
- Good, because taxonomy is admin-extensible — new categories/topics added without code deployment.
- Good, because referential integrity enforced — orphaned junction records impossible with FK constraints.
- Neutral, because filter queries are slightly more complex than single-FK equality — encapsulated by Specification pattern.
- Bad, because multi-select submission form is more complex than a single dropdown — acceptable given the requirement.

### Single `CategoryId` FK on Cfp (One Category per CFP)

- Good, because simplest data model — single FK, single dropdown on form.
- Good, because trivial filter query — `WHERE CategoryId = ?`.
- Bad, because inaccurate — real CFPs span multiple domains; single category misrepresents the conference scope.
- Bad, because speakers filtering by "Security & Privacy" miss a cloud-security conference tagged as "Cloud & Infrastructure".
- Bad, because requires a code change to the data model when multi-select becomes needed (technical debt from day one).

### Comma-Delimited String Column

- Good, because no schema changes — simple text column.
- Good, because easy to display.
- Bad, because no referential integrity — typos, inconsistent casing, and deleted values leave orphaned strings.
- Bad, because filter queries require `LIKE '%value%'` — not index-friendly, slow at scale.
- Bad, because EF Core cannot model relationships against a string column — no navigation properties.
- Bad, because admin extensibility requires string matching instead of ID lookups.

## More Information

The seeded taxonomy is:

**Primary Domains (10):**
1. Software Development & Engineering
2. Cloud & Infrastructure
3. Data, AI & Machine Learning
4. Security & Privacy
5. Web, Mobile & Frontend
6. DevOps, Platform Engineering & Automation
7. Enterprise & Architecture
8. Open Source & Community
9. Product, Design & Innovation
10. Specialized Domains

**Secondary Tag groups (10):** Programming Languages, Frameworks & Ecosystems, Cloud Providers, AI/ML Focus Areas, Architecture Styles, Infrastructure Practices, Security Topics, Data Topics, Developer Experience, Community & Career.

Filter behaviour: OR logic within each field (any matching category qualifies), AND logic between fields (if both `categories` and `topics` filters are specified, a CFP must match at least one from each).

## Follow-On Information

Post-MVP: consider adding a `TopicGroup` entity to allow admins to manage tag group structure without code changes. For MVP, the group name is a string property on `Topic`.

## Record History

* **Proposed**: 2026-02-28
* **Accepted**: 2026-02-28
* **Last Reviewed**: 2026-02-28
