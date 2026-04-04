# Job Application Tracker MVP
## Product + Technical Specification for Cursor

**Target platform:** macOS only  
**Primary architecture:** local-first native desktop app  
**Target machine:** Apple Silicon MacBook (M1 Pro), macOS 15.7.3  
**Primary language:** Swift 5.10+ / SwiftUI  
**IDE / implementation environment:** VS Code + Cursor  
**Database:** SQLite  
**Distribution path:** local runnable build first, then signed `.app`, then optional `.dmg` / `.pkg` later  
**Design direction:** macOS-native professional, dark / graphite / slate / deep-blue premium visual language inspired by modern Sequoia aesthetics  

---

## 1. Executive Summary

Build a **local macOS job application tracking app** that scans a user-selected root folder containing job application materials, converts file signals into structured application records, lets the user confirm and correct those records, and provides dashboards, KPI tracking, reminders, CSV export, and manual editing.

The app must be:
- local-first
- low-memory
- fast to open
- simple to maintain
- fully usable without paid APIs
- open-source friendly
- safe for personal use without hidden services, background scraping, or external vendor lock-in

The app **does not include email ingestion in MVP**. Email-based ingestion is explicitly deferred to a future beta or later version.

---

## 2. Product Goal

Help a job seeker track applications in a structured way without relying on spreadsheets, while preserving the flexibility of manual control.

The app should answer these core user questions:
- How many applications have I sent?
- Which companies matter most to me?
- Which roles are active right now?
- Where am I failing most often in the funnel?
- Which companies need follow-up?
- How are my applications distributed across industries and company sizes?
- What has changed since the last time I opened the app?

---

## 3. MVP Scope

### In scope
- Native macOS app
- User-selectable root folder, with default suggestion:
  - Example: `~/Documents/JOB` or any folder you choose (not hardcoded)
- Recursive scan of nested subfolders under the selected root
- File support:
  - `.docx`: full metadata + text parsing
  - `.doc`: metadata only in MVP, no guaranteed full text parsing
- Auto-detection of:
  - companies
  - candidate applications
  - role names
  - supporting resume files
  - timestamps from file metadata
- Review & Map onboarding wizard
- Company mapping reuse
- Manual CRUD flows for all important records
- Duplicate suggestion with in-app notification and review sheet
- Raw data table with filters and inline edits
- Auto-save on all detail panels (debounced for text, immediate for pickers)
- Rich analytics dashboard with 8+ charts (funnel, industry, timeline, rejection analysis, etc.)
- Dashboards and KPI cards with conversion rates
- Internal reminders and notes
- CSV export
- Local SQLite storage
- Networking beta module: DB schema retained for future use, no UI in current version
- Secure local app preferences and optional sensitive storage separation

### Explicitly out of scope for MVP
- Email / Outlook / Microsoft Graph ingestion
- Azure / Entra integration
- LinkedIn automation or scraping
- Browser automation
- Selenium / BeautifulSoup workflow in MVP
- OCR
- Machine learning or LLM-based classification
- Cloud sync
- Multi-user support
- Multi-account mailbox support
- Real-time daemon-heavy background refresh

---

## 4. Product Principles

1. **Manual override always wins.**
2. **Detection should be conservative, not magical.**
3. **The app should suggest, never silently distort data.**
4. **Folder and file structure are signals, not truth.**
5. **User correction must be fast and pleasant.**
6. **Visual analytics should help decisions, not just decorate data.**
7. **Every important piece of app state must be stored locally.**
8. **Architecture must remain open-source friendly and free-of-cost.**

---

## 5. Final Scope Decisions Already Locked

### Data source
- Only locally accessible folder content under a user-selected root folder
- Default suggested root path:
  - Example: `~/Documents/JOB` or any folder you choose (not hardcoded)
- User must be able to pick another folder path in-app

### File rules
- Scan all nested subfolders recursively
- Ignore everything except `.docx` and `.doc`
- `.docx` may be parsed for text when needed
- `.doc` is metadata-only in MVP

### Application model
- Hybrid model:
  - **Application** is role-level
  - **Company** is aggregate-level

### Application detection rule
- Each distinct cover letter file = one detected application candidate
- Resume file is a supporting artifact, not the primary application counter
- If multiple role-specific cover letters exist in the same company folder, that company has multiple applications
- If there is only a resume and no cover letter, create **one draft application candidate** and ask the user to confirm

### Role inference rule
1. Subfolder name, if present
2. Cover letter filename
3. Strong role phrase in document text, especially formats similar to `Re: <Role Name>`
4. Fallback to `Unknown Role` and prompt user to edit

### Source-of-truth priority
1. Manual edit
2. Verified structured event
3. Email inference
4. File inference

> Note: Email inference is not active in MVP, but the priority order should still be preserved in architecture for future versions.

