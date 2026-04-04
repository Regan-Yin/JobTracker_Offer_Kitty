# Security practices

This document describes what JobTracker **does** and **does not** do with respect to networking and data. It is informational, not a legal warranty.

## What is not in the app

- No analytics SDKs, crash reporting hooks, or remote logging endpoints are included in the source tree reviewed for release.
- No hardcoded API keys, cloud database URLs, or third-party authentication for core features.
- No code paths that upload your SQLite database or materials folder to a server controlled by the author.

## Network and dependencies

- **Swift Package Manager** may fetch **GRDB** and **ZIPFoundation** from GitHub when you run `swift package resolve` or build — that is tooling traffic, not the app runtime phoning home.
- The **Feedback** feature composes a **`mailto:`** URL and opens your **default mail client**; mail is sent only if you choose to send it.

## Local data

- Application data is stored in SQLite at a path under `~/Library/Application Support/JobTracker/` on the user’s machine.
- **Materials folder** content remains where you put it on disk; the app reads files you selected.

## Supply chain

- Pin dependency versions via **Package.resolved** when you need reproducible builds.
- Review updates to dependencies before upgrading in production-like use.

## Reporting

If you discover a security issue in this repository’s code:

1. Prefer a **private** GitHub security advisory (if enabled).
2. If private reporting is unavailable, open a GitHub Issue with minimal sensitive details and request private follow-up.

General bug reports and improvement requests should go to GitHub Issues.
