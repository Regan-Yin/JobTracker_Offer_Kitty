import AppKit
import SwiftUI

/// Replace with your address when distributing a fork or custom build (`mailto` feedback).
private enum FeedbackDistribution {
    static let mailtoRecipient = ""
    static let githubIssuesURL = "https://github.com/Regan-Yin/JobTracker_Offer_Kitty/issues/new/choose"
}

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isScanning = false
    @State private var showFeedbackSheet = false
    @State private var showDraftsSheet = false

    var body: some View {
        Form {
            materialsSection
            appearanceSection
            feedbackSection
            aboutSection
            databaseSection
        }
        .formStyle(.grouped)
        .padding()
        .frame(maxWidth: 600, alignment: .leading)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(JobTrackerTheme.background)
        .navigationTitle("Settings")
        .sheet(isPresented: $showFeedbackSheet) {
            FeedbackSheet()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showDraftsSheet) {
            DraftsSheet()
                .environmentObject(appState)
        }
    }

    // MARK: Materials Folder

    private var materialsSection: some View {
        Section("Materials folder") {
            HStack {
                Text(appState.rootFolderURL?.path ?? "Not set")
                    .font(.caption)
                    .foregroundColor(JobTrackerTheme.textPrimary)
                    .textSelection(.enabled)
                Spacer()
                Button("Choose folder\u{2026}") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        appState.setRootFolder(url)
                    }
                }
            }
            Button {
                Task {
                    isScanning = true
                    await appState.performScan()
                    isScanning = false
                }
            } label: {
                if isScanning {
                    ProgressView().controlSize(.small)
                } else {
                    Text("Rescan folder")
                }
            }
            .disabled(appState.rootFolderURL == nil || isScanning)
        }
    }

    // MARK: Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Theme")
                    .font(.headline)
                    .foregroundColor(JobTrackerTheme.textPrimary)

                HStack(spacing: 12) {
                    ForEach(ThemePreset.allCases) { preset in
                        themeSwatch(preset)
                    }
                }
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("Light or dark")
                    .font(.headline)
                    .foregroundColor(JobTrackerTheme.textPrimary)
                Text("Controls this app’s window colors only. Dock/Finder icon sizing is set in the packaging icon pipeline (see docs).")
                    .font(.caption)
                    .foregroundColor(JobTrackerTheme.muted)
                Picker("Appearance", selection: $appState.appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 8) {
                Text("App icon")
                    .font(.headline)
                    .foregroundColor(JobTrackerTheme.textPrimary)

                Picker("App icon", selection: $appState.appIconMode) {
                    ForEach(AppIconMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if appState.iconChangeRequiresRestart {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon preference saved. Restart the app to apply the new icon.")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fixedSize(horizontal: false, vertical: true)

                        Button("Restart now") {
                            appState.restartApplicationNow()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                } else {
                    Text("Changes apply on next launch.")
                        .font(.caption)
                        .foregroundColor(JobTrackerTheme.muted)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func themeSwatch(_ preset: ThemePreset) -> some View {
        let isSelected = appState.selectedTheme == preset
        return VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 6)
                .fill(preset.themeColors(for: appState.appearanceMode).accent)
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            isSelected ? JobTrackerTheme.textPrimary : Color.clear,
                            lineWidth: 2
                        )
                )
            Text(preset.rawValue)
                .font(.caption2)
                .foregroundColor(isSelected ? JobTrackerTheme.textPrimary : JobTrackerTheme.muted)
        }
        .onTapGesture {
            appState.selectedTheme = preset
        }
    }

    // MARK: Feedback & Suggestions

    private var feedbackSection: some View {
        Section("Feedback & Suggestions") {
            Button("Submit Feedback") {
                showFeedbackSheet = true
            }

            if !appState.feedbackDrafts.isEmpty {
                Button("View Drafts (\(appState.feedbackDrafts.count))") {
                    showDraftsSheet = true
                }
            }

            if !appState.submittedFeedback.isEmpty {
                Text("\(appState.submittedFeedback.count) submitted")
                    .font(.caption)
                    .foregroundColor(JobTrackerTheme.muted)
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section("About") {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("JobTracker")
                        .font(.headline)
                        .foregroundColor(JobTrackerTheme.textPrimary)
                    Text("v1.0.0")
                        .font(.caption)
                        .foregroundColor(JobTrackerTheme.muted)
                }

                Text("Author: Regan")
                    .font(.subheadline)
                    .foregroundColor(JobTrackerTheme.muted)

                Text("A macOS application for tracking job applications, managing company data, and analyzing your job search progress.")
                    .font(.caption)
                    .foregroundColor(JobTrackerTheme.textPrimary)

                Divider()

                Text("Non-commercial community license — see LICENSE in the repository.")
                    .font(.caption)
                    .foregroundColor(JobTrackerTheme.muted)

                Text("Provided as-is, for personal and non-profit sharing. No warranties. Commercial use is not permitted without permission from the author.")
                    .font(.caption2)
                    .foregroundColor(JobTrackerTheme.muted)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: Database

    private var databaseSection: some View {
        Section("Database") {
            Text(AppDatabase.databaseFileURL.path)
                .font(.caption)
                .foregroundColor(JobTrackerTheme.textPrimary)
                .textSelection(.enabled)
        }
    }
}

// MARK: - FeedbackSheet

struct FeedbackSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var editingDraft: FeedbackDraft?

    @State private var subject = ""
    @State private var topic = "Feature Request"
    @State private var feedbackBody = ""
    @State private var showDeleteDraftConfirm = false

    private let topics = [
        "Bug Report",
        "Feature Request",
        "UI/UX Improvement",
        "Data/Export",
        "Performance",
        "Other",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Submit Feedback")
                .font(.title2)
                .foregroundColor(JobTrackerTheme.textPrimary)

            TextField("Subject", text: $subject)
                .textFieldStyle(.roundedBorder)

            Picker("Topic", selection: $topic) {
                ForEach(topics, id: \.self) { t in
                    Text(t).tag(t)
                }
            }

            Text("Details")
                .font(.caption)
                .foregroundColor(JobTrackerTheme.muted)

            TextEditor(text: $feedbackBody)
                .frame(minHeight: 120)
                .font(.body)
                .scrollContentBackground(.hidden)
                .background(JobTrackerTheme.surface)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(JobTrackerTheme.border, lineWidth: 1)
                )

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                if editingDraft != nil {
                    Button("Delete draft\u{2026}") {
                        showDeleteDraftConfirm = true
                    }
                    .foregroundColor(.red)
                }

                Spacer()

                Button("Save as Draft") {
                    saveDraft()
                }

                Button("Submit") {
                    submitFeedback()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(subject.isEmpty || feedbackBody.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 480)
        .background(JobTrackerTheme.background)
        .alert("Delete this draft?", isPresented: $showDeleteDraftConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let d = editingDraft {
                    appState.deleteDraft(d)
                    dismiss()
                }
            }
        } message: {
            Text("This saved draft will be permanently removed.")
        }
        .onAppear {
            if let draft = editingDraft {
                subject = draft.subject
                topic = draft.topic
                feedbackBody = draft.body
            }
        }
    }

    private func saveDraft() {
        var draft = editingDraft ?? FeedbackDraft()
        draft.subject = subject
        draft.topic = topic
        draft.body = feedbackBody
        appState.saveDraft(draft)
        dismiss()
    }

    private func submitFeedback() {
        let version = "1.0.0"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let fullBody = """
        \(feedbackBody)

        ---
        App: JobTracker v\(version)
        macOS: \(osVersion)
        """

        let subjectLine = "[JobTracker] \(topic): \(subject)"

        if FeedbackDistribution.mailtoRecipient.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let issuesURL = URL(string: FeedbackDistribution.githubIssuesURL) {
                NSWorkspace.shared.open(issuesURL)
            }
        } else {
            var components = URLComponents()
            components.scheme = "mailto"
            components.path = FeedbackDistribution.mailtoRecipient
            components.queryItems = [
                URLQueryItem(name: "subject", value: subjectLine),
                URLQueryItem(name: "body", value: fullBody),
            ]

            if let url = components.url {
                NSWorkspace.shared.open(url)
            }
        }

        var draft = editingDraft ?? FeedbackDraft()
        draft.subject = subject
        draft.topic = topic
        draft.body = feedbackBody
        appState.markSubmitted(draft)
        dismiss()
    }
}