### Stage model
Use three separate fields:
- `current_stage`
- `outcome`
- `last_failed_stage`

### Required company mappings
- Industry
- Company size

### Reminder scope
- Internal reminders only for MVP
- No macOS local notifications in MVP

### Duplicate handling
- Suggest duplicates only
- Never auto-merge without confirmation
- User must be able to merge, ignore, or delete suggestions

### Importance scoring
- Automatic score + manual override
- Both company importance and application priority are required

---

## 6. Recommended Technical Stack

### Primary app stack
- **SwiftUI** for UI
- **AppKit bridging only where needed**
- **SQLite** for persistence
- **GRDB.swift** recommended as the SQLite wrapper
- **Swift concurrency** (`async/await`) for scan and parse tasks
- **FileManager** + `NSOpenPanel` for folder access
- **UniformTypeIdentifiers** for file typing
- **Security-scoped bookmarks** if sandboxing is later introduced

### DOCX parsing
Use a fully local approach.
Recommended options, in priority order:
1. Native unzip + XML extraction for `.docx`
2. Lightweight Swift package for ZIP/XML reading if it keeps the dependency tree clean

Reason:
- `.docx` is a ZIP container with XML inside
- This avoids external services and preserves open-source readiness

### `.doc` handling in MVP
- Read filename, path, created time, modified time
- Do not rely on full text extraction for `.doc`
- Mark inference confidence lower for `.doc`-based candidates

### Charts
- Native Swift Charts

### Export
- Standard CSV generation via Swift `String` / file write

### Logging
- Use `OSLog`

### Preferences / sensitive storage
- Standard app settings in `UserDefaults`
- Sensitive tokens reserved for future versions in Keychain
- MVP has no remote tokens, but architecture should isolate secrets cleanly

---

## 7. High-Level Architecture

Use a modular structure.

### Suggested modules
1. **App Shell**
   - app lifecycle
   - settings
   - theme
   - navigation

2. **Folder Access Module**
   - root folder selection
   - recursive listing
   - path filtering
   - file metadata gathering

3. **Document Parsing Module**
   - `.docx` text extraction
   - filename classification
   - artifact classification (cover letter vs resume vs unknown)
   - role-name inference

4. **Ingestion Pipeline Module**
   - raw scan items
   - normalization
   - candidate company creation
   - candidate application creation
   - confidence scoring
   - duplicate suggestion generation

5. **Persistence Module**
   - SQLite schema
   - migrations
   - repositories
   - indexing

6. **Mapping + Review Module**
   - onboarding wizard
   - company mapping reuse
   - stage confirmation
   - unresolved item queue

7. **Manual Editing Module**
   - add company
   - add application
   - add event
   - edit / merge / ignore

8. **Dashboard Module**
   - KPI calculations
   - funnel analytics
   - stage analysis
   - time series
   - category analysis

9. **Reminder Module**
   - internal reminders
   - due / overdue state
   - task views

10. **CSV Export Module**
    - filtered export
    - full event export

11. **Networking Beta Module**
    - manual contacts
    - relationship tracking
    - company linkage
    - coffee chat tracking

---

## 8. Data Model

Design the model so that companies, applications, events, reminders, mappings, and documents are separated cleanly.

## 8.1 Core Entities

### Company
Represents one employer or target organization.

Fields:
- `id` (UUID)
- `normalized_name` (unique-friendly normalized value)
- `display_name`
- `industry_category`
- `company_size_category`
- `importance_score_auto` (0–100)
- `importance_score_manual_override` (nullable)
- `importance_tier` (`Low`, `Medium`, `High`, `Critical`)
- `notes`
- `mapping_status` (`unmapped`, `mapped`, `needs_review`)
- `created_at`
- `updated_at`
- `last_activity_at`
- `is_ignored`

### Application
Represents one role-level application.

Fields:
- `id` (UUID)
- `company_id` (FK)
- `role_title`
- `department_name` (nullable)
- `current_stage`
- `outcome`
- `last_failed_stage` (nullable)
- `application_time`
- `priority_score_auto` (0–100)
- `priority_score_manual_override` (nullable)
- `priority_tier` (`Low`, `Medium`, `High`, `Critical`)
- `source_type` (`auto_detected`, `manual_input`, `mixed`)
- `confidence_score` (0–100)
- `status_needs_review` (bool)
- `notes`
- `created_at`
- `updated_at`
- `last_activity_at`
- `is_draft_candidate`
- `is_ignored`

### DocumentArtifact
Represents one scanned file.

