# CFP Compass — Requirements Breakdown

**Last Updated:** 2026-02-28  
**Version:** v3.1  
**Owner:** Brett (Requirements Analyst)  
**Project:** CFP Compass — .NET 10 / Azure web application aggregating open Calls for Papers  
**Features:** 18

---

## Personas

| Persona | Definition | Goals | Pain Points |
|---------|-----------|-------|-------------|
| **Speaker** | Community speaker looking for speaking opportunities; may be new or experienced | Find relevant CFPs quickly, keep track of favorites, never miss a deadline | Too many sources to check; deadlines scattered across multiple sites; manually tracking favorites |
| **Organizer** | Event organizer wanting to promote their CFP to a wider speaker audience | Get CFP in front of qualified speakers; fast approval process | Limited reach; waiting for approval; unclear submission requirements |
| **Admin** | Platform moderator ensuring quality and accuracy of listed CFPs | Review and approve/reject submissions efficiently; maintain quality standards | Volume of submissions; need to verify legitimacy; inconsistent data from organizers |
| **API Consumer** | Third-party developer or service integrating CFP data into their own tools | Reliable, versioned API access; read and write CFP data programmatically | API downtime; breaking changes; unclear authorization process |
| **Community Contributor** | A speaker or community member who submits a CFP listing on behalf of an event they didn't organize | Contribute to CFP Compass being comprehensive and up-to-date; receive credit for their submission | No ongoing ownership of the listing; dependent on organizer to claim and manage it |

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

**Description:** Display all approved CFPs on a public-facing page with essential details (event name, deadline, location, topics). A CFP may have multiple categories and topics; filtering works against multi-value sets.

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

<!-- Updated v3: Added UN M.49 world region, country, and country subdivision filters -->

**Description:** Allow speakers to filter CFPs by topic, location (world region, country, country subdivision), deadline range, and format; sort by deadline, event date, or recently added. Category and topic filters work against multi-value sets — a CFP with multiple categories will appear in results for any of its selected categories.

#### User Story 1.2.1: Filter CFPs by Topic

**As a** speaker  
**I want to** filter the CFP list by topic tags  
**So that I can** focus on opportunities relevant to my expertise

**Acceptance Criteria:**

- **Given** I am on the CFP listing page
- **When** I select one or more topic tags from a filter panel
- **Then** the list updates to show only CFPs matching all selected topics
- **And** I can clear filters to return to the full list
- **Given** a speaker is filtering CFPs
- **When** they filter by a Primary Domain or Secondary Tag
- **Then** any CFP that includes that category/tag in its multi-value set is returned

#### User Story 1.2.2: Filter CFPs by Location & Format

**As a** speaker  
**I want to** filter CFPs by location (world region, country, country subdivision) and format (in-person/virtual/hybrid)  
**So that I can** find opportunities I can realistically attend or present at

**Acceptance Criteria:**

- **Given** I am on the CFP listing page
- **When** I select a world region filter (UN M.49 region, e.g., "Northern America", "Western Europe")
- **Then** the list shows only CFPs whose event country maps to that UN M.49 region
- **Given** I am on the CFP listing page
- **When** I select a country filter (ISO 3166-1 country, e.g., "United States", "Germany")
- **Then** the list shows only CFPs in that country
- **Given** I am on the CFP listing page
- **When** I select a country subdivision filter (ISO 3166-2 subdivision, e.g., "California", "Bavaria")
- **Then** the list shows only CFPs in that subdivision
- **Given** I am on the CFP listing page
- **When** I select a format filter (e.g., "Virtual", "In-Person", "Hybrid")
- **Then** the list shows only CFPs matching the selected format
- **And** all location filters (world region, country, subdivision) and format filters are combinable with topic filters

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

### Feature 1.3: Personal CFP Tracking

<!-- Updated v3: Replaced "favorite" terminology with "interest"; added submission and acceptance tracking states -->

**Description:** Authenticated users can mark CFPs as interested, track submission status, and record acceptances.

#### User Story 1.3.1: Mark Interest in a CFP

**As a** logged-in speaker  
**I want to** mark a CFP as interested  
**So that I can** easily return to it later and track my engagement

