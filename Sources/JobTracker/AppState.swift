import Combine
import Foundation
import GRDB
import AppKit

enum AppIconMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System Default"
        case .light: return "Light Icon"
        case .dark: return "Dark Icon"
        }
    }
}

/// Central app state: database, settings, onboarding flag.
@MainActor
final class AppState: ObservableObject {
    @Published var database: AppDatabase
    @Published var onboardingCompleted: Bool
    @Published var rootFolderURL: URL?
    @Published var lastScanSummary: ScanSummary?
    @Published var isScanning = false
    @Published var scanError: String?
    @Published var pendingDuplicateCount: Int = 0
    @Published var navigateToTab: String? = nil
    @Published var navigateToApplicationId: String? = nil
    @Published var navigateToCompanyId: String? = nil

    // Theme & appearance (app-controlled light/dark; not tied to system appearance)
    @Published var selectedTheme: ThemePreset = .midnight {
        didSet {
            JobTrackerTheme.activePreset = selectedTheme
            defaults.set(selectedTheme.rawValue, forKey: themeKey)
        }
    }
    @Published var appearanceMode: AppearanceMode = .dark {
        didSet {
            JobTrackerTheme.appearanceMode = appearanceMode
            defaults.set(appearanceMode.rawValue, forKey: appearanceKey)
        }
    }
    @Published var appIconMode: AppIconMode = .system {
        didSet {
            defaults.set(appIconMode.rawValue, forKey: appIconModeKey)
            guard hasLoadedPreferences else { return }
            iconChangeRequiresRestart = (appIconMode != launchIconMode)
        }
    }
    @Published private(set) var iconChangeRequiresRestart = false

    // Feedback drafts
    @Published var feedbackDrafts: [FeedbackDraft] = []
    @Published var submittedFeedback: [FeedbackDraft] = []

    private let defaults = UserDefaults.standard
    private let onboardingKey = "onboardingCompleted"
    private let rootPathKey = "jobRootFolderPath"
    private let themeKey = "selectedTheme"
    private let appearanceKey = "appearanceMode"
    private let appIconModeKey = "appIconMode"
    private let draftsKey = "feedbackDrafts"
    private let submittedKey = "submittedFeedback"
    private var hasLoadedPreferences = false
    private var launchIconMode: AppIconMode = .system
    private var didApplyLaunchIcon = false

    init() {
        let db = try! AppDatabase.makeShared()
        self.database = db
        self.onboardingCompleted = defaults.bool(forKey: onboardingKey)
        if let path = defaults.string(forKey: rootPathKey) {
            self.rootFolderURL = URL(fileURLWithPath: path, isDirectory: true)
        }
        // Theme + appearance (migrate legacy "Arctic" preset → light mode + Midnight accent)
        var loadedAppearance = AppearanceMode.dark
        if let modeName = defaults.string(forKey: appearanceKey),
           let mode = AppearanceMode(rawValue: modeName) {
            loadedAppearance = mode
        }
        var loadedTheme = ThemePreset.midnight
        if let themeName = defaults.string(forKey: themeKey) {
            if themeName == "Arctic" {
                loadedTheme = .midnight
                loadedAppearance = .light
                defaults.set(ThemePreset.midnight.rawValue, forKey: themeKey)
                defaults.set(AppearanceMode.light.rawValue, forKey: appearanceKey)
            } else if let preset = ThemePreset(rawValue: themeName) {
                loadedTheme = preset
            }
        }
        self.selectedTheme = loadedTheme
        self.appearanceMode = loadedAppearance

        var loadedIconMode: AppIconMode = .system
        if let iconModeName = defaults.string(forKey: appIconModeKey),
           let mode = AppIconMode(rawValue: iconModeName) {
            loadedIconMode = mode
        }
        self.appIconMode = loadedIconMode
        self.launchIconMode = loadedIconMode
        self.iconChangeRequiresRestart = false
        self.hasLoadedPreferences = true

        JobTrackerTheme.activePreset = loadedTheme
        JobTrackerTheme.appearanceMode = loadedAppearance
        // Feedback
        if let data = defaults.data(forKey: draftsKey),
           let drafts = try? JSONDecoder().decode([FeedbackDraft].self, from: data) {
            self.feedbackDrafts = drafts
        }
        if let data = defaults.data(forKey: submittedKey),
           let submitted = try? JSONDecoder().decode([FeedbackDraft].self, from: data) {
            self.submittedFeedback = submitted
        }
    }