Fields:
- `id` (UUID)
- `company_id` (nullable until resolved)
- `application_id` (nullable until resolved)
- `file_path`
- `file_name`
- `file_extension`
- `parent_folder_name`
- `relative_path_from_root`
- `document_type` (`cover_letter`, `resume`, `unknown`)
- `text_extract_status` (`not_attempted`, `success`, `failed`, `unsupported`)
- `text_extract_preview` (nullable, short stored snippet only)
- `created_time`
- `modified_time`
- `last_scanned_at`
- `content_hash` (optional, recommended)
- `is_deleted_from_disk` (bool)

### EventLog
Represents an app event or application activity.

Fields:
- `id` (UUID)
- `company_id` (nullable)
- `application_id` (nullable)
- `event_type`
- `event_time`
- `event_source` (`system`, `manual`, `scan`, `merge`, `mapping`)
- `title`
- `details`
- `created_at`

### Reminder
Represents a manual follow-up or task.

Fields:
- `id` (UUID)
- `company_id` (nullable)
- `application_id` (nullable)
- `title`
- `note`
- `due_at`
- `status` (`open`, `completed`, `dismissed`, `overdue`)
- `created_at`
- `updated_at`
- `completed_at` (nullable)

### DuplicateSuggestion
Represents possible duplicates.

Fields:
- `id` (UUID)
- `entity_type` (`company`, `application`)
- `left_entity_id`
- `right_entity_id`
- `reason`
- `score`
- `status` (`pending`, `merged`, `ignored`, `resolved_manually`)
- `created_at`
- `updated_at`

### NetworkingContact (Beta)
Represents a manually tracked networking contact.

Fields:
- `id` (UUID)
- `full_name`
- `company_id` (nullable)
- `job_title`
- `linkedin_url` (nullable)
- `relationship_type` (`alumni`, `employee`, `recruiter`, `manager`, `peer`, `other`)
- `last_contact_at` (nullable)
- `coffee_chat_status` (`none`, `planned`, `completed`, `follow_up_needed`)
- `follow_up_due_at` (nullable)
- `notes`
- `created_at`
- `updated_at`

### CompanyMappingPreset
Stores reusable mapping choices.

Fields:
- `company_normalized_name`
- `industry_category`
- `company_size_category`
- `last_confirmed_at`

---

## 8.2 Enumerations

### Current stage
- Submitted
- OA / Assessment
- Recruiter Screen
- Hiring Manager / Line Manager
- First Round Interview
- Second Round Interview
- Final Round
- Case / Technical / Presentation
- Reference Check
- Offer
- Rejected
- Ghosted / No Response
- Closed / Unknown

### Outcome
- Active
- Rejected
- Offered
- Withdrawn
- Closed

### Last failed stage
Nullable. Same logical options as the interview / screening path.
Recommended allowed values:
- OA / Assessment
- Recruiter Screen
- Hiring Manager / Line Manager
- First Round Interview
- Second Round Interview
- Final Round
- Case / Technical / Presentation
- Reference Check

### Industry category
- Technology / SaaS
- Financial Services
- Banking / Capital Markets
- Consulting
- Retail / Consumer
- E-commerce
- Healthcare
- Education
- Government / Public Sector
- Energy / Utilities
- Industrial / Manufacturing
- Transportation / Logistics
- Media / Entertainment
- Real Estate
- Nonprofit
- Other

### Company size
- Startup
- Small Business
- Mid-Market
- Enterprise
- Publicly Listed
- Government / Crown Corp
- Nonprofit / NGO
- Unknown

### Event types
- Auto-detected from file scan
- Manual application added
- Stage updated
- Interview scheduled
- Interview completed
- OA assigned
- OA completed
- Rejected received
- Offer received
- Follow-up note added
- Reminder created
- Duplicate merged
- Record ignored

---

## 9. Database Design Notes

### Recommended database approach
- SQLite database file stored in app support directory
- Use migrations from day one
- Index all commonly filtered fields

### Recommended indexes
- `companies.normalized_name`
- `applications.company_id`
- `applications.current_stage`
- `applications.outcome`
- `applications.application_time`
- `artifacts.file_path`
- `artifacts.modified_time`
- `events.application_id`
- `reminders.due_at`

### Deletion policy
Use soft deletion or ignore flags where user history matters.

Recommended:
- Applications: soft ignore instead of hard delete by default
- Artifacts: keep record even if missing from disk, mark `is_deleted_from_disk = true`
- Events: append-only where possible

---

## 10. File Ingestion Rules

## 10.1 Root folder selection
- On first launch, prompt the user to select the JOB root folder
- Suggest the default known path if it exists
- Save the selected path in settings
- Allow re-selection later in Settings

## 10.2 Recursive scan rules
- Traverse all nested folders under the chosen root
- Only keep `.docx` and `.doc`
- Ignore hidden files
- Ignore temporary office files such as names beginning with `~$`
- Track relative path for inference

## 10.3 Artifact classification rules

