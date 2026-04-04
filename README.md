# JobTracker

Version 1.0.0

A local-first macOS app for tracking job applications from your own folders. No cloud account, no paid API requirement, and no hidden background sync.

---

## License and allowed use

This project is released under the repository LICENSE as a non-commercial community license.

Allowed:
- Personal use
- Educational use
- Non-profit use
- Non-commercial forks with attribution

Not allowed without permission:
- Selling this app
- Commercial internal deployment
- Bundling into paid products/services

No warranty is provided. You are responsible for your own backups.

---

## Quick path (non-technical users)

If you do not code, use the release package instead of building from source.

### A) Download and install

1. Open this repository on GitHub.
  - https://github.com/Regan-Yin/JobTracker_Offer_Kitty
2. Go to Releases.
3. Download the latest file named like JobTracker-<version>-macOS.zip.
4. Unzip it.
5. Drag JobTracker.app into your Applications folder.
6. Open JobTracker.

If macOS blocks first launch:
1. Right-click JobTracker.app.
2. Click Open.
3. Confirm Open.

### B) First-time setup

1. On first launch, choose your JOB root folder.
2. Click scan/rescan.
3. Review detected companies and applications.
4. Confirm role names, stage, industry, and company size.
5. Start using Overview, Applications, Companies, and Exports.

---

## Recommended folder and file naming (important)

Detection quality is best when your files follow consistent structure.

### Recommended folder nesting

```text
JOB/
  Company Name/
    Role or Team Name/
      Cover Letter - Company - Role.docx
      Resume - Your Name.docx
```

Also supported:

```text
JOB/
  Company Name/
    Cover Letter - Data Analyst.docx
    Resume - Your Name.docx
```

### Cover letter naming tips

Use at least one keyword:
- Cover
- Cover Letter
- CL

Good examples:
- Cover Letter - Capital One - Business Analyst.docx
- CL - Shopify - Data Analyst.docx

### Resume naming tips

Use at least one keyword:
- Resume
- CV

Good examples:
- Resume - Regan.docx
- CV - Regan - 2026.docx

### Parser behavior notes

- .docx: full metadata + text extraction (best quality)
- .doc: metadata-focused fallback (lower confidence)
- If only resume exists and no cover letter: app creates one draft candidate and asks for confirmation

---

## How to use the app step-by-step

1. Choose materials root folder in onboarding or Settings.
2. Click Rescan folder.
3. Open review items with unresolved fields.
4. Confirm or edit:
   - Company name
   - Role title
   - Stage and outcome
   - Industry and company size
5. Use Applications and Companies tabs for manual edits.
6. Add reminders/tasks for follow-up.
7. Use Exports to generate CSV for your records.
8. Re-scan after you add new cover letters/resumes.

---

## Privacy and safety summary

- Data is local on your Mac.
- No telemetry or analytics SDK in this repo.
- No cloud sync for MVP.
- No hidden background upload pipeline.
- Optional feedback action opens your browser to GitHub Issues when email is unset.

Database location:
- ~/Library/Application Support/JobTracker/jobtracker.sqlite

---

## For advanced users (developers)

### Build from source

Requirements:
- macOS 14+
- Xcode 15+ or Swift 5.10+

Commands:

```bash
git clone <your-repo-url>
cd JobTracker_Offer_Kitty
swift package resolve
swift build
open .build/debug/JobTracker
```

### Package release app

```bash
chmod +x Scripts/package_mac_app.sh
./Scripts/package_mac_app.sh
```

Expected outputs:
- dist/JobTracker.app
- dist/JobTracker-<version>-macOS.zip

### Personalization points

- App bundle id: Scripts/package_mac_app.sh
- Icon assets and sizing: Resources plus Scripts/package_mac_app.sh
- Theme colors: Sources/JobTracker/Theme
- Role title cleanup rules: Sources/JobTracker/Core/Utilities/RoleTitleSanitizer.swift
- Feedback channel defaults: Sources/JobTracker/Features/Settings/SettingsView.swift

### Suggested improvement workflow

1. Open a GitHub Issue first for bug/feature discussion.
2. Add reproducible steps and screenshots.
3. Submit a focused pull request.
4. Keep changes aligned with job_tracker_mvp_cursor_spec.md.

---

## Bug reports and improvement requests

Please use GitHub Issues instead of direct email.

Issues page:
- https://github.com/Regan-Yin/JobTracker_Offer_Kitty/issues

Issue recommendations:
- Bug: include macOS version, app version, exact steps, expected vs actual behavior
- Feature request: describe use case and workflow impact
- UX issue: include screenshot/video

Security-related concerns:
- Use GitHub private security reporting if enabled
- Otherwise open an issue with minimal sensitive detail and ask for private follow-up

---

## Maintainer note

Maintainer email is intentionally left blank in source default to reduce spam.

If you are a recruiter and this project demonstrates relevant fit, you are welcome to check the maintainer GitHub profile.

The maintainer is actively job searching for roles such as:
- BA
- DS
- DE
- SDE

---

## Open-source release hygiene checklist

Before publishing source:

1. Ensure these are not committed:
   - .build/
   - dist/
   - local databases
   - local logs
2. Keep mailto recipient blank unless you explicitly want email feedback.
3. Confirm LICENSE matches intended non-commercial terms.
4. Verify README and SECURITY are consistent with actual behavior.
5. Build and run one clean release package from Scripts/package_mac_app.sh.

---

## Security reference

See SECURITY.md for the full security posture and reporting guidance.
