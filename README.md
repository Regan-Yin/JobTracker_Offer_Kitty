# JobTracker

**Version 1.0.0** — A **local-first macOS** app for tracking job applications: scan a folder of materials (`.docx` / `.doc`), organize **companies** and **applications** in **SQLite**, and use **Overview**, **Applications**, **Companies**, **Exports**, and **Settings** without cloud accounts or paid APIs.

---

## License and acceptable use (read this)

This project is shared for **non-profit, personal, and educational** use. **Commercial use is not permitted** without prior written permission from the author. See **[LICENSE](LICENSE)** for the full **JobTracker Non-Commercial Community License**.

- **Allowed:** Install, run, modify, and share the source for personal job hunting, learning, and good-faith non-commercial redistribution (e.g. your GitHub fork with attribution).
- **Not allowed without permission:** Selling the app, bundling it in a paid product or service, or using it as part of work-for-hire or internal tooling where the primary purpose is commercial advantage, as described in the license.

The MIT License text **does not** apply; the license file in this repository controls use. If you need a commercial license, contact the author.

**No warranty.** The software is provided **as-is**. You are responsible for your data and backups.

---

## What JobTracker does (product)

| Capability | Description |
|------------|-------------|
| **Materials root** | You choose a folder on disk; the app scans it for documents and builds structured records. |
| **Pipeline** | Companies, applications, stages, outcomes, notes, duplicates, exports. |
| **Analytics** | Overview dashboards and charts for your search. |
| **Privacy** | Data stays on your Mac (SQLite under Application Support). No vendor cloud for core features. |

**Out of scope (by design):** No email scraping, no LinkedIn automation, no paid third-party APIs for core functionality.

---

## Technical overview

| Layer | Choice |
|-------|--------|
| UI | SwiftUI |
| Persistence | SQLite via [GRDB](https://github.com/groue/GRDB.swift) |
| Documents | [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) for `.docx` handling |
| Build | Swift Package Manager, macOS 14+ |

Detailed product and technical notes: [`job_tracker_mvp_cursor_spec.md`](job_tracker_mvp_cursor_spec.md).

---

## Requirements

- **macOS 14+**
- **Xcode 15+** or Swift **5.10+** with Command Line Tools (for `swift build` and optional `actool` / `iconutil` when packaging)

---

## Quick start (from source)

```bash
git clone <your-repo-url>
cd <repository-folder>
swift package resolve
swift build
open .build/debug/JobTracker
```

Or open `Package.swift` in Xcode, select the **JobTracker** executable scheme, and run (**⌘R**).

### First launch

1. Choose a **JOB materials root** folder (optional shortcut if `~/Documents/JOB` or `~/Documents/JobMaterials` exists).
2. Run a **scan** from onboarding or **Settings → Rescan folder**.
3. Explore **Overview**, **Applications**, and **Companies**.

**Database location (your machine):**  
`~/Library/Application Support/JobTracker/jobtracker.sqlite`

---

## Packaging a `.app` and zip (optional)

See **[Scripts/package_mac_app.sh](Scripts/package_mac_app.sh)**. It builds a release binary, compiles icons from `Resources/Assets.xcassets`, writes `dist/JobTracker.app`, and zips it for testing.

```bash
chmod +x Scripts/package_mac_app.sh
./Scripts/package_mac_app.sh
```

Unsigned builds may require **Right-click → Open** the first time Gatekeeper prompts. Notarization is your responsibility if you distribute outside your own Mac.

---

## Security and privacy (no backdoors)

- **No analytics or telemetry** are implemented in this codebase.
- **No network calls** from the app for core features; your data stays local except when *you* open a **mailto:** link for feedback (the system Mail app).
- **Dependencies** are resolved via SwiftPM when you build (GRDB, ZIPFoundation from public GitHub).

For more detail: **[SECURITY.md](SECURITY.md)**.

---

## Configuration for maintainers and forks

| Item | Where |
|------|--------|
| Feedback email (`mailto`) | `Sources/JobTracker/Features/Settings/SettingsView.swift` — `FeedbackDistribution.mailtoRecipient` (default placeholder). |
| App bundle id (packaging) | `Scripts/package_mac_app.sh` — `BUNDLE_ID`. |
| Role title cleanup patterns | `Sources/JobTracker/Core/Utilities/RoleTitleSanitizer.swift`. |

Replace the placeholder email before publishing a build you expect others to use for feedback.

---

## Frequently asked questions

**Q: Is my data sent to the cloud?**  
A: No. SQLite lives under your user’s Application Support folder. You control backups (Time Machine, etc.).

**Q: Can I use this at my company?**  
A: Internal use at a for-profit company falls under **commercial / business use** in the license. You need **written permission** from the author for that, or use a different tool. Personal job search on your own machine is what this release targets.

**Q: Can I fork on GitHub?**  
A: Yes, for **non-commercial** sharing and modification, with license and copyright notice preserved.

**Q: Why does `actool` print `dyld` lines when packaging?**  
A: On some macOS versions the asset compiler still writes icons successfully; the script checks for output files. See comments in `Scripts/package_mac_app.sh`.

**Q: Gatekeeper says the app is from an unidentified developer.**  
A: Expected for unsigned builds. Use **Right-click → Open**, or sign and notarize with your own Apple Developer ID.

**Q: Where is feedback email delivered?**  
A: To whatever address you set in `FeedbackDistribution.mailtoRecipient`, via your default mail client. The default in source is a **placeholder** — change it for your fork.

---

## Contributing

Issues and pull requests are welcome for **non-commercial** improvements. Keep changes focused; match existing Swift style. Large features should align with [`job_tracker_mvp_cursor_spec.md`](job_tracker_mvp_cursor_spec.md).

---

## Author

**Regan** — JobTracker is shared as a **personal, non-profit** project. **Commercial use is prohibited** without explicit permission; see **[LICENSE](LICENSE)**.

If you find the app useful, a star on GitHub or a short note in your fork is appreciated.