### Cover letter detection heuristic
Mark a document as likely `cover_letter` if one or more of these are true:
- filename contains keywords like `cover`, `cover letter`, `cl`
- filename contains a role-like string and is not clearly a resume
- document text contains greeting / cover letter structure
- document text contains `Re:` or similar role header
- document text contains hiring intent language such as `I am writing to apply`

### Resume detection heuristic
Mark a document as likely `resume` if one or more are true:
- filename contains `resume`, `cv`
- filename pattern suggests personal profile doc
- document text has typical resume sections such as `Experience`, `Education`, `Skills`

### Unknown fallback
If not confident, classify as `unknown` and send to review queue.

---

## 11. Company Detection Rules

A company is usually inferred from folder structure.

### Recommended default logic
Assume the first child folder under the JOB root is the company bucket.

Example:
- `JOB/Capital One/...` → company = `Capital One`
- `JOB/Capital One/Analytics/Role A Cover Letter.docx` → company = `Capital One`, department maybe `Analytics`

### Company inference fallback
1. First-level folder name under root
2. If not available, nearest meaningful folder name
3. Filename hints
4. User confirmation during onboarding

### Normalization
Normalize company names for matching:
- trim whitespace
- collapse duplicate spaces
- lowercase for comparison
- remove common punctuation noise

Do **not** over-aggressively merge legally distinct names automatically.

---

## 12. Application Detection Rules

## 12.1 Core detection
- Each distinct cover letter file = one application candidate

## 12.2 Resume-only case
- If a company folder contains resume files but no cover letter files:
  - create one `draft application candidate`
  - mark `is_draft_candidate = true`
  - require user confirmation in onboarding / unresolved queue

## 12.3 Multiple applications under same company
If there are multiple distinct cover letters in the same company folder:
- create multiple applications
- attempt role disambiguation
- link shared resume artifacts if appropriate

## 12.4 Shared resume behavior
- A single resume can support multiple applications under the same company
- Resume presence increases company importance, but does not count as multiple applications by itself

---

## 13. Role Name Inference Rules

Role detection should use a cascading strategy with confidence scoring.

### Ordered inference logic
1. **Subfolder name** if it clearly looks like a department or role bucket
2. **Cover letter filename**
3. **Cover letter text extraction** looking for high-signal phrases
4. Fallback to `Unknown Role`

### Text-based signals to detect
Look for patterns like:
- `Re: <Role Name>`
- `Position: <Role Name>`
- `Application for <Role Name>`
- `applying for the <Role Name> position`
- `the <Role Name> role`

### Confidence strategy
Assign rough confidence levels:
- 90–100: exact strong text/header signal
- 70–89: clean filename / subfolder signal
- 40–69: weak filename guess
- below 40: unresolved, prompt user

### Manual correction requirement
If confidence is below threshold, show `Unknown Role` or tentative value in onboarding and require a quick confirmation.

---

## 14. Timestamp Rules

### Application time fallback
Use:
1. cover letter modified time nearest to the candidate application
2. resume modified time if there is no cover letter
3. manual user override

For MVP, use **last modified time** as the inferred submission time unless manually corrected.

Store both:
- raw file times
- chosen application time

---

## 15. Importance and Priority Scoring

The app needs two different concepts.

## 15.1 Company Importance Score
Represents strategic attention / seriousness toward the company.

### Recommended automatic factors
- company folder exists: base score
- one or more resume files exists
- one or more cover letters exists
- more than one detected application for the same company
- company has mapped industry / size completed
- company has recent activity
- company has any OA, interview, or offer event

### Suggested example weight model
- base company folder: +10
- resume exists: +15
- cover letter exists: +20
- 2+ applications: +15
- 3+ applications: additional +10
- recent activity within 14 days: +10
- any OA/interview event: +15
- offer event: +20
- rejection only / closed history: +5 historical only, do not inflate too much

Clamp to `0–100`.

### Importance tiers
- 0–24 = Low
- 25–49 = Medium
- 50–74 = High
- 75–100 = Critical

### Manual override
Allow the user to override importance tier or score.
Manual override must be visible and reversible.

## 15.2 Application Priority Score
Represents urgency and actionability for a specific role.

### Recommended automatic factors
- stage is active
- OA pending
- interview upcoming
- reminder overdue
- recent stage change
- final round or offer
- unresolved / needs review state

### Suggested example weight model
- submitted active: +20
- OA / Assessment active: +45
- recruiter screen / hiring manager active: +50
- first or second round active: +60
- final round: +75
- offer: +100
- reminder overdue: +15
- status needs review: +10
- closed / rejected: reduce priority strongly unless reminder exists

Clamp to `0–100`.

### Display
Show both:
- numeric score
- tier label

---

## 16. Onboarding and First-Run Flow

Use the following exact flow.

