import AppKit
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var step = 0
    @State private var isBusy = false
    @State private var errorMessage: String?

    /// If this path exists, offer it as a shortcut. Forks may customize.
    private var suggestedMaterialsRoot: URL? {
        let fm = FileManager.default
        let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        let candidates = [
            home.appendingPathComponent("Documents/JOB", isDirectory: true),
            home.appendingPathComponent("Documents/JobMaterials", isDirectory: true),
        ]
        return candidates.first { fm.fileExists(atPath: $0.path) }
    }

    var body: some View {
        VStack(spacing: 28) {
            Text("Job Application Tracker")
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(JobTrackerTheme.textPrimary)

            Text("Local-first tracking from your materials folder")
                .foregroundStyle(JobTrackerTheme.muted)

            if step == 0 {
                folderStep
            } else if step == 1 {
                scanStep
            } else {
                completeStep
            }

            if let err = errorMessage {
                Text(err)
                    .foregroundStyle(.red.opacity(0.9))
                    .font(.callout)
            }
        }
        .padding(40)
        .frame(maxWidth: 520)
        .background(JobTrackerTheme.background)
    }

    private var folderStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose your JOB materials root folder")
                .font(.headline)
                .foregroundStyle(JobTrackerTheme.textPrimary)

            if let suggested = suggestedMaterialsRoot {
                Button("Use suggested folder") {
                    appState.setRootFolder(suggested)
                    step = 1
                }
                .buttonStyle(.borderedProminent)
                .tint(JobTrackerTheme.accent)
            }

            Button("Choose folder…") {
                let panel = NSOpenPanel()
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.allowsMultipleSelection = false
                panel.directoryURL = URL(fileURLWithPath: NSHomeDirectory())
                if panel.runModal() == .OK, let url = panel.url {
                    appState.setRootFolder(url)
                    step = 1
                }
            }
        }
    }

    private var scanStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let url = appState.rootFolderURL {
                Text("Root: \(url.path)")
                    .font(.caption)
                    .foregroundStyle(JobTrackerTheme.muted)
                    .textSelection(.enabled)
            }

            Button {
                Task {
                    isBusy = true
                    errorMessage = nil
                    await appState.performScan()
                    isBusy = false
                    if appState.scanError != nil {
                        errorMessage = appState.scanError
                    } else {
                        step = 2
                    }
                }
            } label: {
                if isBusy {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Scan folder and build candidates")
                }
            }
            .disabled(isBusy || appState.rootFolderURL == nil)
            .buttonStyle(.borderedProminent)
            .tint(JobTrackerTheme.accent)

            Button("Back") { step = 0 }
                .buttonStyle(.borderless)
        }
    }

    private var completeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let s = appState.lastScanSummary {
                Text("Scan complete")
                    .font(.headline)
                Text("Artifacts: \(s.artifactsFound) · New companies: \(s.companiesCreated) · New applications: \(s.applicationsCreated) · Duplicate hints: \(s.duplicatesSuggested)")
                    .foregroundStyle(JobTrackerTheme.muted)
            }
            Text("You can refine company mappings, stages, and roles in the main app. Manual edits always win.")
                .foregroundStyle(JobTrackerTheme.muted)
                .font(.callout)

            Button("Open dashboard") {
                appState.completeOnboarding()
            }
            .buttonStyle(.borderedProminent)
            .tint(JobTrackerTheme.accent)
        }
    }
}
