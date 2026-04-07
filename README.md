# JobTracker

**Version 1.0.0** — A **local-first macOS** app for tracking job applications: scan a folder of materials (`.docx` / `.doc`), organize **companies** and **applications** in **SQLite**, and use **Overview**, **Applications**, **Companies**, **Exports**, and **Settings** without cloud accounts or paid APIs.

---

## License

This project is licensed under the **MIT License**. See **[LICENSE](LICENSE)** for the full text.

- **Allowed:** Use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the software.
- **Required:** Include the copyright notice and license text in substantial portions of the software.
- **No warranty:** The software is provided **as-is**.

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
- **Xcode 15+** or Swift **5.10+** with Command Line Tools (for `swift build`; packaging normalizes icon visual size and generates `AppIcon.icns`)

---

## Quick start (from source)

```bash
git clone https://github.com/Regan-Yin/JobTracker_Offer_Kitty.git
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

See **[Scripts/package_mac_app.sh](Scripts/package_mac_app.sh)**. It builds a release binary and uses this icon priority:
- **`AppIcon.appiconset` + `actool`** (Cursor-like asset catalog workflow, preferred)
- **`AppIcon.iconset`** (normalized, then converted to `.icns`)
- **`AppIcon.icns`** (normalized and rebuilt)

Then it writes `dist/JobTracker.app` and zips it for testing.

```bash
chmod +x Scripts/package_mac_app.sh
./Scripts/package_mac_app.sh
```

Icon source options:
- Put an app icon set at **`Resources/AppIcon/AppIcon.appiconset`** (recommended, Cursor-like workflow).
- Or provide **`Resources/AppIcon/AppIcon.iconset`**.
- Or keep using **`Resources/AppIcon/AppIcon.icns`**.

Optional overrides:
- **`APPICON_APPICONSET_PATH=/path/to/AppIcon.appiconset ./Scripts/package_mac_app.sh`**
- **`APPICON_ICONSET_PATH=/path/to/AppIcon.iconset ./Scripts/package_mac_app.sh`**
- **`APPICON_ICNS_PATH=/path/to/icon.icns ./Scripts/package_mac_app.sh`**
- **`APPICON_DARK_ICNS_PATH=/path/to/icon-dark.icns ./Scripts/package_mac_app.sh`**
- **`APPICON_CONTENT_SCALE=0.82 ./Scripts/package_mac_app.sh`** (lower = more margin, appears smaller)
- **`APPICON_USE_ACTOOL=always|auto|never ./Scripts/package_mac_app.sh`**

See **`Resources/AppIcon/README.txt`**.

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
| Dock / Finder icon | `Scripts/package_mac_app.sh` prefers `AppIcon.appiconset` (asset catalog). Fallback path normalizes/rebuilds `AppIcon.icns`. |

Replace the placeholder email before publishing a build you expect others to use for feedback.

Default public setup in this repository keeps email blank and uses GitHub Issues:
- https://github.com/Regan-Yin/JobTracker_Offer_Kitty/issues

---

## Frequently asked questions

**Q: Is my data sent to the cloud?**  
A: No. SQLite lives under your user’s Application Support folder. You control backups (Time Machine, etc.).

**Q: Can I use this at my company?**  
A: Yes. The MIT License permits commercial and internal business use.

**Q: Can I fork on GitHub?**  
A: Yes. MIT allows forking and redistribution, including commercial use, as long as license and copyright notices are preserved.

**Q: Gatekeeper says the app is from an unidentified developer.**  
A: Expected for unsigned builds. Use **Right-click → Open**, or sign and notarize with your own Apple Developer ID.

**Q: Where is feedback email delivered?**  
A: In this public repo, default behavior opens GitHub Issues. If you set `FeedbackDistribution.mailtoRecipient`, feedback can also open your default mail client with prefilled content.

**Q: Why doesn’t the Dock icon match the Light/Dark toggle inside Settings?**  
A: The appearance toggle only changes window colors (`JobTrackerTheme`). Icon style is separate. In Settings you can manually choose System/Light/Dark icon mode; the app reminds you that icon mode applies after restart.

**Q: Can I ship separate light and dark Dock icons?**  
A: Yes, when using `AppIcon.appiconset` with `actool` (the script now prefers this). If you package with fallback `.icns` flow, output is one icon file per build.

**Q: The icon still looks large or cramped vs apps like Cursor.**  
A: Tune **`APPICON_CONTENT_SCALE`** when packaging. Example: `APPICON_CONTENT_SCALE=0.80 ./Scripts/package_mac_app.sh`. Lower values add transparent margin so the icon appears less zoomed-in.

---

## Contributing

Issues and pull requests are welcome. Keep changes focused; match existing Swift style. Large features should align with [`job_tracker_mvp_cursor_spec.md`](job_tracker_mvp_cursor_spec.md).

---

## Author

**Regan** — JobTracker is open sourced under the **MIT License**; see **[LICENSE](LICENSE)**.

If you find the app useful, a star on GitHub or a short note in your fork is appreciated.
