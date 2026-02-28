# CFP Compass — System Architecture

**Version:** v1.0  
**Author:** Dallas (Lead & Architect)  
**Date:** 2026-02-28  
**Status:** Draft — pending Chad Green review on open questions

---

## 1. Solution Overview

CFP Compass is a .NET 10, Azure-hosted web application that aggregates open Calls for Papers (CFPs) for community speakers. Organizers submit CFPs through a public form; admins moderate submissions before publication. Authenticated speakers track CFPs through a 3-state workflow (Interested → Submitted → Accepted), receive deadline reminders and weekly digests via email, and browse a historical archive of past CFPs. A public REST API enables third-party integrations. The system enforces international standards (ISO 3166, IANA Time Zones, UN M.49) and supports an organizer claim flow for community-contributed listings.

### High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Azure Front Door (CDN)                       │
└───────────────┬─────────────────────────────────┬───────────────────┘
                │                                 │
                ▼                                 ▼
┌───────────────────────┐         ┌───────────────────────────────┐
│   Azure Container App │         │   Azure API Management (APIM) │
│   ── Web App ──       │         │   ── /api/v1/* ──             │
│   Blazor Server (SSR) │         │   Rate limiting, API keys,    │
│   + MVC Controllers   │         │   developer portal            │
└───────────┬───────────┘         └──────────────┬────────────────┘
            │                                    │
            ▼                                    ▼
┌──────────────────────────────────────────────────────────────────┐
│                    Azure Container App                            │
│                    ── API Host ──                                 │
│     ASP.NET Core Web API (.NET 10)                               │
│     Controllers, Services, Domain Logic                          │
└────┬──────────┬──────────┬──────────┬──────────┬────────────────┘
     │          │          │          │          │
     ▼          ▼          ▼          ▼          ▼
┌─────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌──────────────────┐
│Azure SQL│ │Azure   │ │Azure   │ │Azure   │ │Azure Container   │
│Database │ │Blob    │ │Key     │ │Comm.   │ │Apps Jobs         │
│         │ │Storage │ │Vault   │ │Services│ │(Background Work) │
└─────────┘ └────────┘ └────────┘ └────────┘ └──────────────────┘
```

### Deployment Topology

| Component | Azure Service | Purpose |
|-----------|--------------|---------|
| Web Frontend | Azure Container Apps (Container App #1) | Blazor Server app serving UI |
| API Backend | Azure Container Apps (Container App #2) | ASP.NET Core Web API |
| Background Workers | Azure Container Apps Jobs | Scheduled jobs: digest, reminders, expiry, region assignment |
| Database | Azure SQL Database (Serverless, S0) | Primary relational data store |
| Blob Storage | Azure Storage Account (GPv2) | Event logos, file uploads |
| Cache | Azure Cache for Redis (Basic C0) | Response caching, session state |
| API Gateway | Azure API Management (Consumption tier) | Rate limiting, API key management, developer portal |
| CDN | Azure Front Door (Standard) | Static asset caching, SSL termination, global edge |
| Email | Azure Communication Services | Transactional and digest emails |
| Secrets | Azure Key Vault | Connection strings, API keys, ACS credentials |
| Container Registry | Azure Container Registry (Basic) | Docker image storage |
| Identity | ASP.NET Core Identity + external OAuth providers | User auth, passkeys, social login |

---

## 2. Solution Structure

### .NET Solution Layout

```
CFPCompass.sln
│
├── src/
│   ├── CFPCompass.Domain/                  # Class Library
│   │   ├── Entities/                       # Domain entities (Cfp, User, ApiKey, etc.)
│   │   ├── Enums/                          # Status enums, EventType, Format, etc.
│   │   ├── ValueObjects/                   # Country, Subdivision, TimeZone, WorldRegion
│   │   └── Events/                         # Domain events (CfpApproved, ClaimRequested, etc.)
│   │
│   ├── CFPCompass.Application/             # Class Library
│   │   ├── Interfaces/                     # Service contracts (ICfpService, IEmailService, etc.)
│   │   ├── Services/                       # Application service implementations
│   │   ├── DTOs/                           # Data transfer objects (request/response models)
│   │   ├── Validators/                     # FluentValidation validators
│   │   ├── Mapping/                        # AutoMapper profiles
│   │   └── Standards/                      # ISO 3166, IANA TZ, UN M.49 lookup services
│   │
│   ├── CFPCompass.Infrastructure/          # Class Library
│   │   ├── Data/                           # EF Core DbContext, configurations, migrations
│   │   ├── Repositories/                   # Repository implementations
│   │   ├── Email/                          # ACS email integration
│   │   ├── Storage/                        # Azure Blob Storage client
│   │   ├── Identity/                       # Identity configuration, passkey stores
│   │   └── Caching/                        # Redis cache service implementations
│   │
│   ├── CFPCompass.Api/                     # ASP.NET Core Web API (Container App #2)
│   │   ├── Controllers/                    # API controllers under /api/v1/
│   │   ├── Middleware/                     # Error handling, request logging
│   │   ├── Filters/                        # Auth filters, model validation
│   │   └── Program.cs                      # API host startup
│   │
│   ├── CFPCompass.Web/                     # Blazor Server App (Container App #1)
│   │   ├── Components/                     # Razor/Blazor components
│   │   │   ├── Pages/                      # Routable page components
│   │   │   ├── Shared/                     # Layout, nav, shared components
│   │   │   └── Admin/                      # Admin-only components
│   │   ├── Resources/                      # .resx localization files
│   │   ├── wwwroot/                        # Static assets (CSS, JS, images)
│   │   └── Program.cs                      # Web host startup
│   │
│   └── CFPCompass.Workers/                 # Worker Service (Container Apps Jobs)
│       ├── Jobs/                           # Individual job implementations
│       │   ├── CfpExpiryJob.cs
│       │   ├── DeadlineReminderJob.cs
│       │   ├── WeeklyDigestJob.cs
│       │   ├── WorldRegionAssignmentJob.cs
│       │   └── DuplicateDetectionJob.cs
│       └── Program.cs                      # Worker host startup
│
├── tests/
│   ├── CFPCompass.Domain.Tests/            # xUnit — domain logic
│   ├── CFPCompass.Application.Tests/       # xUnit — service layer, validators
│   ├── CFPCompass.Infrastructure.Tests/    # xUnit — repository, EF Core integration
│   ├── CFPCompass.Api.Tests/               # xUnit — API integration (WebApplicationFactory)
│   ├── CFPCompass.Web.Tests/               # xUnit + bUnit — Blazor component tests
│   └── CFPCompass.E2E.Tests/               # Playwright — end-to-end browser tests
│
├── infra/
│   ├── modules/                            # Terraform modules
│   │   ├── container-apps/
│   │   ├── sql/
│   │   ├── storage/
│   │   ├── redis/
│   │   ├── apim/
│   │   ├── keyvault/
│   │   ├── acr/
│   │   ├── acs/
│   │   └── frontdoor/
│   ├── environments/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
└── .github/
    └── workflows/
        ├── ci.yml                          # Build + test on PR
        ├── cd-dev.yml                      # Deploy to dev
        ├── cd-staging.yml                  # Deploy to staging
        └── cd-prod.yml                     # Deploy to production
```

### Naming Conventions

- **Namespaces:** `CFPCompass.{Layer}.{Feature}` — e.g., `CFPCompass.Application.Services`, `CFPCompass.Infrastructure.Data`
- **Projects:** `CFPCompass.{Layer}` — Domain, Application, Infrastructure, Api, Web, Workers
- **Test projects:** `CFPCompass.{Layer}.Tests`
- **Terraform modules:** lowercase kebab-case — `container-apps`, `key-vault`

### Architecture Pattern

Clean Architecture (Onion) — dependencies point inward:

```
Domain (innermost) → Application → Infrastructure / Api / Web / Workers (outermost)
```

- **Domain** has zero external dependencies (no NuGet packages except standard BCL)
- **Application** depends on Domain; defines interfaces that Infrastructure implements
- **Infrastructure** implements data access, email, storage, caching
- **Api** and **Web** are thin entry points that wire up DI and delegate to Application services
- **Workers** uses the same Application services for background processing

---

## 3. Data Architecture

### Database Choice: Azure SQL Database (Serverless)

**Decision:** Azure SQL Database, Serverless compute tier (General Purpose).

**Justification:**
1. **Relational data model** — CFPs, users, tracking states, moderation workflows are inherently relational with foreign key constraints and transactional integrity requirements
2. **EF Core maturity** — Best tooling support in .NET ecosystem; migrations, LINQ, change tracking
3. **Azure-native** — Fully managed, auto-scaling serverless tier with auto-pause for cost savings in MVP
4. **Familiar** — Team and community contributors will know SQL; reduces onboarding friction
5. **Cost** — Serverless tier auto-pauses when idle (MVP won't have constant load); estimated ~$5-15/month for MVP

**Why not Cosmos DB:** The data is highly relational (CFPs ↔ users ↔ tracking ↔ moderation). Cosmos excels at document/key-value workloads with massive horizontal scale. CFP Compass doesn't need that scale for MVP, and the relational constraints (FK integrity, transactional moderation workflows) favor SQL.

### Key Entities and Relationships

```
┌──────────────┐     ┌──────────────────┐     ┌───────────────┐
│   User       │     │   Cfp            │     │   Category    │
│──────────────│     │──────────────────│     │───────────────│
│ PK: Id       │     │ PK: Id           │     │ PK: Id        │
│ Email        │     │ EventName        │     │ Name          │
│ DisplayName  │     │ Status (enum)    │     └───────┬───────┘
│ IsAdmin      │     │ FK: SubmitterId  │             │
│ ...          │     │ FK: OrganizerId  │     ┌───────┴───────┐
└──────┬───────┘     │ FK: CategoryId   │     │  CfpTopic     │
       │             │ CountryCode      │     │  (join table) │
       │             │ SubdivisionCode  │     │ FK: CfpId     │
       │             │ WorldRegion      │     │ FK: TopicId   │
       │             │ TimeZone         │     └───────────────┘
       │             │ CfpOpenDate      │
       │             │ CfpCloseDate     │     ┌───────────────┐
       │             │ ...30+ fields    │     │   Topic       │
       │             └──────┬───────────┘     │───────────────│
       │                    │                 │ PK: Id        │
       │                    │                 │ Name          │
       ▼                    │                 └───────────────┘
┌──────────────────┐        │
│ UserCfpTracking  │        │         ┌────────────────────┐
│──────────────────│        │         │ ModerationAction   │
│ PK: Id           │        │         │────────────────────│
│ FK: UserId       │◄───────┼─────────│ PK: Id             │
│ FK: CfpId        │        │         │ FK: CfpId          │
│ Status (enum)    │        │         │ FK: AdminUserId    │
│ (Interested/     │        │         │ Action (enum)      │
│  Submitted/      │        │         │ Reason             │
│  Accepted)       │        │         │ CreatedAt          │
└──────────────────┘        │         └────────────────────┘
                            │
┌──────────────────┐        │         ┌────────────────────┐
│ NotificationPref │        │         │ ApiKeyRequest      │
│──────────────────│        │         │────────────────────│
│ PK: Id           │        │         │ PK: Id             │
│ FK: UserId       │        │         │ FK: UserId         │
│ DeadlineReminder │        │         │ ApiKey (hashed)    │
│ WeeklyDigest     │        │         │ Permission (enum)  │
└──────────────────┘        │         │ Status (enum)      │
                            │         │ RateLimit          │
┌──────────────────┐        │         └────────────────────┘
│ ClaimRequest     │        │
│──────────────────│        │         ┌────────────────────┐
│ PK: Id           │◄───────┘         │ Country            │
│ FK: CfpId        │                  │────────────────────│
│ FK: ClaimantId   │                  │ PK: Alpha2Code     │
│ Status (enum)    │                  │ Name               │
│ Token            │                  │ WorldRegion        │
│ CreatedAt        │                  └────────────────────┘
└──────────────────┘
                                      ┌────────────────────┐
┌──────────────────┐                  │ Subdivision        │
│ EmailLog         │                  │────────────────────│
│──────────────────│                  │ PK: Code           │
│ PK: Id           │                  │ FK: CountryCode    │
│ FK: UserId       │                  │ Name               │
│ EmailType (enum) │                  └────────────────────┘
│ SentAt           │
│ Status           │
└──────────────────┘
```

**Key Relationships:**
- `Cfp` → `User` (SubmitterId, OrganizerId — both nullable FKs)
- `Cfp` → `Category` (FK)
- `Cfp` ↔ `Topic` (many-to-many via `CfpTopic`)
- `UserCfpTracking` → `User` + `Cfp` (composite unique on UserId + CfpId)
- `ModerationAction` → `Cfp` + `User` (admin who acted)
- `ClaimRequest` → `Cfp` + `User` (claimant)
- `Country` → `Subdivision` (one-to-many)
- `Country.WorldRegion` stores the UN M.49 region (auto-assigned)

### Data Access: Entity Framework Core

**Decision:** EF Core 10 with code-first migrations.

**Justification:**
1. First-class .NET 10 support; handles Azure SQL natively
2. Code-first migrations provide version-controlled schema evolution
3. LINQ-based querying reduces raw SQL mistakes
4. Change tracking simplifies audit trail implementation
5. Strong community ecosystem (interceptors, query filters, value converters)

**Patterns:**
- **Repository pattern** via thin wrappers over `DbContext` for testability
- **Specification pattern** for complex query composition (e.g., CFP filters)
- **Global query filters** for soft-delete and tenant isolation (e.g., `IsArchived`)
- **Value converters** for enums stored as strings in DB
- **Interceptors** for `CreatedAt` / `UpdatedAt` auto-stamping

### Blob Storage

- **Azure Storage Account (GPv2, LRS)**
- **Container:** `event-logos` — stores uploaded event logo images
- **Naming:** `{cfpId}/{guid}.{ext}` — prevents collisions, enables easy cleanup
- **Access:** SAS tokens generated server-side; images served via CDN for public access
- **Size limits:** 2 MB max per logo; accepted formats: PNG, JPG, WebP
- **Future:** Additional containers for speaker materials if needed

### Caching Strategy

| Layer | Technology | Use Case |
|-------|-----------|----------|
| Distributed cache | Azure Cache for Redis (Basic C0) | API response caching, session state, rate limit counters (app-level fallback) |
| In-memory cache | `IMemoryCache` | Reference data: countries, subdivisions, topics, categories (refreshed every 24h) |
| Output cache | ASP.NET Core Output Caching | Public CFP listing pages (cache-tag invalidation on CFP approval/expiry) |

**Cache invalidation:**
- CFP listing cache is busted when a CFP is approved, rejected, expired, or modified
- Reference data (countries, topics) is cached for 24 hours with manual refresh endpoint for admins
- Redis is used for distributed scenarios; in-memory for single-instance reference data

---

## 4. API Design

### REST API Structure

All public API endpoints are versioned under `/api/v1/` and fronted by Azure API Management.

#### CFP Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/cfps` | API Key (read) | List approved CFPs with filtering/sorting/pagination |
| `GET` | `/api/v1/cfps/{id}` | API Key (read) | Get single approved CFP by ID |
| `POST` | `/api/v1/cfps` | API Key (read-write) | Submit new CFP (enters moderation) |
| `PUT` | `/api/v1/cfps/{id}` | API Key (read-write) | Update existing CFP (re-enters moderation) |
| `GET` | `/api/v1/cfps/archive` | API Key (read) | List archived/past CFPs |
| `GET` | `/api/v1/cfps/{id}/history` | API Key (read) | Get CFP history for an event |

#### Metadata Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/topics` | API Key (read) | List all topics |
| `GET` | `/api/v1/categories` | API Key (read) | List all categories |
| `GET` | `/api/v1/countries` | API Key (read) | List countries (ISO 3166-1) |
| `GET` | `/api/v1/countries/{code}/subdivisions` | API Key (read) | List subdivisions for a country |
| `GET` | `/api/v1/regions` | API Key (read) | List UN M.49 world regions |

#### User/Speaker Endpoints (Web App — not exposed via APIM)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/v1/account/register` | Anonymous | Create speaker account |
| `POST` | `/api/v1/account/login` | Anonymous | Authenticate |
| `POST` | `/api/v1/account/logout` | Authenticated | End session |
| `POST` | `/api/v1/account/forgot-password` | Anonymous | Request password reset |
| `POST` | `/api/v1/account/reset-password` | Anonymous (token) | Reset password via token |
| `GET` | `/api/v1/me/tracking` | Authenticated | Get user's tracked CFPs |
| `POST` | `/api/v1/me/tracking/{cfpId}` | Authenticated | Track a CFP (body: status) |
| `PUT` | `/api/v1/me/tracking/{cfpId}` | Authenticated | Update tracking status |
| `DELETE` | `/api/v1/me/tracking/{cfpId}` | Authenticated | Remove tracking |
| `GET` | `/api/v1/me/preferences` | Authenticated | Get notification preferences |
| `PUT` | `/api/v1/me/preferences` | Authenticated | Update notification preferences |

#### Submission Endpoints (Web App)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/v1/submissions` | Anonymous | Submit a new CFP |
| `GET` | `/api/v1/submissions/{id}` | Token (from email) | Get submission for editing |
| `PUT` | `/api/v1/submissions/{id}` | Token (from email) | Edit pending/rejected submission |
| `POST` | `/api/v1/submissions/{id}/reconsider` | Token (from email) | Request reconsideration |

#### Claim Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/v1/claims/{cfpId}` | Authenticated | Initiate organizer claim |
| `POST` | `/api/v1/claims/{cfpId}/verify` | Token (from email) | Complete claim verification |

#### Admin Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/v1/admin/submissions` | Admin | List pending submissions |
| `POST` | `/api/v1/admin/submissions/{id}/approve` | Admin | Approve a submission |
| `POST` | `/api/v1/admin/submissions/{id}/reject` | Admin | Reject with reason |
| `GET` | `/api/v1/admin/users` | Admin | List users |
| `PUT` | `/api/v1/admin/users/{id}/disable` | Admin | Disable user account |
| `PUT` | `/api/v1/admin/users/{id}/enable` | Admin | Re-enable user account |
| `GET` | `/api/v1/admin/api-requests` | Admin | List pending API key requests |
| `POST` | `/api/v1/admin/api-requests/{id}/approve` | Admin | Approve API key request |
| `POST` | `/api/v1/admin/api-requests/{id}/reject` | Admin | Reject API key request |
| `POST` | `/api/v1/admin/claims/{cfpId}/assign` | Admin | Admin-assisted claim assignment |
| `GET` | `/api/v1/admin/dashboard` | Admin | Dashboard summary metrics |

### Authentication / Authorization Model

| Role | Identity Source | Access Level |
|------|----------------|-------------|
| Anonymous | None | Browse public CFP listing, view details, submit CFP form |
| Authenticated Speaker | ASP.NET Core Identity (cookie/JWT) | Track CFPs, manage preferences, request API access |
| Organizer (verified) | Authenticated + claim verified | Edit owned CFP listings |
| Admin | Authenticated + email in env config list | Full admin dashboard, moderation, user management |
| API Consumer (read) | APIM subscription key | GET endpoints only |
| API Consumer (read-write) | APIM subscription key (write product) | GET + POST + PUT endpoints |

### APIM Topology

**Tier:** Consumption (pay-per-call, no fixed cost for MVP)

**Products:**
| Product | Access | Rate Limit | Description |
|---------|--------|-----------|-------------|
| `cfp-compass-read` | Requires approval | 100 req/min | Read-only API access |
| `cfp-compass-readwrite` | Requires approval | 10 req/min (writes), 100 req/min (reads) | Full API access |

**Policies:**
- **Inbound:** Validate subscription key, rate limiting (by subscription key), CORS headers, request size limit (1 MB)
- **Backend:** Forward to Container App API backend (internal URL)
- **Outbound:** Remove internal headers, set cache-control headers
- **On-error:** Standard error response format

**Developer Portal:** Enabled for API consumers to register, browse API docs (auto-generated from OpenAPI spec), and manage subscription keys.

---

## 5. Authentication & Identity

### Recommendation: ASP.NET Core Identity + External OAuth Providers

**Decision:** Use ASP.NET Core Identity (self-hosted) as the primary identity system, not Azure AD B2C.

**Reasoning:**

| Factor | ASP.NET Core Identity | Azure AD B2C |
|--------|----------------------|-------------|
| Passkey (WebAuthn) support | FIDO2 via `Fido2NetLib` library; full control | Limited, requires custom policies (complex XML) |
| Cost | Free (self-hosted) | Per-authentication charges at scale |
| Customization | Full control over UI, flows, storage | Custom policies are complex/brittle |
| Social login (OAuth) | Built-in middleware for Google, GitHub, Microsoft, etc. | Supported but config-heavy |
| Complexity | Moderate — but we own the code | B2C custom policies are a significant learning curve |
| Admin via env config | Trivial — seed check on login | Requires Azure AD group mapping |

**Azure AD B2C is overkill for CFP Compass MVP.** The passkey requirement specifically makes B2C harder — B2C's WebAuthn support requires complex custom policies. ASP.NET Core Identity with `Fido2NetLib` gives us direct control.

### Passkey (WebAuthn/FIDO2) Integration

**Library:** [`Fido2NetLib`](https://github.com/passwordless-lib/fido2-net-lib) — mature, well-maintained .NET library for FIDO2/WebAuthn.

**Flow:**
1. **Registration:** User creates account with email → prompted to register a passkey → `Fido2NetLib` handles attestation ceremony → credential stored in `UserPasskeys` table
2. **Login:** User enters email → server sends assertion challenge → browser/authenticator signs challenge → `Fido2NetLib` validates assertion → session created
3. **Fallback:** Password login remains available for devices without passkey support; OAuth social login (Google, GitHub, Microsoft) as alternative

**Storage:** `UserPasskeys` table linked to `AspNetUsers`:
- `Id`, `UserId` (FK), `CredentialId`, `PublicKey`, `SignCount`, `CreatedAt`, `LastUsedAt`, `DeviceName`

### Social Login (OAuth)

Supported providers for MVP:
- **Google** — largest user base
- **GitHub** — natural fit for developer/speaker audience
- **Microsoft** — Azure ecosystem alignment

Implementation via `Microsoft.AspNetCore.Authentication.{Provider}` packages. External login creates/links local Identity user on first use.

### Session / Token Strategy

| Context | Mechanism | Details |
|---------|-----------|---------|
| Web app (Blazor Server) | Cookie authentication | HttpOnly, Secure, SameSite=Strict; 14-day sliding expiration |
| API (public, via APIM) | APIM subscription key | Passed in `Ocp-Apim-Subscription-Key` header |
| Submission edit links | Short-lived JWT tokens | Embedded in email links; 72-hour expiration; single-use |
| Claim verification links | Short-lived JWT tokens | Embedded in email links; 7-day expiration; single-use |
| Passkey assertion | Challenge-response | Server-generated challenge; 5-minute expiration |

**No refresh tokens needed** — the web app uses server-side session via cookies (Blazor Server), and the public API uses subscription keys (stateless).

### Admin Identity

Admins are identified by email match against an environment variable:

```
CFPCOMPASS_ADMIN_EMAILS=chad@example.com,admin2@example.com
```

On login, the system checks if the user's email is in this list and assigns the `Admin` claim. This is evaluated on every login (not cached), so adding/removing admins takes effect immediately on next login.

---

## 6. Frontend Architecture

### Recommendation: Blazor Server (Interactive SSR)

**Decision:** Blazor Server with .NET 10 interactive server-side rendering.

**Reasoning:**

| Factor | Blazor Server | Razor Pages | Blazor WebAssembly |
|--------|--------------|-------------|-------------------|
| .NET 10 alignment | First-class | First-class | First-class but larger payload |
| Interactivity | Rich (SignalR) | Limited (requires JS) | Rich (client-side) |
| SEO | SSR by default | SSR by default | Requires pre-rendering |
| Auth integration | Direct (server-side) | Direct | Requires API calls |
| i18n | `IStringLocalizer` | `IStringLocalizer` | More complex |
| Development speed | Fast (C# everywhere) | Fast but less interactive | Slower (WASM limitations) |
| Passkey integration | Server-side JS interop | Server-side | Client-side |

**Blazor Server wins** because:
1. Rich interactivity for dashboards, tracking status updates, and admin moderation without JavaScript
2. Server-side rendering for SEO (public CFP listings must be indexable)
3. Direct access to application services — no separate API layer needed for the web app
4. .NET 10's enhanced Blazor SSR (streaming, enhanced navigation) provides excellent UX
5. Passkey WebAuthn JavaScript interop is straightforward via `IJSRuntime`

**Risk:** SignalR connection dependency. Mitigated by Azure Container Apps' WebSocket support and .NET 10's improved reconnection handling.

### Page/Component Structure

```
Components/
├── Pages/
│   ├── Home.razor                     # Public CFP listing (default page)
│   ├── CfpDetail.razor                # CFP detail page
│   ├── PastCfps.razor                 # Archived CFPs browsing
│   ├── CfpHistory.razor               # Event-specific CFP history
│   ├── Submit.razor                    # Public CFP submission form
│   ├── EditSubmission.razor            # Edit pending/rejected submission (token auth)
│   ├── ClaimCfp.razor                  # Organizer claim flow
│   ├── Account/
│   │   ├── Register.razor              # Account creation
│   │   ├── Login.razor                 # Login (email/password + passkey + OAuth)
│   │   ├── ForgotPassword.razor        # Password reset request
│   │   ├── ResetPassword.razor         # Password reset form
│   │   └── Settings.razor              # Notification preferences
│   ├── Dashboard/
│   │   ├── MyTracking.razor            # Speaker's tracked CFPs
│   │   └── ApiAccess.razor             # Request/manage API keys
│   └── Admin/
│       ├── AdminDashboard.razor        # Summary metrics
│       ├── PendingSubmissions.razor     # Moderation queue
│       ├── ReviewSubmission.razor       # Detailed review with approve/reject
│       ├── ManageUsers.razor           # User list with search/disable
│       ├── ApiRequests.razor           # Pending API key requests
│       └── ManageClaims.razor          # Admin-assisted claim assignment
├── Shared/
│   ├── MainLayout.razor                # Site-wide layout
│   ├── NavMenu.razor                   # Navigation
│   ├── CfpCard.razor                   # CFP summary card (reused in listing, dashboard, archive)
│   ├── FilterPanel.razor               # Topic, location, format, date filters
│   ├── SortControl.razor               # Sort dropdown
│   ├── Pagination.razor                # Pagination component
│   ├── StatusBadge.razor               # Tracking/moderation status badges
│   ├── TrackingButtons.razor           # Interested/Submitted/Accepted buttons
│   ├── CountryPicker.razor             # Searchable ISO 3166-1 dropdown
│   ├── SubdivisionPicker.razor         # Cascading ISO 3166-2 dropdown
│   ├── TimeZonePicker.razor            # Searchable IANA time zone dropdown
│   ├── PasskeyPrompt.razor             # WebAuthn registration/login UI
│   └── ConfirmDialog.razor             # Reusable confirmation modal
```

### i18n Implementation

**Pattern:** ASP.NET Core localization with `IStringLocalizer<T>`.

```
Resources/
├── Pages/
│   ├── Home.en.resx                   # English strings for Home page
│   ├── CfpDetail.en.resx
│   └── ...
├── Shared/
│   ├── SharedResources.en.resx        # Common strings (buttons, labels, errors)
│   └── ValidationMessages.en.resx     # Validation error messages
```

**Rules:**
1. Every user-facing string goes through `IStringLocalizer` — no string literals in Razor/Blazor markup
2. Validation messages use `IStringLocalizer` via FluentValidation integration
3. Email templates use the same resource file pattern
4. Data annotations use `ErrorMessageResourceType` + `ErrorMessageResourceName`
5. Future languages: add `{Resource}.{locale}.resx` files; no code changes needed

**Configuration:**
```csharp
builder.Services.AddLocalization(options => options.ResourcesPath = "Resources");
builder.Services.Configure<RequestLocalizationOptions>(options =>
{
    var supportedCultures = new[] { new CultureInfo("en") };
    options.DefaultRequestCulture = new RequestCulture("en");
    options.SupportedCultures = supportedCultures;
    options.SupportedUICultures = supportedCultures;
});
```

### Static Assets / CDN Strategy

- **Azure Front Door** fronts both the web app and blob storage
- Static assets (`wwwroot/`) are served via Blazor Server's static file middleware, cached by Front Door
- Event logos are served from Azure Blob Storage via Front Door CDN with cache-control headers (1 hour public cache)
- CSS framework: **Bootstrap 5** — minimal custom CSS, consistent with .NET default templates
- No JavaScript framework — Blazor handles all interactivity; minimal JS interop for passkeys only

---

## 7. Background Services & Workers

### Recommendation: Azure Container Apps Jobs

**Decision:** Azure Container Apps Jobs (scheduled triggers) for all background work.

**Reasoning:**
1. **Same container ecosystem** as the web/API apps — single Dockerfile, shared codebase
2. **Cost-efficient** — jobs only run when triggered (no idle compute)
3. **Simpler than Azure Functions** — no Function-specific abstractions; just a .NET console app
4. **Terraform-managed** — Container Apps Jobs are well-supported in Terraform
5. **Scalable** — can scale to multiple job executions in parallel if needed

**Why not Azure Functions:** Functions add another deployment model, runtime, and abstraction layer. Container Apps Jobs keep the deployment topology uniform — everything is a container.

**Why not IHostedService:** Hosted services run inside the web/API container and compete for resources. Separate jobs provide isolation and independent scaling.

### Job Definitions

| Job | Schedule (CRON) | Description |
|-----|----------------|-------------|
| `CfpExpiryJob` | `0 0 * * *` (daily midnight UTC) | Move CFPs past 7 days after deadline from active → archived status |
| `DeadlineReminderJob` | `0 6 * * *` (daily 6 AM UTC) | Send reminders for tracked CFPs at 7, 3, 1 day(s) before deadline |
| `WeeklyDigestJob` | `0 8 * * 0` (Sunday 8 AM UTC) | Send weekly digest: new CFPs + closing soon CFPs |
| `WorldRegionAssignmentJob` | `0 */6 * * *` (every 6 hours) | Assign UN M.49 world region to any CFP with null WorldRegion |
| `DuplicateDetectionJob` | On-demand (triggered on submission) | Flag submissions with exact URL match against existing CFPs |

**Implementation pattern:**
```csharp
public class CfpExpiryJob(ICfpService cfpService, ILogger<CfpExpiryJob> logger)
{
    public async Task ExecuteAsync(CancellationToken ct)
    {
        var expired = await cfpService.GetExpiredCfpsAsync(ct);
        await cfpService.ArchiveCfpsAsync(expired, ct);
        logger.LogInformation("Archived {Count} expired CFPs", expired.Count);
    }
}
```

**Note on DuplicateDetectionJob:** This runs inline during submission processing (not on a schedule) — it queries for existing CFPs with the same `CfpUrl` and flags the submission for admin attention. It's part of the `CfpSubmissionService`, not a scheduled job.

---

## 8. Email Architecture

### ACS Integration Pattern

**Library:** `Azure.Communication.Email` SDK

**Service architecture:**
```
CFPCompass.Infrastructure/
└── Email/
    ├── AcsEmailService.cs          # Implements IEmailService; wraps ACS SDK
    ├── EmailTemplateRenderer.cs    # Renders Razor templates to HTML
    └── Templates/
        ├── _EmailLayout.cshtml     # Base email layout (header, footer, branding)
        ├── DeadlineReminder.cshtml
        ├── WeeklyDigest.cshtml
        ├── SubmissionConfirmation.cshtml
        ├── SubmissionApproved.cshtml
        ├── SubmissionRejected.cshtml
        ├── ClaimInvitation.cshtml
        ├── ReconsiderationConfirmed.cshtml
        ├── WelcomeEmail.cshtml
        ├── PasswordReset.cshtml
        └── ApiKeyApproved.cshtml
