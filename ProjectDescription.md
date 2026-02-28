## CFP Compass — Project Description for Squad

CFP Compass is a .NET 10, Azure‑hosted web application that aggregates open Calls for Papers (CFPs) to help community speakers discover speaking opportunities. The platform maintains a curated, up‑to‑date listing of active CFPs, each with event details, submission deadlines, and links to official CFP pages.

Event organizers can submit new CFPs through a public form. All submissions enter an admin moderation workflow; approved entries become publicly visible. No CFP is auto‑published.

Users can create accounts, favorite CFPs, and receive deadline reminders. The system also sends a weekly digest email summarizing newly added CFPs and CFPs closing soon.

The platform exposes a public, RESTful API that allows authorized consumers to read and write CFP Compass data. API access requires authentication and supports GET/POST/PUT operations for CFPs, submissions, and related metadata.

### Core Features

- Public listing of open CFPs with filtering, sorting, and detail pages
- Organizer submission workflow with admin moderation
- User accounts with the ability to favorite CFPs
- Email notifications for upcoming deadlines
- Weekly digest email of new and closing CFPs
- Public REST API for authorized consumers (read/write CFP data)

### Technical Expectations

- .NET 10 and C#
- Hosted on **Azure Container Apps**
- Persistent storage via Azure SQL or Cosmos DB
- Background processing (e.g., weekly digests, deadline reminders) via Azure Functions or containerized workers
- Authentication via Azure AD B2C or built‑in identity
- RESTful API with proper authorization and versioning
- **Infrastructure as Code using Terraform**
- **CI/CD pipelines implemented with GitHub Actions**
- Clean, maintainable, cloud‑native architecture with clear separation of concerns