// MARK: - DraftsSheet

struct DraftsSheet: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var editingDraft: FeedbackDraft?
    @State private var draftPendingDelete: FeedbackDraft?
    @State private var showDeleteDraftConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Feedback Drafts")
                    .font(.title2)
                    .foregroundColor(JobTrackerTheme.textPrimary)
                Spacer()
                Button("Done") { dismiss() }
            }

            if appState.feedbackDrafts.isEmpty {
                Text("No drafts")
                    .foregroundColor(JobTrackerTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                List {
                    ForEach(appState.feedbackDrafts) { draft in
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(draft.subject.isEmpty ? "(No subject)" : draft.subject)
                                    .foregroundColor(JobTrackerTheme.textPrimary)
                                HStack {
                                    Text(draft.topic)
                                        .font(.caption)
                                        .foregroundColor(JobTrackerTheme.accent)
                                    Spacer()
                                    Text(draft.createdAt, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(JobTrackerTheme.muted)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingDraft = draft
                            }

                            Button {
                                draftPendingDelete = draft
                                showDeleteDraftConfirm = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red.opacity(0.9))
                            }
                            .buttonStyle(.borderless)
                            .help("Delete draft")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .padding(24)
        .frame(minWidth: 440, minHeight: 300)
        .background(JobTrackerTheme.background)
        .sheet(item: $editingDraft) { draft in
            FeedbackSheet(editingDraft: draft)
                .environmentObject(appState)
        }
        .alert("Delete this draft?", isPresented: $showDeleteDraftConfirm) {
            Button("Cancel", role: .cancel) {
                draftPendingDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let d = draftPendingDelete {
                    appState.deleteDraft(d)
                }
                draftPendingDelete = nil
            }
        } message: {
            Text("The saved draft will be permanently removed.")
        }
    }
}