```

### Email Templates: Razor Templates

**Decision:** Razor-based email templates using `RazorLight` or ASP.NET Core's built-in Razor engine.

**Justification:**
1. Team already knows Razor syntax
2. Strong typing — template models are C# classes
3. i18n support via `IStringLocalizer` in templates
4. Layout/partial support for consistent branding
5. Testable — render templates in unit tests and validate HTML output

### Email Flows

**Transactional emails (sent immediately):**
| Email | Trigger | Recipient |
|-------|---------|-----------|
| Submission Confirmation | CFP submitted | Submitter (contact email) |
| Submission Approved | Admin approves CFP | Submitter (contact email) |
| Submission Rejected | Admin rejects CFP | Submitter (contact email) |
| Reconsideration Confirmed | Organizer requests reconsideration | Submitter (contact email) |
| Claim Invitation | Community-submitted CFP is published | Organizer Contact Email |
| Welcome Email | Account created | New user |
| Password Reset | Reset requested | User |
| API Key Approved | Admin approves API access | API consumer |
| Claim Verified | Organizer claim verified | Claimant |
| Account Disabled/Enabled | Admin action | Affected user |

**Scheduled/batch emails:**
| Email | Schedule | Recipients |
|-------|---------|-----------|
| Deadline Reminders | Daily 6 AM UTC | Users with tracked CFPs nearing deadline (7, 3, 1 day) |
| Weekly Digest | Sunday 8 AM UTC | Users with digest enabled |

### Unsubscribe / Preference Management

- **One-click unsubscribe:** Every email includes an unsubscribe link (`/account/settings?unsubscribe={type}&token={jwt}`)
- **List-Unsubscribe header:** Included in all marketing/digest emails per RFC 8058
- **Preferences page:** `/account/settings` shows toggles for Deadline Reminders and Weekly Digest
- **Token-based unsubscribe:** Unsubscribe links contain a signed JWT so users can unsubscribe without logging in
- **Email footer:** Every email includes "Manage your notification preferences" link

---

## 9. Infrastructure Topology

### Azure Services — MVP SKUs

| Service | SKU | Estimated Monthly Cost | Notes |
|---------|-----|----------------------|-------|
| Azure Container Apps | Consumption | $5-20 | Pay-per-use; 2 apps + jobs |
| Azure Container Apps Environment | Consumption | Included | Shared environment for all apps |
| Azure SQL Database | Serverless (GP S0) | $5-15 | Auto-pause when idle |
| Azure Cache for Redis | Basic C0 (250 MB) | $16 | Smallest tier |
| Azure Storage Account | GPv2 LRS | $1-3 | Blob storage for logos |
| Azure API Management | Consumption | $3.50/million calls | Pay-per-call; no fixed cost |
| Azure Communication Services | Pay-as-you-go | $0.25/1000 emails | Transactional email |
| Azure Key Vault | Standard | $0.03/10K operations | Secrets management |
| Azure Container Registry | Basic | $5 | Docker image store |
| Azure Front Door | Standard | $35 | CDN + SSL + routing |
| Azure Log Analytics | Pay-as-you-go | $2-5 | Centralized logging |

**Estimated MVP total: ~$75-105/month**

### Network Topology

**MVP approach: Public endpoints with APIM gateway.**

```
Internet
    │
    ├── Azure Front Door ──► Container App (Web) [public ingress]
    │
    └── Azure Front Door ──► APIM (Consumption) ──► Container App (API) [APIM-only ingress]
                                                         │
                                                         ├── Azure SQL (firewall: allow Azure services)
                                                         ├── Redis (access key auth)
                                                         ├── Blob Storage (SAS tokens)
                                                         ├── Key Vault (managed identity)
                                                         └── ACS (connection string from Key Vault)
