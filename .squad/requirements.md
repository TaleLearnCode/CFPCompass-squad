# CFP Compass — Requirements Breakdown

**Last Updated:** 2026-02-28 v2  
**Owner:** Brett (Requirements Analyst)  
**Project:** CFP Compass — .NET 10 / Azure web application aggregating open Calls for Papers  
**Features:** 16  

---

## Personas

| Persona | Definition | Goals | Pain Points |
|---------|-----------|-------|-------------|
| **Speaker** | Community speaker looking for speaking opportunities; may be new or experienced | Find relevant CFPs quickly, keep track of favorites, never miss a deadline | Too many sources to check; deadlines scattered across multiple sites; manually tracking favorites |
| **Organizer** | Event organizer wanting to promote their CFP to a wider speaker audience | Get CFP in front of qualified speakers; fast approval process | Limited reach; waiting for approval; unclear submission requirements |
| **Admin** | Platform moderator ensuring quality and accuracy of listed CFPs | Review and approve/reject submissions efficiently; maintain quality standards | Volume of submissions; need to verify legitimacy; inconsistent data from organizers |
| **API Consumer** | Third-party developer or service integrating CFP data into their own tools | Reliable, versioned API access; read and write CFP data programmatically | API downtime; breaking changes; unclear authorization process |

---

## Epics

1. **CFP Discovery** — Enable speakers to find, browse, and track relevant CFPs (Features 1.1–1.4)
2. **CFP Submission & Moderation** — Allow organizers to submit CFPs and admins to review/approve them
3. **User Accounts & Authentication** — Provide account creation, login, and profile management
4. **Notifications & Reminders** — Send email notifications for deadlines and weekly digests
5. **Public API** — Expose RESTful API for authorized third-party access to CFP data
6. **Administration & Moderation** — Provide admin tools for CFP review, user management, and platform oversight

---

## Epic 1: CFP Discovery

### Feature 1.1: Public CFP Listing

**Description:** Display all approved CFPs on a public-facing page with essential details (event name, deadline, location, topics).

#### User Story 1.1.1: View All Open CFPs

**As a** speaker  
**I want to** see a list of all currently open CFPs  
**So that I can** discover speaking opportunities without creating an account

**Acceptance Criteria:**

- **Given** I am on the CFP Compass homepage
- **When** the page loads
- **Then** I see a list of all approved CFPs sorted by submission deadline (soonest first)
- **And** each CFP displays: event name, submission deadline, location (physical/virtual), and primary topic tags
- **And** the list shows only CFPs with future deadlines or deadlines within the last 7 days

#### User Story 1.1.2: View CFP Details

**As a** speaker  
**I want to** click on a CFP to see full details  
**So that I can** decide if it matches my interests and availability

**Acceptance Criteria:**

- **Given** I am viewing the CFP listing
- **When** I click on a CFP entry
- **Then** I am taken to a detail page showing: event name, description, submission deadline, notification date, event date(s), location, format (in-person/virtual/hybrid), topics, session types, and a link to the official CFP page
- **And** the detail page includes a "Submit Your Proposal" button linking to the official CFP URL

---

### Feature 1.2: Filtering & Sorting

**Description:** Allow speakers to filter CFPs by topic, location, deadline range, and format; sort by deadline, event date, or recently added.

#### User Story 1.2.1: Filter CFPs by Topic

**As a** speaker  
**I want to** filter the CFP list by topic tags  
**So that I can** focus on opportunities relevant to my expertise

**Acceptance Criteria:**

- **Given** I am on the CFP listing page
- **When** I select one or more topic tags from a filter panel
- **Then** the list updates to show only CFPs matching all selected topics
- **And** I can clear filters to return to the full list

#### User Story 1.2.2: Filter CFPs by Location & Format

**As a** speaker  
**I want to** filter CFPs by location (region/country) and format (in-person/virtual/hybrid)  
**So that I can** find opportunities I can realistically attend or present at

**Acceptance Criteria:**

- **Given** I am on the CFP listing page
- **When** I select a location filter (e.g., "North America", "Europe") and/or format (e.g., "Virtual")
- **Then** the list shows only CFPs matching the selected location and format criteria
- **And** filters are combinable with topic filters

