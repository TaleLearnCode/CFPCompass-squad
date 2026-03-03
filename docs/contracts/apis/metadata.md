---
title: Metadata API Contract
description: Governed interface for retrieving reference data — topics, categories, countries, subdivisions, and world regions — used to classify and filter CFP listings.
tags:
  - api-contract
  - architecture
  - metadata
  - reference-data
  - governance
---

# Metadata API Contract

## Purpose and Scope

This contract defines the governed interface for all reference-data endpoints exposed under `/v1/` via Azure API Management. Metadata endpoints provide the taxonomy and geographic lookup data that consumers use to populate filters, submission forms, and CFP classification UIs.

Covered endpoints:

- `GET /v1/topics` — all Secondary Tag topics grouped by category
- `GET /v1/categories` — all Primary Domain categories
- `GET /v1/countries` — ISO 3166-1 alpha-2 country list
- `GET /v1/countries/{code}/subdivisions` — ISO 3166-2 subdivisions for a given country
- `GET /v1/regions` — UN M.49 world regions

These endpoints are read-only and serve exclusively pre-seeded or admin-maintained reference data. They are heavily cached at the APIM response cache and in-memory cache layers. They are consumed by the web application's submission form and filter panel, as well as by third-party API consumers building integrations.

Out of scope: creating or modifying taxonomy data (admin-only operations handled via admin UI), and the CFP listing or submission endpoints (see `cfps.md` and `submissions.md`).

---

## API Responsibilities

- Return the full list of Primary Domain categories (10 seeded domains, admin-extensible).
- Return the full list of Secondary Tag topics grouped by their parent tag group (10 groups, ~100+ tags, admin-extensible).
- Return a complete list of countries per ISO 3166-1 alpha-2, each annotated with its UN M.49 world region assignment.
- Return the list of ISO 3166-2 subdivisions (states, provinces, regions) for a specified country code.
- Return the canonical list of UN M.49 world regions used for geographic filtering.
- Serve all responses from the APIM response cache or the API's in-memory reference cache to minimize Azure SQL load.
- Enforce the standard APIM read rate limit (100 req/min per subscription key).

The API does **not** allow creation, modification, or deletion of reference data through these endpoints. Administrative taxonomy management is handled exclusively through the admin UI.

---

## Request Model

### `GET /v1/topics` — Query Parameters

No required parameters.

| Parameter | Type   | Required | Description |
|-----------|--------|:--------:|-------------|
| `group`   | string | No       | Filter by topic group name. Returns only topics belonging to that group. |

### `GET /v1/categories` — Query Parameters

No parameters.

### `GET /v1/countries` — Query Parameters

No required parameters.

| Parameter | Type   | Required | Description |
|-----------|--------|:--------:|-------------|
| `region`  | string | No       | Filter by UN M.49 world region code. Returns only countries in that region. |

### `GET /v1/countries/{code}/subdivisions` — Path Parameters

| Parameter | Type   | Required | Description |
|-----------|--------|:--------:|-------------|
| `code`    | string | ✔️       | ISO 3166-1 alpha-2 country code (e.g., `US`, `GB`, `DE`). Case-insensitive; normalized to uppercase. |

### `GET /v1/regions` — Query Parameters

No parameters.

---

## Field Semantics and Constraints

- **Category**: A Primary Domain classification for CFP listings. Categories are the top-level taxonomy used for broad classification (e.g., "Cloud & Infrastructure", "Security & Privacy"). A CFP may have 1–5 categories.
- **Topic**: A Secondary Tag for fine-grained classification within a category group (e.g., "Azure" within "Cloud Platforms" group). A CFP may have 1–10 topics. Topics are grouped; the group name aligns to — but does not strictly mirror — categories, as a topic can be relevant across multiple categories.
- **Country**: Identified by ISO 3166-1 alpha-2 code. Each country record includes a `worldRegion` field (UN M.49) assigned via the `WorldRegionAssignmentJob` or seeded from the database migration.
- **Subdivision**: Identified by ISO 3166-2 code (e.g., `US-TX` for Texas). Each subdivision belongs to exactly one country. Not all countries have subdivisions exposed — only those commonly used for event location filtering.
- **Region**: UN M.49 region codes (e.g., `021` for Northern America, `150` for Europe). Used for cross-country filtering on the CFP listing page.

