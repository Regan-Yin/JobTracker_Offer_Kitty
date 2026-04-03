# Publishing this folder to GitHub

This folder is intended to be the **root of your public repository** (no `.build`, no `dist`, no personal databases).

## Before the first push

1. **Feedback email** — In `Sources/JobTracker/Features/Settings/SettingsView.swift`, set `FeedbackDistribution.mailtoRecipient` to an address you control (or leave the placeholder if you do not want mailto to target a real inbox yet).
2. **Bundle ID** — In `Scripts/package_mac_app.sh`, adjust `BUNDLE_ID` if you distribute a signed `.app`.
3. **License** — Read `LICENSE`. It is a **non-commercial** community license, not MIT. Ensure it matches what you want before publishing.

## Initialize and push

```bash
cd /path/to/JobTracker_v1.0.0
git init
git add Package.swift Package.resolved LICENSE README.md SECURITY.md PUBLISHING.md \
  .gitignore Sources Resources Scripts job_tracker_mvp_cursor_spec.md
git commit -m "JobTracker v1.0.0 — initial open release"
```

Create an **empty** repository on GitHub (no README if you already have one locally), then:

```bash
git remote add origin https://github.com/<you>/<repo>.git
git branch -M main
git push -u origin main
```

## Releases

Tag a version (e.g. `v1.0.0`), attach an optional zip of `JobTracker.app` from `./Scripts/package_mac_app.sh`, and paste release notes from `README.md`.

## Disclaimer

Licensing text here is not legal advice. For organizational or commercial questions, consult a qualified attorney.