## Step 1: Folder selection
- show welcome screen
- allow user to select root folder
- suggest known default path if found

## Step 2: Scan and candidate generation
- scan recursively
- classify artifacts
- infer companies
- infer applications
- calculate confidence and unresolved flags

## Step 3: Review & Map Wizard
For each unresolved company/application, prompt user to confirm:
- company name
- detected applications
- role names
- current stage
- outcome if known
- last failed stage if applicable
- industry
- company size

## Step 4: Save confirmed records
- write clean normalized records into database
- store raw artifacts and event logs

## Step 5: Show dashboard
- KPI cards
- recent changes
- records needing review
- reminders panel

### UX requirements for the wizard
- must be fast, keyboard friendly, and not overwhelming
- use inline suggestions
- show grey placeholder hint text in inputs
- reuse prior mappings automatically
- if the company was mapped before, prefill industry and size immediately

---

## 17. Main Screens and Navigation

Recommended sidebar navigation:
- Overview
- Applications
- Companies
- Tasks (Reminders)
- Exports
- Settings

> Note: Activity and Networking Beta are deferred from the sidebar. Activity events are shown in the Overview recent activity feed. Networking DB schema is retained for future use.

## 17.1 Overview
Contains:
- KPI cards (total, active, companies, offers, rejections, withdrawn, conversion rates, needs review)
- Duplicate notification banner (with review sheet)
- Applications by stage chart
- Outcome distribution donut chart
- Applications by industry chart
- Applications by company size chart
- Rejections by failed stage chart
- Top companies by application count chart
- Pipeline funnel chart (Applied → OA → Screen → Interview → Final → Offer)
- Applications over time line chart (monthly)
- Outcome by industry grouped chart
- Recent activity timeline

## 17.2 Applications
Primary raw data management screen.

Requirements:
- table/grid layout
- filter by company, stage, outcome, industry, size, source type, date range
- sort by application time, priority, last activity, company
- inline edit support where reasonable
- row detail panel or drawer
- bulk actions where safe

Columns should include at minimum:
- application time
- company name
- role title
- department
- current stage
- outcome
- last failed stage
- company importance
- application priority
- industry
- company size
- source type
- notes indicator
- reminder indicator
- needs review flag

## 17.3 Companies
Requirements:
- company list with grouping / filtering
- importance tier
- number of applications
- mapped industry / size
- latest activity
- linked artifacts count
- detail pane showing all role applications under that company

## 17.4 Activity
> **Deferred as standalone screen.** Activity events are displayed in the Overview's recent activity feed. A dedicated Activity screen may be added in a future version.

## 17.5 Tasks (Reminders)
Requirements:
- new reminder form
- reminders list (non-completed)
- mark reminder as done

> Note: Duplicate suggestions are surfaced via the Overview duplicate notification banner and review sheet, not in the Tasks view.

## 17.6 Networking Beta
> **Deferred.** See section 22. No UI in current version.

## 17.7 Exports
Requirements:
- export filtered applications to CSV
- export filtered companies to CSV
- export full event log to CSV
- preview export count before writing file

## 17.8 Settings
Requirements (as implemented):
- **Materials folder:** display path, **Choose folder…**, **Rescan folder**
- **Appearance:**
  - **Accent theme:** four presets — Midnight, Sequoia, Ocean, Slate (no separate “Arctic” swatch)
  - **Light / Dark:** app-level appearance mode stored in preferences; **independent of macOS system light/dark**; combined with accent to drive `JobTrackerTheme` and `preferredColorScheme` for native controls
  - **No** desktop background / wallpaper image behind the UI (removed from product)
- **Feedback & Suggestions:** submit (mailto), save drafts, list drafts, **delete draft** (with confirmation), submitted count
- **About:** version, credits, license summary
- **Database:** show on-disk SQLite path (`~/Library/Application Support/JobTracker/jobtracker.sqlite`)
- Parsing rules / import-export settings: placeholder for future advanced config

---

## 18. Dashboard Requirements

Use grouped dashboards as confirmed.

## 18.1 Consolidated Overview Dashboard
All analytics are consolidated into the single Overview screen.

KPI cards:
- Total applications
- Active applications
- Distinct companies applied
- Offers
- Rejections
- Withdrawn
- App → Interview conversion rate
- Interview → Offer conversion rate
- Needs review count

Charts (all Swift Charts, rendered in 2-column grid + full-width):
- Applications by stage (bar)
- Outcome distribution (donut/sector)
- Applications by industry (horizontal bar)
- Applications by company size (horizontal bar)
- Rejections by failed stage (horizontal bar)
- Top companies by application count (horizontal bar, top 15)
- Pipeline funnel (horizontal bar, Applied → OA → Screen → Interview → Final → Offer)
- Applications over time (line + area, monthly)
- Outcome by industry (grouped bar)