**Acceptance Criteria:**

- **Given** I am logged in and viewing a CFP detail page or listing
- **When** I click the "Mark as Interested" button
- **Then** the CFP is added to my tracked CFPs with status "Interested"
- **And** the button state changes to "Remove Interest"
- **And** I can remove interest by clicking again

#### User Story 1.3.2: Track CFP Submission Status

**As a** speaker  
**I want to** mark that I have submitted a talk proposal to a CFP  
**So that I can** track which CFPs I've applied to

**Acceptance Criteria:**

- **Given** I am logged in and viewing a CFP listing
- **When** I click "I've Submitted"
- **Then** that CFP is marked as "Submitted" in my personal dashboard
- **Given** I view my dashboard
- **When** I look at my tracked CFPs
- **Then** each CFP shows one of: Interested / Submitted / Accepted

#### User Story 1.3.3: Track CFP Acceptance Status

**As a** speaker  
**I want to** mark that I have been accepted to speak at an event  
**So that I can** track my confirmed speaking engagements

**Acceptance Criteria:**

- **Given** I have previously marked a CFP as "Submitted"
- **When** I receive acceptance and click "I've Been Accepted"
- **Then** the CFP status on my dashboard updates to "Accepted"
- **Given** I view my profile/dashboard
- **When** I filter by "Accepted"
- **Then** I see only CFPs where I have been accepted to speak

#### User Story 1.3.4: View My Tracked CFPs

**As a** logged-in speaker  
**I want to** see all my tracked CFPs in one place  
**So that I can** review and manage my submission targets

**Acceptance Criteria:**

- **Given** I am logged in
- **When** I navigate to "My Dashboard" or "My Tracked CFPs"
- **Then** I see a list of all CFPs I have marked as Interested, Submitted, or Accepted
- **And** the list displays the same details as the public listing (event name, deadline, location, topics) plus the tracking status
- **And** I can filter by status: Interested / Submitted / Accepted
- **And** I can remove CFPs from tracking directly from this page

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

<!-- Updated v3: Expanded data model with comprehensive event/CFP fields including ISO/IANA standards, expense coverage, categorization, and organizer editing capability -->
<!-- Updated v3.1: submitter/organizer distinction, "Are you the organizer?" checkbox, organizer contact email -->

**Description:** Public form allowing event organizers to submit new CFPs for admin review. No account required — organizers identify themselves via a contact email field only.

**CFP Data Model:** The submission form captures the following fields, organized into logical groups:

**Event Details:**
- Event Name
- Event Type (enum: Conference, Meetup/User Group, Workshop, Summit, Symposium, Other)
- Event Time Zone (IANA Time Zone Database identifier, e.g., "America/Chicago" — presented via searchable dropdown)
- Event Logo (image upload)
- Event Description
- Event Location: City, State/Province (ISO 3166-2 subdivision), Country (ISO 3166-1 alpha-2 code)
- Venue Name
- Event Website URL
- Organizer's Legal Name
- Social Media Links (all optional): X/Twitter, LinkedIn, Facebook, Instagram, Bluesky
- In-Person / Online / Hybrid (enum)

**CFP Details:**
- CFP Open Date / CFP Close Date (date range)
- CFP URL
- CFP Description/Details (rich text)
- Speaker Support Email
- Show Speaker Support Email on listing (boolean toggle)

**Event Scheduling:**
- Event Start Date / Event End Date (optional; null if TBD — per Decision 6)
- Additional Event Dates (repeatable field for Meetup/User Group CFPs that cover multiple event dates)

**Expense Coverage:**
- Travel expenses covered (boolean)
- Accommodation expenses covered (boolean)
- Full conference fee covered (boolean)
- Coverage Details (free text: max amount, number of nights, special terms, additional benefits)