#### User Story 1.2.3: Sort CFPs

**As a** speaker  
**I want to** sort CFPs by deadline, event date, or date added  
**So that I can** prioritize my submission workflow

**Acceptance Criteria:**

- **Given** I am on the CFP listing page
- **When** I select a sort option (deadline ascending, event date ascending, or date added descending)
- **Then** the list re-orders according to the selected sort criteria
- **And** the sort persists when applying filters

---

### Feature 1.3: Favorites & Personal Tracking

**Description:** Authenticated users can favorite CFPs and view a personalized list of saved opportunities.

#### User Story 1.3.1: Favorite a CFP

**As a** logged-in speaker  
**I want to** mark a CFP as a favorite  
**So that I can** easily return to it later

**Acceptance Criteria:**

- **Given** I am logged in and viewing a CFP detail page or listing
- **When** I click the "Favorite" button
- **Then** the CFP is added to my favorites list
- **And** the button state changes to "Unfavorite"
- **And** I can unfavorite by clicking again

#### User Story 1.3.2: View My Favorites

**As a** logged-in speaker  
**I want to** see all my favorited CFPs in one place  
**So that I can** review and manage my submission targets

**Acceptance Criteria:**

- **Given** I am logged in
- **When** I navigate to "My Favorites"
- **Then** I see a list of all CFPs I have favorited
- **And** the list displays the same details as the public listing (event name, deadline, location, topics)
- **And** I can remove CFPs from favorites directly from this page

---

### Feature 1.4: Past CFPs Archive

**Description:** A browsable archive of expired and closed CFPs, enabling speakers to research a conference's CFP history, understand when an event typically runs its CFP, and anticipate when the next opening might occur.

#### User Story 1.4.1: Browse the Past CFPs Archive

**As a** speaker  
**I want to** browse a list of expired and closed CFPs  
**So that I can** discover past events and understand which conferences have previously sought speakers

**Acceptance Criteria:**

- **Given** I am on the CFP Compass site
- **When** I navigate to the "Past CFPs" section
- **Then** I see a list of all CFPs whose submission deadlines have passed by more than 7 days
- **And** each entry displays: event name, submission deadline (past), event date(s), location, format, and primary topic tags
- **And** the list is sorted by submission deadline (most recent first by default)
- **And** I can filter the archive by topic, format, and location (same filter controls as the active listing)

#### User Story 1.4.2: View CFP History for an Event

**As a** speaker  
**I want to** see the CFP history for a specific conference  
**So that I can** understand when that event typically runs its CFP and anticipate when the next one might open

**Acceptance Criteria:**

- **Given** I am viewing a CFP entry (active or archived)
- **When** I click "View CFP History" for that event
- **Then** I see a chronological list of all archived CFPs from that event on CFP Compass
- **And** each historical entry displays: year, submission deadline, event date(s), and a link to the archived CFP detail page
- **And** if the event has only one archived entry, the history page still renders correctly with that single entry
- **And** a note is displayed: "CFP history is based on submissions to CFP Compass and may not be complete"

---

## Epic 2: CFP Submission & Moderation

### Feature 2.1: Organizer Submission Form

**Description:** Public form allowing event organizers to submit new CFPs for admin review. No account required — organizers identify themselves via a contact email field only.

#### User Story 2.1.1: Submit a New CFP

**As an** organizer  
**I want to** submit my event's CFP via a public form  
**So that it can** be reviewed and listed on CFP Compass

**Acceptance Criteria:**

> ℹ️ **Decision 1 (Resolved):** No organizer account is required. The submission form is entirely public — contact email only.

- **Given** I am on the "Submit a CFP" page (publicly accessible — no account or login required)
- **When** I fill out the form with: event name, description, submission deadline, notification date, event date(s), location, format, topics, session types, official CFP URL, and my contact email
- **And** I click "Submit"
- **Then** my submission is saved with status "Pending Review"
- **And** I receive a confirmation message stating "Your CFP has been submitted for review"
- **And** the submission is not publicly visible until approved