Also includes:
- Duplicate notification banner with review sheet
- Recent activity feed (last 12 events)

> Note: Pipeline, Company Insights, and Timeline dashboards from the original spec are consolidated into the single Overview screen for simplicity.

### Chart implementation note
Use Swift Charts only. Keep visuals clean, native, and performant.

---

## 19. Manual Input and Editing Requirements

The app must allow full manual correction because auto-detection is intentionally conservative.

User must be able to:
- add company
- add application
- add event/activity
- edit any auto-detected field
- merge duplicate companies
- merge duplicate applications
- mark wrong auto-detected events as ignored
- override status manually
- add notes
- add follow-up reminders

### Auto-save behavior
Detail panels for applications and companies use auto-save:
- Text field changes (role title, display name, notes) are saved with 800ms debounce after the last keystroke
- Picker changes (stage, outcome, industry, company size) are saved immediately on change
- A transient "Saved" indicator appears briefly after each save
- No explicit Save button is needed
- Unsaved changes are flushed on view disappear (selection change)

### Delete behavior (destructive)
- **Application detail:** user can **Delete application…** with a **confirmation alert**; persists via `JobStore.deleteApplication`; list selection clears after delete
- **Company detail:** user can **Delete company…** with a **confirmation alert** explaining that linked applications are removed (DB **cascade** on `applications.companyId`); list selection clears after delete
- **Feedback drafts:** delete from draft list or from the feedback editor, each with **confirmation** where appropriate

### Source tagging
All records should preserve origin metadata.

Use values such as:
- `auto_detected`
- `manual_input`
- `mixed`

This must be visible in raw data views.

---

## 20. Duplicate Suggestion Logic

Do not auto-merge. Suggest only.

### Company duplicate suggestion heuristics
- same normalized display name
- highly similar normalized display name
- same folder root pattern

### Application duplicate suggestion heuristics
- same company + same role title
- same company + same modified-time cluster + same cover letter filename
- same company + highly similar role strings + near-identical timestamps

### UX requirement
For each duplicate suggestion, user can:
- merge records
- ignore suggestion
- delete incorrect record manually
- edit and keep both

### Merge behavior
When merging:
- preserve all linked artifacts
- preserve all events
- preserve manual notes
- keep most trusted values according to source priority

---

## 21. CSV Export Requirements

Must support:
- filtered applications export
- filtered companies export
- full event log export

### CSV implementation requirements
- use current filters from the UI
- include column headers
- use ISO 8601 timestamps where applicable
- properly escape commas and quotes
- let user choose save location with native macOS save panel

---

## 22. Networking Beta Module

> **Status: Deferred.** The networking beta UI is not included in the current version. The database table (`networking_contacts`) and record struct (`NetworkingContactRecord`) are retained for backward compatibility and future development. No sidebar entry or views are exposed.

### Future scope (when re-enabled)
- manual contact creation only
- link contact to company
- relationship type, coffee chat tracking
- follow-up due dates
- no LinkedIn auth or scraping

---

## 23. Refresh and Performance Requirements

### Refresh behavior
Use:
- refresh on app open
- manual rescan button
- optional lightweight refresh hook later, but not required in MVP

### Performance rules
- no constant polling
- do not run heavy background workers
- use incremental scan when possible
- cache scan metadata and compare modified times / hashes before reparsing
- keep startup responsive even on large folders

### Recommended scan strategy
1. quick file inventory pass
2. identify changed/new files only
3. parse only changed `.docx` files as needed
4. update derived records

---

## 24. Theme and UX Style Guide

### Visual direction
- **Default:** dark-friendly palettes; user may switch to **light** per app setting (not tied to system appearance)
- macOS-native professional appearance
- graphite / deep gray base in dark mode; light neutrals in light mode
- restrained accent per theme family (Midnight / Sequoia / Ocean / Slate)
- soft translucency where appropriate, but do not overuse blur
- premium but calm, not flashy
- **No** full-window custom background image behind content (removed; solid themed background only)

### UX principles
- keyboard-friendly
- compact but readable tables
- spacious detail drawers
- clear chip/tier labels for stages, outcomes, and priorities
- use placeholder hint text in gray for mapping inputs
- reuse previous mappings with type-ahead suggestions

### Suggested UI patterns
- sidebar + content area
- segmented controls where natural
- inspector panel / detail drawer on the right for selected row
- confirmation sheets for merge / delete actions

---

## 25. Error Handling and Trust

The app must clearly distinguish between:
- detected fact
- low-confidence guess
- manual user input
- unresolved field

### Examples
- Unknown role should remain visible as unresolved instead of faking confidence
- `.doc` parsing limitation should be visible in status or tooltip
- if a file disappears from disk, do not silently delete history