---

## Naming and Validation Rules

- Country codes are accepted case-insensitively and normalized to uppercase before lookup.
- Topic group names in query parameters are matched case-insensitively.
- All response identifiers (`id` fields) are UUIDs for taxonomy items and ISO/UN codes for geographic items.
- Field names in all responses use `camelCase`.

---

## Request Validation and Governance Rules

- The APIM subscription key is validated by APIM. Missing or invalid keys return `401 Unauthorized`.
- A `GET /v1/countries/{code}/subdivisions` request with an unrecognized ISO country code returns `404 Not Found`.
- A `GET /v1/topics?group=` request with an unrecognized group name returns an empty `items` array (not an error), to allow forward-compatible clients to handle taxonomy additions gracefully.
- All endpoints are read-only. Any attempt to use non-GET HTTP methods returns `405 Method Not Allowed`.
- Reference data is loaded from the API's in-memory `IMemoryCache` (refreshed every 24 hours); cache misses hit Azure SQL and refresh the cache entry.

---

## Execution Semantics

1. APIM validates the subscription key.
2. APIM checks its response cache for the request signature. On hit, the cached response is returned without forwarding to the backend.
3. On miss, APIM forwards to the `CfpCompass.Api` backend.
4. The backend checks its in-memory reference cache (`IMemoryCache`). On hit, serves from memory. On miss, queries Azure SQL and populates the cache.
5. APIM caches the response per the configured TTL for the next requests.

Reference data is not subject to the event-driven async write pattern. Administrative mutations go through the admin UI, which writes directly to Azure SQL and emits a cache refresh signal (clearing both Redis and APIM cache for the affected endpoint).

---

## Response Model

### `GET /v1/categories` — Success Response (`200 OK`)

```json
{
  "items": [
    { "id": "a1b2c3d4-...", "name": "Cloud & Infrastructure", "sortOrder": 1 },
    { "id": "b2c3d4e5-...", "name": "Security & Privacy", "sortOrder": 2 },
    { "id": "c3d4e5f6-...", "name": "AI & Machine Learning", "sortOrder": 3 },
    { "id": "d4e5f6a7-...", "name": "Web & Mobile Development", "sortOrder": 4 },
    { "id": "e5f6a7b8-...", "name": "Data & Analytics", "sortOrder": 5 },
    { "id": "f6a7b8c9-...", "name": "DevOps & Platform Engineering", "sortOrder": 6 },
    { "id": "a7b8c9d0-...", "name": "Architecture & Design Patterns", "sortOrder": 7 },
    { "id": "b8c9d0e1-...", "name": "Leadership & Career", "sortOrder": 8 },
    { "id": "c9d0e1f2-...", "name": "Open Source & Community", "sortOrder": 9 },
    { "id": "d0e1f2a3-...", "name": "Emerging Technologies", "sortOrder": 10 }
  ],
  "count": 10
}
```

### `GET /v1/topics` — Success Response (`200 OK`)

```json
{
  "groups": [
    {
      "name": "Cloud Platforms",
      "topics": [
        { "id": "...", "name": "Azure", "sortOrder": 1 },
        { "id": "...", "name": "AWS", "sortOrder": 2 },
        { "id": "...", "name": "Google Cloud", "sortOrder": 3 }
      ]
    },
    {
      "name": "Security",
      "topics": [
        { "id": "...", "name": "AppSec", "sortOrder": 1 },
        { "id": "...", "name": "Zero Trust", "sortOrder": 2 }
      ]
    }
  ],
  "totalTopics": 104
}
```

### `GET /v1/countries` — Success Response (`200 OK`)

```json
{
  "items": [
    {
      "code": "US",
      "name": "United States",
      "worldRegion": { "code": "021", "name": "Northern America" }
    },
    {
      "code": "GB",
      "name": "United Kingdom",
      "worldRegion": { "code": "154", "name": "Northern Europe" }
    }
  ],
  "count": 249
}
```

### `GET /v1/countries/{code}/subdivisions` — Success Response (`200 OK`)

```json
{
  "countryCode": "US",
  "countryName": "United States",
  "items": [
    { "code": "US-AL", "name": "Alabama" },
    { "code": "US-AK", "name": "Alaska" },
    { "code": "US-TX", "name": "Texas" }
  ],
  "count": 56
}
```