#### User Story 2.1.2: Form Validation

**As an** organizer  
**I want to** receive clear validation errors if my submission is incomplete  
**So that I can** correct it before submitting

**Acceptance Criteria:**

- **Given** I am filling out the CFP submission form
- **When** I attempt to submit with missing required fields (event name, submission deadline, official CFP URL, contact email)
- **Then** the form displays inline error messages identifying the missing or invalid fields
- **And** the submission is not saved until all required fields are valid

---

### Feature 2.2: Admin Moderation Workflow

**Description:** Admin dashboard to review pending CFP submissions, approve or reject with optional feedback.

#### User Story 2.2.1: View Pending Submissions

**As an** admin  
**I want to** see a list of all pending CFP submissions  
**So that I can** review and moderate them

**Acceptance Criteria:**

- **Given** I am logged in as an admin
- **When** I navigate to the "Pending Submissions" dashboard
- **Then** I see a list of all CFPs with status "Pending Review"
- **And** each entry displays: event name, submission deadline, organizer contact email, and date submitted
- **And** I can click on a submission to view full details

#### User Story 2.2.2: Approve a CFP

**As an** admin  
**I want to** approve a pending CFP submission  
**So that it** becomes publicly visible to speakers

**Acceptance Criteria:**

- **Given** I am viewing a pending CFP submission
- **When** I click "Approve"
- **Then** the CFP status changes to "Approved"
- **And** the CFP appears in the public listing immediately
- **And** a confirmation email is sent to the organizer's contact email

#### User Story 2.2.3: Reject a CFP with Feedback

**As an** admin  
**I want to** reject a CFP submission and provide a reason  
**So that the** organizer understands why it was not approved

**Acceptance Criteria:**

- **Given** I am viewing a pending CFP submission
- **When** I click "Reject" and enter a reason (e.g., "Deadline has passed", "Event not relevant to audience")
- **Then** the CFP status changes to "Rejected"
- **And** the CFP is not publicly visible
- **And** an email is sent to the organizer with the rejection reason

---

## Epic 3: User Accounts & Authentication

### Feature 3.1: Account Registration

**Description:** Allow speakers to create an account to access personalized features (favorites, notifications).

#### User Story 3.1.1: Create an Account

**As a** speaker  
**I want to** create an account with email and password  
**So that I can** favorite CFPs and receive notifications

**Acceptance Criteria:**

- **Given** I am on the registration page
- **When** I enter my email, password (min 8 characters), and confirm password
- **And** I click "Create Account"
- **Then** my account is created with status "Active"
- **And** I am automatically logged in and redirected to the CFP listing
- **And** I receive a welcome email

#### User Story 3.1.2: Duplicate Email Handling

**As a** speaker  
**I want to** be notified if I attempt to register with an email that already exists  
**So that I can** log in or reset my password instead

**Acceptance Criteria:**

- **Given** I am on the registration page
- **When** I enter an email that is already registered
- **And** I click "Create Account"
- **Then** I see an error message: "An account with this email already exists. Please log in or reset your password."
- **And** no duplicate account is created

---

### Feature 3.2: Login & Session Management

**Description:** Allow users to log in, maintain a session, and log out.

#### User Story 3.2.1: Log In

**As a** registered speaker  
**I want to** log in with my email and password  
**So that I can** access my favorites and notification settings

**Acceptance Criteria:**

- **Given** I am on the login page
- **When** I enter my registered email and correct password
- **And** I click "Log In"
- **Then** I am authenticated and redirected to the CFP listing or my previous page
- **And** my session persists for 14 days or until I log out

#### User Story 3.2.2: Invalid Login Handling

**As a** speaker  
**I want to** receive a clear error if my login credentials are incorrect  
**So that I can** retry or reset my password

**Acceptance Criteria:**

- **Given** I am on the login page
- **When** I enter an incorrect email or password
- **And** I click "Log In"
- **Then** I see an error message: "Invalid email or password"
- **And** I remain on the login page

---

### Feature 3.3: Password Reset

**Description:** Allow users to reset their password via email link.

#### User Story 3.3.1: Request Password Reset