### Trust UI ideas
- confidence badge per application candidate
- `Needs Review` label
- origin label: auto/manual/mixed

---

## 26. Open-Source-Friendly Constraints

The project must be built with the assumption that it may later be published on GitHub.

Requirements:
- no paid APIs
- no hidden telemetry
- no backdoor services
- no proprietary external dependency required for core functionality
- all parsing and storage local only
- root path must be configurable, never hardcoded into app logic
- category lists should be seed data, not buried in UI-only code
- architecture must allow contributors to extend parsers later

### Distribution bundle and app icon (as implemented)

- **SwiftPM** builds a command-line executable; **`Scripts/package_mac_app.sh`** produces a double-clickable **`JobTracker.app`** under **`dist/`** (release binary, `Info.plist`, resources) and a **`JobTracker-<version>-macOS.zip`** for copying to another Mac for testing.
- **Icons:** `Resources/Assets.xcassets/AppIcon.appiconset/` merges **light** and **dark** macOS icon PNGs (dark entries use `appearances` / luminosity `dark`). **`xcrun actool`** compiles the catalog to **`AppIcon.icns`** and **`Assets.car`** in the app bundle so Finder can show the correct icon for light vs dark desktop appearance.
- **Signing:** ad-hoc / unsigned by default; notarization is optional for wider distribution.

---

## 27. Project Structure Recommendation

Suggested repository layout:

```text
JobTracker/
  App/
    JobTrackerApp.swift
    AppRouter.swift
  Core/
    Models/
    Enums/
    Utilities/
    Extensions/
  Data/
    Database/
      Migrations/
      Repositories/
    Parsers/
      DOCX/
      DOC/
      Classification/
    Scanners/
    Importers/
  Features/
    Onboarding/
    Overview/
    Applications/
    Companies/
    Activity/
    Tasks/
    Networking/
    Exports/
    Settings/
  Services/
    FolderAccess/
    Ingestion/
    Duplicates/
    Scoring/
    Reminders/
    Export/
    Logging/
  Resources/
    SeedData/
    Themes/
  Tests/
    Unit/
    Integration/
    Snapshot/
```

---

## 28. Implementation Plan

## Phase 0: Foundation
Deliverables:
- app shell
- sidebar navigation scaffold
- theme baseline
- SQLite setup with migrations
- base models and repositories
- root folder selection

## Phase 1: File scanning + raw ingestion
Deliverables:
- recursive file scanner
- `.docx` and `.doc` inventory
- artifact classification
- basic company inference
- application candidate generation
- unresolved queue

## Phase 2: Onboarding wizard + mapping
Deliverables:
- Review & Map Wizard
- company mapping reuse
- role confirmation
- stage / outcome / failed-stage mapping
- save confirmed data

## Phase 3: Raw data management
Deliverables:
- applications table
- companies table
- activity log
- manual add/edit flows
- duplicate suggestion UI
- merge actions

## Phase 4: Dashboards + reminders
Deliverables:
- KPI cards
- overview dashboard
- funnel views
- company insights
- timeline charts
- reminders / tasks screen

## Phase 5: CSV export + networking beta
Deliverables:
- filtered CSV export
- event log export
- manual networking module

## Phase 6: Packaging and polish
Deliverables:
- app icon
- menu polish
- crash-safe behaviors
- performance tuning
- signed app packaging later

---

## 29. Acceptance Criteria

The MVP is successful if all of the following are true:

1. User can launch the macOS app normally.
2. User can choose a root folder.
3. App scans nested folders and detects `.docx` / `.doc` artifacts.
4. App can identify likely cover letters and resumes.
5. App can generate application candidates from file structure.
6. App can reuse company-level mapping fields.
7. User can confirm and edit all important fields in onboarding.
8. User can add and edit applications manually after onboarding.
9. User can track `current stage`, `outcome`, and `last failed stage`.
10. User can merge duplicates only after explicit confirmation.
11. Dashboard KPI cards update after rescan or manual changes.
12. User can create internal reminders and notes.
13. User can export filtered applications / companies and full event log as CSV.
14. App runs locally without any paid service or external API dependency.
15. App remains responsive during normal use on an M1 Pro Mac.

---

## 30. Testing Requirements

### Unit tests
Must cover:
- company normalization
- artifact classification heuristics
- role name inference heuristics
- importance scoring
- priority scoring
- duplicate suggestion logic
- CSV escaping and export

### Integration tests
Must cover:
- folder scan → candidate generation → onboarding save
- manual edit after auto-detection
- duplicate merge flows
- rescan with modified files
- reminder creation and completion

### UX / manual QA scenarios
- company with one cover letter and one resume
- company with many cover letters for multiple roles
- company with resume only
- company with duplicate role files
- unknown role fallback case
- `.doc` metadata-only case
- missing file after previous scan
- mapped company reused in later scan