```

**Rationale for public endpoints (no VNet):**
- APIM Consumption tier does not support VNet integration
- Azure SQL firewall + Redis access keys + Key Vault managed identity provide sufficient security for MVP
- VNet can be added post-MVP if/when moving to APIM Standard v2 tier

### Key Vault Usage

| Secret | Purpose |
|--------|---------|
| `AzureSql-ConnectionString` | Database connection |
| `Redis-ConnectionString` | Cache connection |
| `ACS-ConnectionString` | Email service |
| `Storage-ConnectionString` | Blob storage |
| `Fido2-Origins` | WebAuthn allowed origins |
| `AdminEmails` | Comma-separated admin email list |
| `OAuth-Google-ClientId` / `ClientSecret` | Google OAuth |
| `OAuth-GitHub-ClientId` / `ClientSecret` | GitHub OAuth |
| `OAuth-Microsoft-ClientId` / `ClientSecret` | Microsoft OAuth |
| `Jwt-SigningKey` | JWT signing for email tokens |

**Access method:** Azure Managed Identity on Container Apps → Key Vault access policies. No secrets in app config or environment variables at runtime.

### Container Registry

- **Azure Container Registry (Basic tier)**
- Images: `cfpcompass-web`, `cfpcompass-api`, `cfpcompass-workers`
- Tags: `latest`, `{git-sha}`, `{semver}`
- GitHub Actions pushes images on merge to `main`
- Container Apps configured to pull from ACR via managed identity

### Terraform Module Structure

```
infra/
├── main.tf                    # Root module — orchestrates all modules
├── variables.tf               # Input variables (env, region, SKUs)
├── outputs.tf                 # Outputs (URLs, resource IDs)
├── backend.tf                 # Remote state (Azure Storage)
├── providers.tf               # azurerm, azapi providers
│
├── modules/
│   ├── resource-group/        # Resource group
│   ├── container-apps/        # Container Apps Environment + Apps + Jobs
│   ├── sql/                   # Azure SQL Server + Database
│   ├── storage/               # Storage Account + Containers
│   ├── redis/                 # Azure Cache for Redis
│   ├── apim/                  # API Management + Products + Policies
│   ├── keyvault/              # Key Vault + Access Policies
│   ├── acr/                   # Container Registry
│   ├── acs/                   # Azure Communication Services
│   ├── frontdoor/             # Front Door + Origins + Routes
│   ├── identity/              # User-assigned managed identities
│   └── monitoring/            # Log Analytics + Application Insights
│
├── environments/
│   ├── dev/
│   │   ├── main.tf            # Dev-specific overrides
│   │   └── terraform.tfvars   # Dev variable values
│   ├── staging/
│   │   ├── main.tf
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       └── terraform.tfvars
```

**State management:** Remote state in Azure Storage Account (separate from app storage). State locking via Azure Blob lease.

---

## 10. Security Considerations

### Threat Model Highlights

| Threat | Vector | Mitigation |
|--------|--------|-----------|
| **Organizer claim spoofing** | Attacker claims someone else's event | Email verification to organizer's known email; admin-assisted fallback |
| **API abuse** | Excessive API calls, data scraping | APIM rate limiting (100 read / 10 write per min per key); subscription approval required |
| **Admin access escalation** | Unauthorized admin access | Admin emails in Key Vault (not code); checked on every login |
| **CFP spam submissions** | Automated spam submissions | reCAPTCHA on public submission form; admin moderation queue |
| **XSS via CFP data** | Malicious HTML in event descriptions | Blazor auto-encodes by default; HTML sanitization on rich text input (HtmlSanitizer library) |
| **CSRF** | Cross-site request forgery | Blazor Server uses SignalR (not HTTP forms) — inherently CSRF-resistant; antiforgery tokens on non-Blazor forms |
| **Credential stuffing** | Brute-force login | Account lockout after 5 failed attempts (15 min); passkey preferred (phishing-resistant) |
| **Email token abuse** | Reuse of email-embedded tokens | Single-use tokens; short expiration (72h for edits, 7d for claims) |

### CORS Policy

```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("Default", policy =>
    {
        policy.WithOrigins("https://cfpcompass.com", "https://www.cfpcompass.com")
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});
```

**APIM CORS:** Configured at the APIM policy level for API consumers (allow all origins for API product, since it's API-key authenticated).

### Input Validation Strategy

- **FluentValidation** for all DTOs at the Application layer — validates before reaching domain
- **Data annotations** as a secondary check on API request models
- **ISO 3166 validation:** Country/subdivision codes validated against a lookup table seeded in the database
- **IANA Time Zone validation:** Validated against `TimeZoneInfo.GetSystemTimeZones()` / NodaTime's TZDB
- **URL validation:** `Uri.TryCreate` with `UriKind.Absolute` + scheme check (https only)
- **File upload validation:** MIME type check + magic bytes validation for image uploads
- **HTML sanitization:** `HtmlSanitizer` library for rich text fields (event description, coverage details)

### Rate Limiting

| Layer | Mechanism | Scope |
|-------|-----------|-------|
| APIM | Built-in rate-limit policy | Per subscription key (public API) |
| App-level | ASP.NET Core Rate Limiting middleware | Per IP (web app — login, submission, registration) |

App-level rate limits (defense in depth):
- Login: 10 attempts per 15 minutes per IP
- Registration: 5 per hour per IP
- CFP submission: 10 per hour per IP
- Password reset: 3 per hour per email

### Audit Logging

**What to log:**
- All admin actions (approve, reject, disable user, assign claim)
- All moderation state transitions (pending → approved, rejected → reconsidering)
- Login events (success, failure, lockout)
- API key creation and usage (via APIM analytics)
- CFP submission and editing events
- Claim requests and resolutions

**Where:**
- Structured logging via `Serilog` → Azure Log Analytics workspace
- Admin actions additionally written to `AuditLog` table in Azure SQL for queryability
- APIM logs → Azure Monitor / Application Insights

**Format:** Structured JSON with correlation IDs, user IDs, action types, timestamps, and IP addresses.

---

## 11. Testing Strategy

### Unit Tests

- **Framework:** xUnit
- **Mocking:** NSubstitute (simpler API than Moq)
- **Assertions:** FluentAssertions
- **Naming:** `CFPCompass.{Layer}.Tests` — e.g., `CFPCompass.Domain.Tests`
- **Convention:** `{ClassName}Tests.cs` → `{MethodName}_Should_{ExpectedBehavior}_When_{Condition}`
- **Coverage target:** Domain and Application layers — 80%+ line coverage

**What to unit test:**
- Domain entity behavior (status transitions, validation rules)
- Application service logic (business rules, orchestration)
- FluentValidation validators (valid/invalid inputs)
- ISO 3166 / IANA / UN M.49 lookup services

### Integration Tests

- **Framework:** xUnit + `WebApplicationFactory<Program>`
- **Database:** Testcontainers (SQL Server container) for EF Core integration tests
- **Pattern:** Each test class gets a fresh database via Testcontainers; migrations applied on setup
- **Scope:** Repository tests, API endpoint tests (full HTTP pipeline), email service integration

```csharp
public class CfpApiTests : IClassFixture<CfpCompassWebApplicationFactory>
{
    private readonly HttpClient _client;
    public CfpApiTests(CfpCompassWebApplicationFactory factory)
        => _client = factory.CreateClient();