### `GET /v1/regions` — Success Response (`200 OK`)

```json
{
  "items": [
    { "code": "002", "name": "Africa" },
    { "code": "019", "name": "Americas" },
    { "code": "142", "name": "Asia" },
    { "code": "150", "name": "Europe" },
    { "code": "009", "name": "Oceania" },
    { "code": "021", "name": "Northern America" },
    { "code": "419", "name": "Latin America and the Caribbean" }
  ],
  "count": 7
}
```

### Error Response

```json
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.5.5",
  "title": "Not Found",
  "status": 404,
  "detail": "Country code 'XX' is not a recognized ISO 3166-1 alpha-2 code.",
  "traceId": "00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01"
}
```

---

## Status and Observability

Metadata endpoints do not follow the async write pattern. All responses are synchronous. No polling or status endpoints are required.

Cache state is observable via structured logs in Azure Log Analytics. The API logs cache hits and misses for reference data endpoints at `Debug` severity. A manual cache refresh endpoint (`POST /v1/admin/cache/refresh`) is available to admins when taxonomy data is updated and the TTL-based invalidation window is unacceptable.

---

## Error Handling

| HTTP Status | Condition |
|-------------|-----------|
| `401 Unauthorized` | Missing or invalid APIM subscription key. |
| `404 Not Found` | Requested country code is not recognized. |
| `405 Method Not Allowed` | Non-GET method attempted on a read-only metadata endpoint. |
| `429 Too Many Requests` | Rate limit exceeded (100 req/min). `Retry-After` header included. |
| `500 Internal Server Error` | Unhandled exception. Correlation ID in response. |
| `503 Service Unavailable` | Backend health check failing. |

---

## Security and Access Control

### Authentication

All metadata endpoints require an APIM subscription key in the `Ocp-Apim-Subscription-Key` header. Both `cfp-compass-read` and `cfp-compass-readwrite` products have access.

### Authorization

Metadata endpoints are read-only and accessible to all subscription tiers. No write product is required. No user-level authentication is required for these endpoints.

### Consumer Identity Trust Model

APIM subscription keys are the access boundary. Metadata endpoints expose no user-specific data and contain no PII. Cache responses may be safely shared across all consumers of the same subscription tier.

---

## Relationship to Other Artifacts

| Artifact | Relationship |
|----------|-------------|
| `docs/api/openapi/cfp-compass-api-v1.yaml` | OpenAPI 3.1 spec containing schema definitions for all metadata response types. |
| `docs/contracts/apis/cfps.md` | Consumers of this metadata use `categoryIds`, `topicIds`, `countryCode`, `subdivisionCode`, and region values when filtering and submitting CFPs. |
| `docs/contracts/apis/submissions.md` | Submission form populates dropdowns from these endpoints. |
| Architecture §3 (Caching Strategy) | In-memory cache and Redis cache for reference data; 24h TTL. |
| Architecture §4 (API Design) | APIM response caching TTLs for metadata endpoints. |

---

## Notes and Comments

- The taxonomy (categories and topics) is seeded in the EF Core database migration via `HasData()`. The seeded values are the canonical starting point. Admin-added categories and topics appear immediately in responses after the next cache refresh.
- Countries and subdivisions are seeded from ISO 3166 data. The `WorldRegionAssignmentJob` runs every 6 hours to assign UN M.49 world region codes to any country record where the region is null (covering new entries added after initial seeding).
- The subdivision endpoint is intentionally per-country (not a global list) to keep response sizes manageable and align with the cascading picker UI pattern in the submission form.
- Regions returned by `GET /v1/regions` reflect only the UN M.49 regions actually represented in the seeded country data — not the complete UN M.49 hierarchy.

---

## References

- Architecture §3 — Data Architecture (taxonomy seeding, caching strategy)
- Architecture §4 — API Design (APIM products, response caching TTLs)
- Architecture §11 — API & Event Contract Design (spec-first requirement)
- ADR-014 — Contract-first API and event design
- ISO 3166-1 — Country codes
- ISO 3166-2 — Country subdivision codes
- UN M.49 — Standard country or area codes for statistical use