**As a** speaker who forgot my password  
**I want to** request a password reset link  
**So that I can** regain access to my account

**Acceptance Criteria:**

- **Given** I am on the "Forgot Password" page
- **When** I enter my registered email and click "Send Reset Link"
- **Then** I receive an email with a unique password reset link valid for 1 hour
- **And** I see a confirmation message: "If an account with that email exists, a reset link has been sent."

#### User Story 3.3.2: Reset Password via Link

**As a** speaker  
**I want to** set a new password using the reset link  
**So that I can** log in again

**Acceptance Criteria:**

- **Given** I have received a password reset email
- **When** I click the link and enter a new password (min 8 characters)
- **And** I click "Reset Password"
- **Then** my password is updated
- **And** I am redirected to the login page with a message: "Your password has been reset. Please log in."

---

## Epic 4: Notifications & Reminders

### Feature 4.1: Deadline Reminders

**Description:** Email notifications sent to users before CFP deadlines for favorited CFPs. Notification delivery is controlled by a global account-level toggle.

#### User Story 4.1.1: Receive Deadline Reminder

**As a** logged-in speaker  
**I want to** receive an email reminder before a favorited CFP's deadline  
**So that I don't** miss the submission window

**Acceptance Criteria:**

> ℹ️ **Decision 9 (Resolved):** Deadline reminders are controlled by a **global toggle only** (on/off in account settings). Per-CFP granularity is deferred to a future iteration.

- **Given** I have favorited a CFP with a deadline in 7 days
- **When** the system runs the daily reminder job
- **Then** I receive an email with subject "Reminder: [Event Name] CFP closes in 7 days"
- **And** the email includes: event name, deadline date, link to CFP detail page, and link to official submission page
- **And** reminders are sent at 7 days, 3 days, and 1 day before deadline

#### User Story 4.1.2: Opt Out of Deadline Reminders

**As a** logged-in speaker  
**I want to** disable all deadline reminders via a global toggle in my account settings  
**So that I can** manage notifications according to my preference

**Acceptance Criteria:**

- **Given** I am logged in and on my account settings page
- **When** I toggle "Deadline Reminders" to OFF (global) and save
- **Then** I no longer receive deadline reminder emails for any favorited CFPs
- **And** I can re-enable reminders at any time

---

### Feature 4.2: Weekly Digest Email

**Description:** Weekly email summarizing newly added CFPs and CFPs closing soon. Delivery is controlled by a global account-level toggle.

#### User Story 4.2.1: Receive Weekly Digest

**As a** logged-in speaker  
**I want to** receive a weekly digest email of new and closing CFPs  
**So that I can** stay informed without visiting the site daily

**Acceptance Criteria:**

> ℹ️ **Decision 9 (Resolved):** The weekly digest is controlled by a **global toggle only** (on/off in account settings). Per-CFP digest controls are deferred to a future iteration.

- **Given** I am a registered user with digest emails enabled
- **When** the system runs the weekly digest job (every Sunday at 8 AM UTC)
- **Then** I receive an email with subject "CFP Compass Weekly Digest"
- **And** the email includes two sections:
  - "New This Week": CFPs added in the last 7 days
  - "Closing Soon": CFPs with deadlines in the next 14 days
- **And** each CFP entry shows: event name, deadline, location, and link to detail page

#### User Story 4.2.2: Opt Out of Weekly Digest

**As a** logged-in speaker  
**I want to** disable weekly digest emails via a global toggle in my account settings  
**So that I can** control email frequency

**Acceptance Criteria:**

- **Given** I am logged in and on my account settings page
- **When** I toggle "Weekly Digest" to OFF (global) and save
- **Then** I no longer receive weekly digest emails
- **And** I can re-enable the digest at any time

---

## Epic 5: Public API

### Feature 5.1: API Authentication & Authorization

**Description:** Secure the API with token-based authentication; restrict write operations to authorized consumers. Rate limits: **100 requests/minute per API key** for read operations; **10 requests/minute per API key** for write operations.

#### User Story 5.1.1: Authenticate API Access