    [Fact]
    public async Task GetCfps_ReturnsOnlyApproved()
    {
        var response = await _client.GetAsync("/api/v1/cfps");
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        // ...
    }
}
```

### E2E Tests

- **Framework:** Playwright for .NET (`Microsoft.Playwright`)
- **Scope:** Critical user flows only (not exhaustive)
  - Browse CFP listing → view details
  - Submit a CFP → receive confirmation
  - Register → login → track a CFP → view dashboard
  - Admin login → approve submission → verify it appears publicly
  - Organizer claim flow
- **Environment:** Run against staging environment in CI/CD (post-deploy)
- **Data:** Seeded test data; cleaned up after each test run

### Test Data Management

- **Reference data:** Seeded via EF Core `HasData()` — countries, subdivisions, world regions, default topics/categories
- **Test fixtures:** Builder pattern for test entity creation (`CfpBuilder`, `UserBuilder`)
- **Integration tests:** Each test uses Testcontainers with fresh DB; no shared state
- **E2E tests:** Dedicated test user accounts and test CFPs seeded before suite; cleaned after

---

## 12. Key Architecture Decisions (ADR-Style)

### ADR-001: Azure SQL Database over Cosmos DB

**Context:** The project needs persistent storage for CFPs, users, tracking, and moderation workflows. Options considered: Azure SQL, Cosmos DB, PostgreSQL on Azure.

**Decision:** Azure SQL Database (Serverless, General Purpose).

**Consequences:**
- ✅ Strong relational model for FK-heavy domain (CFPs ↔ users ↔ moderation)
- ✅ Best EF Core tooling and migration support
- ✅ Serverless auto-pause saves cost for MVP
- ✅ Familiar to the broadest .NET developer audience
- ⚠️ Vertical scaling limits compared to Cosmos at extreme scale (not a concern for MVP)
- ⚠️ Serverless cold start (~10s) after idle period — acceptable for MVP traffic patterns

---

### ADR-002: Blazor Server over Razor Pages / Blazor WASM

**Context:** The frontend needs to render public CFP listings (SEO-important), interactive dashboards, admin tools, and handle complex forms with cascading dropdowns.

**Decision:** Blazor Server with .NET 10 interactive server-side rendering.

**Consequences:**
- ✅ Rich interactivity without JavaScript (tracking buttons, filters, admin moderation)
- ✅ Server-side rendering for SEO on public pages
- ✅ Single language (C#) for frontend and backend
- ✅ Direct access to application services (no API layer for web app)
- ⚠️ Requires persistent SignalR connection — adds latency for geographically distant users
- ⚠️ Server memory scales with connected users — monitor for MVP growth
- Mitigation: Azure Front Door for edge caching; Container Apps auto-scaling

---

### ADR-003: ASP.NET Core Identity over Azure AD B2C

**Context:** Authentication must support passkeys (WebAuthn/FIDO2), OAuth social login, and admin identification via env config. Azure AD B2C was the original assumption.

**Decision:** ASP.NET Core Identity (self-hosted) with `Fido2NetLib` for passkeys and built-in OAuth middleware for social login.

**Consequences:**
- ✅ Full control over passkey registration/login flow
- ✅ No per-auth costs (B2C charges at scale)
- ✅ Simpler admin email check (no B2C group mapping)
- ✅ Easier UI customization (no B2C custom policies)
- ⚠️ We own the security surface — must implement lockout, token rotation, etc.
- ⚠️ No enterprise SSO out of the box (could add later via OpenID Connect)
- Mitigation: ASP.NET Core Identity handles lockout, password hashing, token management natively

---

### ADR-004: Azure Container Apps Jobs over Azure Functions

**Context:** Background work includes scheduled jobs (digest, reminders, expiry) and on-demand processing (duplicate detection, region assignment).

**Decision:** Azure Container Apps Jobs with scheduled triggers.

**Consequences:**
- ✅ Same container ecosystem as web/API — single Dockerfile, shared codebase
- ✅ No Function-specific abstractions or bindings to learn
- ✅ Terraform-managed alongside other Container Apps
- ✅ Cost-efficient — jobs only run when triggered
- ⚠️ No built-in retry/poison-queue like Functions (must implement retry logic)
- ⚠️ Minimum schedule granularity is 1 minute (sufficient for all our jobs)
- Mitigation: Polly retry policies in job implementations; dead-letter logging to AuditLog table

---

### ADR-005: Azure Cache for Redis for Distributed Caching

**Context:** The API and web app need caching for response data, session state, and reference data. Options: Redis, in-memory only, SQL-based cache.

**Decision:** Azure Cache for Redis (Basic C0) for distributed cache; `IMemoryCache` for local reference data.

**Consequences:**
- ✅ Distributed cache supports multiple container instances
- ✅ Session state survives container restarts
- ✅ Sub-millisecond reads for cached CFP listings
- ⚠️ Basic tier has no SLA and no replication — acceptable for MVP
- ⚠️ Additional $16/month cost
- Mitigation: In-memory fallback for non-critical data; upgrade to Standard tier when traffic justifies it

---

### ADR-006: APIM Consumption Tier for API Gateway

**Context:** The public API needs rate limiting, subscription key management, and a developer portal. APIM was flagged as a requirement in decisions.md.

**Decision:** Azure API Management, Consumption tier.

**Consequences:**
- ✅ Pay-per-call (no fixed cost for MVP)
- ✅ Built-in rate limiting, key management, developer portal
- ✅ Auto-generated API documentation from OpenAPI spec
- ⚠️ Consumption tier has cold start (~1-2s on first call after idle)
- ⚠️ No VNet integration in Consumption tier
- ⚠️ Limited policy customization compared to Standard tier
- Mitigation: Front Door keeps the API warm via health probes; upgrade to Standard v2 when needed

---

## 13. Open Questions for Chad

### Q1: Domain Name and SSL

**Question:** What is the production domain for CFP Compass (e.g., `cfpcompass.com`, `cfpcompass.dev`)? Do you already own a domain, or should Parker provision one? This affects Front Door configuration, CORS policy, and APIM custom domain setup.

**Blocks:** Infrastructure provisioning (Parker), CORS and cookie domain configuration.

### Q2: reCAPTCHA vs. Alternative Bot Protection

**Question:** The public CFP submission form needs bot protection to prevent spam submissions. Should we use Google reCAPTCHA v3 (free, widely used, but Google dependency), Cloudflare Turnstile (free, privacy-focused), or a simple honeypot approach? This affects the submission form UX and third-party dependencies.

**Blocks:** Submission form implementation (Lambert), API submission endpoint (Ripley).

### Q3: Initial Reference Data Seeding

**Question:** Who provides the initial list of event categories and topic tags? Should we pre-seed with a standard set (e.g., Technology, Healthcare, Finance for categories; Cloud, AI/ML, Security, DevOps for topics), or does Chad want to define the initial taxonomy? These are admin-curated lists per the requirements.

**Blocks:** Database seeding (Ripley), filter UI (Lambert).

### Q4: Email Sender Identity

**Question:** What sender address and display name should transactional emails use? ACS requires a verified sender domain (e.g., `noreply@cfpcompass.com`). This depends on Q1 (domain) and requires DNS verification for ACS.

**Blocks:** Email implementation (Ripley), ACS domain verification (Parker).

---

**End of Architecture Document**