**Categorization:**
- **Event Category (Primary Domain)** — Multi-select, at least 1 required. A CFP may belong to multiple primary domains. Seeded from this authoritative taxonomy (admin-extensible, not free-text):
  1. Software Development & Engineering — General programming, languages, frameworks, tooling, architecture, testing, DevOps
  2. Cloud & Infrastructure — Cloud platforms, distributed systems, networking, SRE, observability, infrastructure automation
  3. Data, AI & Machine Learning — Data engineering, analytics, ML/AI, LLMs, MLOps, data science
  4. Security & Privacy — Application security, cloud security, governance, compliance, identity, threat detection
  5. Web, Mobile & Frontend — Web technologies, frontend frameworks, UX/UI, mobile development
  6. DevOps, Platform Engineering & Automation — CI/CD, platform teams, IaC, GitOps, automation, reliability
  7. Enterprise & Architecture — Software architecture, system design, integration, enterprise platforms, modernization
  8. Open Source & Community — OSS ecosystems, maintainership, community governance, tooling
  9. Product, Design & Innovation — Product management, design systems, research, innovation practices
  10. Specialized Domains — Niche or vertical-specific tech (e.g., fintech, health tech, IoT, robotics, gaming)
- **Event Topics (Secondary Tags)** — Multi-select, 0 or more. Optional field. Seeded from these secondary tag groups (admin-extensible, not free-text):
  - Programming Languages — .NET, Java, JavaScript/TypeScript, Python, Go, Rust, C++, etc.
  - Frameworks & Ecosystems — React, Angular, Vue, ASP.NET Core, Spring, Django, Node.js, etc.
  - Cloud Providers — Azure, AWS, GCP, multi-cloud, hybrid cloud
  - AI/ML Focus Areas — LLMs, generative AI, MLOps, applied ML, AI ethics
  - Architecture Styles — Event-driven, microservices, serverless, monolith modernization, domain-driven design
  - Infrastructure Practices — IaC, Terraform, Kubernetes, containers, networking, observability
  - Security Topics — AppSec, cloud security, identity, zero trust, red/blue/purple team
  - Data Topics — Data engineering, warehousing, analytics, BI, streaming, databases
  - Developer Experience — Tooling, productivity, documentation, testing, automation
  - Community & Career — Speaking, leadership, mentoring, DEI, community building

**Auto-populated (not user input):**
- UN M.49 World Region — Automatically assigned by the system using the ISO 3166-1 → UN M.49 mapping table based on the submitted country code. This is backend-derived and is NOT a user-facing input field.
- **Submitter** — Automatically recorded at submission time. Captured as the authenticated user account (if the submitter has an account) or as the contact email (if submitted without an account). This is NOT a field the submitter fills in.

**Submission Flags (user input):**
- **"Are you the event organizer?"** (boolean checkbox/toggle — defaults to **Yes**): If unchecked, the submitter is flagged as a community contributor, not the organizer. Submission is marked "Unverified — Awaiting Organizer Claim" pending organizer verification.
- **Organizer Contact Email** (text, optional — shown only when "Are you the event organizer?" is **No**): The known email address for the event organizer; used to send a claim invitation when the CFP is published.

#### User Story 2.1.1: Submit a New CFP

**As an** organizer  
**I want to** submit my event's CFP via a public form  
**So that it can** be reviewed and listed on CFP Compass

**Acceptance Criteria:**

> ℹ️ **Decision 1 (Resolved):** No organizer account is required. The submission form is entirely public — contact email only.

- **Given** I am on the "Submit a CFP" page (publicly accessible — no account or login required)
- **When** I fill out the form with all required fields per the CFP Data Model (event name, event type, time zone, location, CFP open/close dates, CFP URL, contact email, etc.)
- **And** I click "Submit"
- **Then** my submission is saved with status "Pending Review"
- **And** I receive a confirmation message stating "Your CFP has been submitted for review"
- **And** the submission is not publicly visible until approved
- **And** country and country subdivision values are validated against ISO 3166 (only valid ISO 3166-1 alpha-2 country codes and ISO 3166-2 subdivision codes are accepted)
- **And** time zone value is validated against the IANA Time Zone Database (only canonical IANA identifiers are accepted)
- **And** the system automatically assigns the UN M.49 world region based on the submitted country code
- **Given** an organizer is completing the submission form
- **When** they reach the Event Category field
- **Then** they can select one or more Primary Domain categories from the seeded list
- **And** at least one category must be selected to submit
- **Given** an organizer selects multiple categories
- **When** the listing is published
- **Then** all selected categories appear on the listing and are filterable
- **Given** an organizer is completing the submission form
- **When** they reach the Event Topics field
- **Then** they can select zero or more Secondary Tags from the seeded list
- **And** this field is optional
- **Given** a submitter completes the form and indicates they **are** the event organizer (default)
- **When** the submission is saved
- **Then** the submission proceeds through the normal moderation workflow with status "Organizer Submitted"
- **Given** a submitter completes the form and indicates they are **NOT** the event organizer
- **When** the submission is saved
- **Then** the submission is flagged as "Unverified — Awaiting Organizer Claim" (pending organizer verification after approval)
- **Given** a submitter provides an Organizer Contact Email and the submission is approved/published
- **When** the CFP goes live
- **Then** the system sends the organizer a claim invitation email to the provided Organizer Contact Email