**As an** API consumer  
**I want to** authenticate using an API key  
**So that I can** access protected endpoints

**Acceptance Criteria:**

- **Given** I have been issued an API key by an admin
- **When** I include the API key in the `Authorization: Bearer <token>` header
- **Then** I can access API endpoints scoped to my permission level (read-only or read-write)
- **And** requests without a valid API key receive a `401 Unauthorized` response
- **And** read operations are rate-limited to **100 requests/minute per API key**
- **And** write operations are rate-limited to **10 requests/minute per API key**
- **And** requests exceeding the rate limit receive a `429 Too Many Requests` response

#### User Story 5.1.2: Request API Access

**As an** API consumer  
**I want to** request an API key via a self-service form  
**So that I can** integrate CFP data into my application

**Acceptance Criteria:**

- **Given** I am on the "Request API Access" page
- **When** I submit a form with my name, email, organization, and intended use
- **Then** my request is saved with status "Pending Admin Review"
- **And** I receive a confirmation email
- **And** an admin can approve or reject my request from the admin dashboard

---

### Feature 5.2: API Endpoints — Read CFP Data

**Description:** Provide GET endpoints for listing and retrieving CFP data. All endpoints are versioned under `/api/v1/`.

#### User Story 5.2.1: List All Approved CFPs

**As an** API consumer  
**I want to** retrieve a JSON list of all approved CFPs  
**So that I can** display them in my own application

**Acceptance Criteria:**

- **Given** I am authenticated with a valid API key
- **When** I send a `GET /api/v1/cfps` request
- **Then** I receive a `200 OK` response with a JSON array of CFP objects
- **And** each object includes: id, eventName, description, submissionDeadline, notificationDate, eventDate, location, format, topics, sessionTypes, officialUrl
- **And** only CFPs with status "Approved" are returned

#### User Story 5.2.2: Get CFP by ID

**As an** API consumer  
**I want to** retrieve a single CFP by its unique ID  
**So that I can** fetch detailed information on demand

**Acceptance Criteria:**

- **Given** I am authenticated with a valid API key
- **When** I send a `GET /api/v1/cfps/{id}` request with a valid CFP ID
- **Then** I receive a `200 OK` response with a single CFP object
- **And** if the ID does not exist or the CFP is not approved, I receive a `404 Not Found` response

---

### Feature 5.3: API Endpoints — Submit & Update CFPs

**Description:** Provide POST and PUT endpoints for authorized consumers to submit or update CFP data. All endpoints are versioned under `/api/v1/`. All endpoints use URL path versioning (`/api/v1/`).

#### User Story 5.3.1: Submit a CFP via API

**As an** API consumer with write access  
**I want to** submit a new CFP via POST request  
**So that I can** automate CFP ingestion from external sources

**Acceptance Criteria:**

- **Given** I am authenticated with a read-write API key
- **When** I send a `POST /api/v1/cfps` request with a valid JSON body (eventName, description, submissionDeadline, officialUrl, etc.)
- **Then** the CFP is created with status "Pending Review"
- **And** I receive a `201 Created` response with the new CFP object including its ID
- **And** the submission follows the same moderation workflow as the web form

#### User Story 5.3.2: Update a CFP via API

**As an** API consumer with write access  
**I want to** update an existing CFP via PUT request  
**So that I can** correct or refresh CFP details

**Acceptance Criteria:**

- **Given** I am authenticated with a read-write API key
- **When** I send a `PUT /api/v1/cfps/{id}` request with updated fields
- **Then** the CFP is updated and the status changes to "Pending Review" if previously approved
- **And** I receive a `200 OK` response with the updated CFP object
- **And** an admin must re-approve changes before they appear publicly

---

## Epic 6: Administration & Moderation

### Feature 6.1: Admin Dashboard

**Description:** Centralized dashboard for admins to manage submissions, users, and API access requests.

#### User Story 6.1.1: View Admin Dashboard

**As an** admin  
**I want to** access a dashboard showing pending CFPs, user counts, and recent activity  
**So that I can** monitor platform health at a glance

**Acceptance Criteria:**