    func setRootFolder(_ url: URL) {
        rootFolderURL = url
        defaults.set(url.path, forKey: rootPathKey)
    }

    func completeOnboarding() {
        onboardingCompleted = true
        defaults.set(true, forKey: onboardingKey)
    }

    func resetOnboardingForTesting() {
        onboardingCompleted = false
        defaults.set(false, forKey: onboardingKey)
    }

    func performScan() async {
        guard let root = rootFolderURL else { return }
        isScanning = true
        scanError = nil
        defer { isScanning = false }
        do {
            let summary = try IngestionService(database: database).ingest(rootFolder: root)
            lastScanSummary = summary
            refreshDuplicateCount()
        } catch {
            scanError = error.localizedDescription
        }
    }

    func refreshDuplicateCount() {
        do {
            pendingDuplicateCount = try JobStore(db: database).pendingDuplicates().count
        } catch {
            pendingDuplicateCount = 0
        }
    }

    func saveDraft(_ draft: FeedbackDraft) {
        if let idx = feedbackDrafts.firstIndex(where: { $0.id == draft.id }) {
            feedbackDrafts[idx] = draft
        } else {
            feedbackDrafts.append(draft)
        }
        persistDrafts()
    }

    func deleteDraft(_ draft: FeedbackDraft) {
        feedbackDrafts.removeAll { $0.id == draft.id }
        persistDrafts()
    }

    func markSubmitted(_ draft: FeedbackDraft) {
        var copy = draft
        copy.submittedAt = Date()
        submittedFeedback.append(copy)
        feedbackDrafts.removeAll { $0.id == draft.id }
        persistDrafts()
        persistSubmitted()
    }

    private func persistDrafts() {
        if let data = try? JSONEncoder().encode(feedbackDrafts) {
            defaults.set(data, forKey: draftsKey)
        }
    }

    private func persistSubmitted() {
        if let data = try? JSONEncoder().encode(submittedFeedback) {
            defaults.set(data, forKey: submittedKey)
        }
    }

    func applyLaunchIconPreferenceIfNeeded() {
        guard !didApplyLaunchIcon else { return }
        didApplyLaunchIcon = true
        applyIconMode(launchIconMode)
    }

    private func applyIconMode(_ mode: AppIconMode) {
        switch mode {
        case .system:
            NSApp.applicationIconImage = nil
        case .light:
            if let image = loadIcon(named: "AppIconLight") ?? loadIcon(named: "AppIcon") {
                NSApp.applicationIconImage = image
            } else {
                NSApp.applicationIconImage = nil
            }
        case .dark:
            if let image = loadIcon(named: "AppIconDark") ?? loadIcon(named: "AppIcon-dark") {
                NSApp.applicationIconImage = image
            } else {
                NSApp.applicationIconImage = nil
            }
        }
    }

    private func loadIcon(named resourceName: String) -> NSImage? {
        if let url = Bundle.main.url(forResource: resourceName, withExtension: "icns") {
            return NSImage(contentsOf: url)
        }
        return nil
    }

    func restartApplicationNow() {
        let bundleURL = Bundle.main.bundleURL
        guard bundleURL.pathExtension.lowercased() == "app" else {
            NSApp.terminate(nil)
            return
        }

        let escapedPath = bundleURL.path.replacingOccurrences(of: "'", with: "'\\''")
        let command = "sleep 0.5; /usr/bin/open -n '\(escapedPath)'"

        let relaunchTask = Process()
        relaunchTask.executableURL = URL(fileURLWithPath: "/bin/sh")
        relaunchTask.arguments = ["-c", command]

        do {
            try relaunchTask.run()
            NSApp.terminate(nil)
        } catch {
            NSApp.terminate(nil)
        }
    }
}

struct ScanSummary: Sendable {
    let artifactsFound: Int
    let companiesCreated: Int
    let applicationsCreated: Int
    let duplicatesSuggested: Int
}

struct FeedbackDraft: Codable, Identifiable {
    var id: String = UUID().uuidString
    var subject: String = ""
    var topic: String = "Feature Request"
    var body: String = ""
    var createdAt: Date = Date()
    var submittedAt: Date? = nil
}