#### User Story 2.1.2: Form Validation

**As an** organizer  
**I want to** receive clear validation errors if my submission is incomplete  
**So that I can** correct it before submitting

**Acceptance Criteria:**

- **Given** I am filling out the CFP submission form
- **When** I attempt to submit with missing required fields (event name, event type, time zone, submission deadline, official CFP URL, contact email, location details)
- **Then** the form displays inline error messages identifying the missing or invalid fields
- **And** the submission is not saved until all required fields are valid
- **And** invalid ISO 3166 country/subdivision codes are rejected with a clear error message
- **And** invalid IANA time zone identifiers are rejected with a clear error message

#### User Story 2.1.3: Edit Pending Submission

**As an** organizer  
**I want to** edit my submitted CFP listing before it is approved/published  
**So that I can** correct mistakes or add information

**Acceptance Criteria:**

- **Given** my submission is in "Pending Review" or "Rejected (Reconsidering)" status
- **When** I visit my submission via a link provided in the confirmation/notification email
- **Then** I can edit all fields and resubmit for review
- **And** the submission status remains "Pending Review" (or changes from "Rejected (Reconsidering)" to "Pending Review")
- **Given** my submission is in "Approved" status
- **When** I visit my submission via the link
- **Then** the edit option is not available
- **And** a message is displayed: "Contact admin to request changes to an approved listing"

---

### Feature 2.2: Admin Moderation Workflow

<!-- Updated v3: Added organizer reconsideration flow -->

**Description:** Admin dashboard to review pending CFP submissions, approve or reject with optional feedback. Includes a reconsideration flow allowing organizers to request re-review of rejected submissions.

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
- **And** the rejection notification email includes a "Request Reconsideration" button/link

#### User Story 2.2.4: Organizer Requests Reconsideration

**As an** organizer whose submission was rejected  
**I want to** request reconsideration of my rejected submission  
**So that I can** address the admin's concerns and resubmit

**Acceptance Criteria:**

- **Given** I received a rejection notification email for my CFP submission
- **When** I click "Request Reconsideration" in the email or on my submission dashboard
- **Then** the submission status changes to "Rejected (Reconsidering)"
- **And** the submission becomes editable (see Story 2.1.3)
- **And** the admin sees the submission back in their moderation queue with a "Reconsidering" badge
- **And** I receive a confirmation message: "Reconsideration requested. You may now edit and resubmit your CFP."

#### User Story 2.2.5: Admin Reviews Resubmitted CFP

**As an** admin  
**I want to** review a CFP that has been resubmitted after reconsideration  
**So that I can** approve it if the organizer has addressed my concerns

**Acceptance Criteria:**

- **Given** a CFP submission has status "Rejected (Reconsidering)" and the organizer has resubmitted
- **When** I view the submission in the moderation queue
- **Then** I see a "Reconsidering" badge on the submission
- **And** I can view the organizer's edits and any previous rejection notes
- **And** I can approve, reject again, or leave a note for further clarification

---

### Feature 2.3: Organizer Claim Flow

<!-- Updated v3.1: organizer claim flow -->

**Description:** Allows the verified event organizer to claim ownership of a CFP listing that was submitted by a community member (non-organizer). Once claimed, the organizer can edit the listing, manage future submissions for the same event, and receive notifications.

#### User Story 2.3.1: Claim a CFP Listing