- **Given** I am logged in as an admin
- **When** I navigate to "/admin"
- **Then** I see summary metrics: pending CFP count, total approved CFPs, total users, pending API access requests
- **And** I see quick links to "Pending CFPs", "Manage Users", "API Access Requests"

---

### Feature 6.2: User Management

**Description:** Allow admins to view, disable, or delete user accounts.

#### User Story 6.2.1: View All Users

**As an** admin  
**I want to** see a list of all registered users  
**So that I can** review account activity and manage access

**Acceptance Criteria:**

- **Given** I am logged in as an admin
- **When** I navigate to "Manage Users"
- **Then** I see a table of all users with: email, account creation date, status (Active/Disabled)
- **And** I can search users by email

#### User Story 6.2.2: Disable a User Account

**As an** admin  
**I want to** disable a user account  
**So that I can** prevent access without deleting their data

**Acceptance Criteria:**

- **Given** I am viewing a user's profile in the admin panel
- **When** I click "Disable Account"
- **Then** the user's status changes to "Disabled"
- **And** the user cannot log in (receives "Account disabled" message)
- **And** I can re-enable the account at any time

---

## Resolved Decisions

### Decision 1: Organizer Account Requirement
**Answer:** Public form + email only. No account required to submit a CFP.  
**Impact:** Feature 2.1 (Organizer Submission Form) — form requires only a contact email field; no login gate for organizers.

### Decision 2: CFP Expiration & Archive Policy
**Answer:** Hide CFPs 7 days after submission deadline. Archive to a "Past CFPs" section. Speakers can browse the archive to see when an event's CFP last ran and anticipate when the next one might open.  
**Impact:** Feature 1.1 (Public CFP Listing) — active listing hides CFPs 7+ days post-deadline. Feature 1.4 (Past CFPs Archive) — new feature added to Epic 1.

### Decision 3: API Rate Limits
**Answer:** 100 requests/minute per API key for read operations; 10 requests/minute per API key for write operations. Requests exceeding limits receive `429 Too Many Requests`.  
**Impact:** Feature 5.1 (API Authentication & Authorization) — rate limit enforcement is part of the API auth spec.

### Decision 4: Admin Account Creation
**Answer:** Environment config (list of admin emails) for MVP. No admin management UI in initial scope.  
**Impact:** Feature 6.1 (Admin Dashboard) — admin identity is config-driven, not role-assigned via UI.

### Decision 5: Email Service Provider
**Answer:** Azure Communication Services (ACS) for all transactional and digest email (deadline reminders, digest, approval/rejection notifications).  
**Impact:** Epic 4 (Notifications & Reminders), Feature 2.2 (Admin Moderation Workflow email confirmations).

### Decision 6: CFP Event Date Schema
**Answer:** Optional `startDate` / `endDate` fields. Both may be null if the event date is TBD.  
**Impact:** Feature 1.1 (CFP detail page), Feature 2.1 (submission form), Features 5.2/5.3 (API schema — `eventDate` object with optional startDate/endDate).

### Decision 7: API Versioning Strategy
**Answer:** URL path versioning: `/api/v1/`. Simple and discoverable.  
**Impact:** Features 5.2/5.3 (API Endpoints) — all endpoints prefixed with `/api/v1/`.

### Decision 8: Duplicate CFP Detection
**Answer:** Manual admin review. Admin UI flags potential duplicates when an exact official URL match is found on an incoming submission.  
**Impact:** Feature 2.2 (Admin Moderation Workflow) — admin UI shows a duplicate flag; no automated merge.

### Decision 9: Notification Preferences Granularity
**Answer:** Global toggle for MVP (all reminders on/off, digest on/off). Per-CFP controls deferred to a later iteration.  
**Impact:** Features 4.1/4.2 (Deadline Reminders & Weekly Digest) — settings are account-level toggles only; no per-CFP opt-out in MVP.

### Decision 10: Internationalization
**Answer:** English-only content for MVP. i18n architecture (resource files, locale-aware rendering) must be built in from day 1 — no hard-coded strings in UI.  
**Impact:** All UI-facing features — no string literals in UI code; resource files required from the start.

---

**End of Requirements Breakdown**