---

## 31. Risks and Mitigations

### Risk 1: messy filenames
Mitigation:
- conservative inference
- unresolved queue
- manual correction first-class

### Risk 2: `.doc` parsing inconsistency
Mitigation:
- metadata-only support in MVP
- clearly label unsupported text extraction

### Risk 3: duplicate ambiguity
Mitigation:
- suggest only, no silent merge

### Risk 4: excessive UI complexity
Mitigation:
- prioritize fast table + detail drawer patterns
- keep beta networking isolated

### Risk 5: large folder scan latency
Mitigation:
- incremental scan design
- modified-time / hash checks
- async parsing pipeline

---

## 32. Packaging and Distribution Notes

### Development and local testing
- no Apple Developer account required for local builds on own machine

### Sharing with other users
- unsigned app can work for testing but may trigger Gatekeeper warnings
- smoother distribution usually requires Apple Developer signing and notarization

### Recommended release path
1. local build and self-test
2. unsigned internal beta for controlled testers
3. signed `.app`
4. optional notarized `.dmg` or `.pkg`

---

## 33. Future Version Hooks

Not for MVP, but architecture should leave room for:
- Outlook / email ingestion
- email rules or mailbox import
- richer `.doc` handling
- local notifications
- smarter classification profiles
- LinkedIn-assisted import with explicit user action
- plugin parser system
- optional encrypted database

---

## 34. Cursor Execution Instructions

Use this project policy when implementing in Cursor:

### Engineering rules
- Prefer simple local implementations over clever abstractions
- Do not introduce paid APIs or hidden services
- Keep all data flows inspectable and testable
- Use migrations from the first database version
- Build UI incrementally and test each screen end-to-end
- Preserve manual override behavior in every layer
- Never auto-merge records without user confirmation
- Never invent role names or stages when confidence is too low

### Implementation order for Cursor
1. Scaffold app + DB + folder picker
2. Build artifact scanner and persistence
3. Implement `.docx` parser and artifact classifier
4. Build application candidate generation
5. Build onboarding wizard
6. Build applications and companies tables
7. Build duplicate suggestion system
8. Build dashboards and KPIs
9. Build reminders and exports
10. Build networking beta
11. Polish theme and packaging

### Definition of done for each feature
Every feature is only done when it has:
- working UI
- persisted data
- basic error handling
- at least one test or validation scenario
- no silent data corruption risk

---

## 35. Final MVP Statement

The MVP is a **premium-feeling, local macOS application tracker** built in Swift/SwiftUI that transforms a folder of job materials into a structured, editable application database with dashboards and reminders.

It should feel better than a spreadsheet, safer than a browser automation tool, and simpler than a full ATS.

The product priority order is:
1. trustworthy local ingestion
2. fast manual correction
3. useful analytics
4. polished native UX
5. extensible architecture for future beta features

---

## 36. Public Open-Source Compliance Checklist (Release Gate)

Before any public source release, verify all of the following:

### Repository hygiene
- `.build/` is not tracked
- `dist/` is not tracked
- no local SQLite data files are tracked
- no macOS metadata clutter (`.DS_Store`) is tracked
- no personal exports or private notes are tracked

### Sensitive content checks
- no hardcoded credentials, API keys, or private tokens
- no personal email addresses unless intentionally published
- no absolute local machine paths in source/runtime defaults
- no hidden or undocumented network endpoints

### Runtime behavior checks
- app can run fully offline for core workflows
- app does not transmit data silently
- any user-triggered outbound action is explicit and documented (for example GitHub issue page or optional mailto flow)

### Documentation consistency
- README install and usage steps match actual UI flow
- LICENSE terms are visible and clear for non-commercial use
- SECURITY statement matches current code behavior

---

## 37. End-User Folder and Naming Guidance (Operational)

For best detection quality in production use, recommend this structure:

```text
JOB/
  Company Name/
    Role or Team/
      Cover Letter - Company - Role.docx
      Resume - Candidate Name.docx
```

### Naming recommendations
- Cover letter file should include one of: `cover`, `cover letter`, `cl`
- Resume file should include one of: `resume`, `cv`
- Include role text in cover letter filename when possible

### Why this matters
- company inference mainly uses first-level folder under root
- role inference uses subfolder name + cover filename + `.docx` text signals
- clear naming increases confidence and reduces manual cleanup workload

### End-user step-by-step flow
1. select JOB root folder
2. run scan
3. review unresolved candidates
4. confirm company, role, stage, outcome, mapping fields
5. use dashboard + reminders
6. export CSV as needed

### MVP parser expectations
- `.docx` is the preferred format for quality
- `.doc` is supported with limited extraction confidence
- resume-only company folders produce draft candidates that need confirmation