**As an** event organizer  
**I want to** claim a CFP listing that someone else submitted for my event  
**So that I can** take ownership and manage it going forward

**Acceptance Criteria:**

- **Given** a CFP listing has been published and is flagged as "Unverified — Awaiting Organizer Claim"
- **When** an organizer visits the listing and clicks "Claim This Event"
- **Then** they are prompted to verify their identity as the organizer (e.g., via a verification email sent to the official Speaker Support Email on the listing, or to the Organizer Contact Email captured at submission time)
- **Given** the organizer completes verification
- **When** the claim is confirmed
- **Then** the listing status updates to "Organizer Verified"
- **And** the organizer's account is linked as the owner
- **And** the original submitter retains credit as a community contributor
- **Given** the claim is successful
- **When** the organizer views the listing
- **Then** they can edit all listing fields and submit changes for admin review (per the existing edit flow in Feature 2.1)

#### User Story 2.3.2: Admin-Assisted Claim

**As an** admin  
**I want to** manually assign organizer ownership of a CFP listing  
**So that I can** resolve disputed or unverified listings without waiting for self-service verification

**Acceptance Criteria:**

- **Given** a listing is in "Unverified — Awaiting Organizer Claim" status
- **When** an admin navigates to the listing in the admin dashboard
- **Then** they can search for and assign a registered user account as the organizer-owner
- **Given** the admin assigns an owner
- **When** the assignment is saved
- **Then** the listing status changes to "Organizer Verified (Admin Assigned)"
- **And** the assigned user receives a notification

#### User Story 2.3.3: Claim Invitation via Email

**As an** event organizer  
**I want to** receive an email invitation to claim my event's CFP listing  
**So that I can** be notified when a community member submits on my behalf

**Acceptance Criteria:**

- **Given** a submission is published and an organizer contact email was provided at submission time
- **When** the CFP goes live
- **Then** the system sends a "Someone submitted your CFP — claim it here" email to the organizer contact email with a unique claim link
- **Given** the organizer clicks the claim link in the email
- **When** they authenticate (or create an account)
- **Then** they are taken directly to the claim confirmation flow for that listing (Story 2.3.1 verification step)

---

## Epic 3: User Accounts & Authentication

<!-- Updated v3: Added passkeys evaluation note -->

> **Auth Note:** Passkey-based authentication (WebAuthn/FIDO2 passkeys) should be evaluated as the primary authentication mechanism for speakers, in place of traditional passwords. Passkeys offer a better UX (no password to remember, phishing-resistant) and align with modern security standards. Final decision deferred to Dallas and Ripley, but the architecture should not assume password-only auth. OAuth/social login (existing requirement) should remain supported alongside passkeys.

### Feature 3.1: Account Registration

**Description:** Allow speakers to create an account to access personalized features (tracked CFPs, notifications).

#### User Story 3.1.1: Create an Account

**As a** speaker  
**I want to** create an account with email and password  
**So that I can** track CFPs and receive notifications

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
**So that I can** access my tracked CFPs and notification settings

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

**Description:** Email notifications sent to users before CFP deadlines for tracked CFPs (Interested or Submitted status). Notification delivery is controlled by a global account-level toggle.

#### User Story 4.1.1: Receive Deadline Reminder

**As a** logged-in speaker  
**I want to** receive an email reminder before a tracked CFP's deadline  
**So that I don't** miss the submission window

**Acceptance Criteria:**

> ℹ️ **Decision 9 (Resolved):** Deadline reminders are controlled by a **global toggle only** (on/off in account settings). Per-CFP granularity is deferred to a future iteration.

- **Given** I have marked a CFP as Interested or Submitted with a deadline in 7 days
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
- **Then** I no longer receive deadline reminder emails for any tracked CFPs
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

<!-- Updated v3: Added Azure API Management (APIM) infrastructure note -->

> **Infrastructure Note:** All public and private APIs should be fronted by Azure API Management (APIM). APIM handles rate limiting (replacing any app-level rate limit logic), API key management, versioning, developer portal, and analytics. This is an architecture/implementation decision for Dallas and Parker — requirements documents here for traceability. Rate limits defined in Resolved Decision 3 remain the target limits; APIM will be the enforcement layer.

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
