import SwiftUI

// MARK: - Duplicate resolution row (reused by OverviewView)

struct DuplicateRow: View {
    @EnvironmentObject private var appState: AppState
    var suggestion: DuplicateSuggestionRecord
    var onChange: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(suggestion.entityType.capitalized): \(suggestion.reason)")
                    .font(.headline)
                    .foregroundStyle(JobTrackerTheme.textPrimary)
                Text("Tap to compare and resolve")
                    .font(.caption)
                    .foregroundStyle(JobTrackerTheme.muted)
            }
            Spacer()
            Button("Ignore") { ignore() }
                .font(.caption)
            Image(systemName: "chevron.right")
                .foregroundStyle(JobTrackerTheme.muted)
        }
        .padding(12)
        .background(JobTrackerTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func merge(keepLeft: Bool) {
        let keep = keepLeft ? suggestion.leftEntityId : suggestion.rightEntityId
        let drop = keepLeft ? suggestion.rightEntityId : suggestion.leftEntityId
        do {
            if suggestion.entityType == "company" {
                try MergeService.mergeCompanies(database: appState.database, keepId: keep, mergeId: drop)
            } else {
                try MergeService.mergeApplications(database: appState.database, keepId: keep, mergeId: drop)
            }
            var copy = suggestion
            copy.status = DuplicateSuggestionStatus.merged.rawValue
            copy.updatedAt = Date()
            try JobStore(db: appState.database).updateDuplicate(copy)
            onChange()
        } catch {}
    }

    private func ignore() {
        var copy = suggestion
        copy.status = DuplicateSuggestionStatus.ignored.rawValue
        copy.updatedAt = Date()
        do {
            try JobStore(db: appState.database).updateDuplicate(copy)
            onChange()
        } catch {}
    }
}

// MARK: - Duplicate comparison view (side-by-side)

struct DuplicateComparisonView: View {
    @EnvironmentObject private var appState: AppState
    var suggestion: DuplicateSuggestionRecord
    var onResolved: () -> Void
    var dismissSheet: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var leftApp: ApplicationRecord?
    @State private var rightApp: ApplicationRecord?
    @State private var leftCompany: CompanyRecord?
    @State private var rightCompany: CompanyRecord?
    @State private var showDeleteConfirm = false
    @State private var deleteTarget: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(suggestion.entityType == "company"
                    ? "Company Comparison"
                    : "Application Comparison")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(JobTrackerTheme.textPrimary)

                Text("Reason: \(suggestion.reason)")
                    .font(.subheadline)
                    .foregroundStyle(JobTrackerTheme.muted)

                if suggestion.entityType == "application" {
                    applicationComparison
                } else {
                    companyComparison
                }

                Divider()

                actionButtons
            }
            .padding(20)
        }
        .onAppear { loadEntities() }
        .alert("Delete entity?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the selected entity and resolve this duplicate suggestion.")
        }
    }

    // MARK: - Application comparison

    private var applicationComparison: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left entity
            VStack(alignment: .leading, spacing: 12) {
                Text("Left")
                    .font(.headline)
                    .foregroundStyle(JobTrackerTheme.accent)
                if let app = leftApp {
                    appFields(app, company: leftCompany)
                } else {
                    Text("Not found").foregroundStyle(JobTrackerTheme.muted)
                }
                Button("Delete this", role: .destructive) {
                    deleteTarget = "left"
                    showDeleteConfirm = true
                }
                .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().padding(.horizontal, 12)

            // Right entity
            VStack(alignment: .leading, spacing: 12) {
                Text("Right")
                    .font(.headline)
                    .foregroundStyle(JobTrackerTheme.accent)
                if let app = rightApp {
                    appFields(app, company: rightCompany)
                } else {
                    Text("Not found").foregroundStyle(JobTrackerTheme.muted)
                }
                Button("Delete this", role: .destructive) {
                    deleteTarget = "right"
                    showDeleteConfirm = true
                }
                .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func appFields(_ app: ApplicationRecord, company: CompanyRecord?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldRow("Role", app.roleTitle)
            fieldRow("Company", company?.displayName ?? "Unknown")
            fieldRow("Stage", app.currentStage)
            fieldRow("Outcome", app.outcome)
            fieldRow("Applied", app.applicationTime?.formatted(date: .abbreviated, time: .omitted) ?? "—")
            fieldRow("Source", app.sourceType)
            if let notes = app.notes, !notes.isEmpty {
                fieldRow("Notes", notes)
            }
        }
    }

    // MARK: - Company comparison

    private var companyComparison: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Left")
                    .font(.headline)
                    .foregroundStyle(JobTrackerTheme.accent)
                if let c = leftCompany {
                    companyFields(c)
                } else {
                    Text("Not found").foregroundStyle(JobTrackerTheme.muted)
                }
                Button("Delete this", role: .destructive) {
                    deleteTarget = "left"
                    showDeleteConfirm = true
                }
                .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().padding(.horizontal, 12)

            VStack(alignment: .leading, spacing: 12) {
                Text("Right")
                    .font(.headline)
                    .foregroundStyle(JobTrackerTheme.accent)
                if let c = rightCompany {
                    companyFields(c)
                } else {
                    Text("Not found").foregroundStyle(JobTrackerTheme.muted)
                }
                Button("Delete this", role: .destructive) {
                    deleteTarget = "right"
                    showDeleteConfirm = true
                }
                .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func companyFields(_ c: CompanyRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldRow("Name", c.displayName)
            fieldRow("Industry", c.industryCategory ?? "Unmapped")
            fieldRow("Size", c.companySizeCategory ?? "Unknown")
            fieldRow("Importance", c.importanceTier)
            fieldRow("Mapping", c.mappingStatus)
        }
    }

    // MARK: - Helpers

    private func fieldRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(JobTrackerTheme.muted)
            Text(value)
                .foregroundStyle(JobTrackerTheme.textPrimary)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Merge (keep left)") { mergeKeep(leftSide: true) }
            Button("Merge (keep right)") { mergeKeep(leftSide: false) }
            Button("Ignore") { ignoreSuggestion() }

            Spacer()

            if suggestion.entityType == "application" {
                Button("Go to Applications") {
                    navigateToApp(suggestion.leftEntityId)
                }
                .buttonStyle(.borderedProminent)
                .tint(JobTrackerTheme.accent)
            }
            if suggestion.entityType == "company" {
                Button("Go to Companies") {
                    navigateToCompany(suggestion.leftEntityId)
                }
                .buttonStyle(.borderedProminent)
                .tint(JobTrackerTheme.accent)
            }
        }
    }

    // MARK: - Actions

    private func loadEntities() {
        let store = JobStore(db: appState.database)
        do {
            if suggestion.entityType == "application" {
                leftApp = try store.application(id: suggestion.leftEntityId)
                rightApp = try store.application(id: suggestion.rightEntityId)
                if let la = leftApp { leftCompany = try store.company(id: la.companyId) }
                if let ra = rightApp { rightCompany = try store.company(id: ra.companyId) }
            } else {
                leftCompany = try store.company(id: suggestion.leftEntityId)
                rightCompany = try store.company(id: suggestion.rightEntityId)
            }
        } catch {}
    }

    private func mergeKeep(leftSide: Bool) {
        let keep = leftSide ? suggestion.leftEntityId : suggestion.rightEntityId
        let drop = leftSide ? suggestion.rightEntityId : suggestion.leftEntityId
        do {
            if suggestion.entityType == "company" {
                try MergeService.mergeCompanies(database: appState.database, keepId: keep, mergeId: drop)
            } else {
                try MergeService.mergeApplications(database: appState.database, keepId: keep, mergeId: drop)
            }
            var copy = suggestion
            copy.status = DuplicateSuggestionStatus.merged.rawValue
            copy.updatedAt = Date()
            try JobStore(db: appState.database).updateDuplicate(copy)
            onResolved()
            dismiss()
        } catch {}
    }

    private func ignoreSuggestion() {
        var copy = suggestion
        copy.status = DuplicateSuggestionStatus.ignored.rawValue
        copy.updatedAt = Date()
        do {
            try JobStore(db: appState.database).updateDuplicate(copy)
            onResolved()
            dismiss()
        } catch {}
    }

    private func performDelete() {
        guard let target = deleteTarget else { return }
        let entityId = target == "left" ? suggestion.leftEntityId : suggestion.rightEntityId
        do {
            let store = JobStore(db: appState.database)
            if suggestion.entityType == "company" {
                try store.deleteCompany(id: entityId)
            } else {
                try store.deleteApplication(id: entityId)
            }
            var copy = suggestion
            copy.status = DuplicateSuggestionStatus.ignored.rawValue
            copy.updatedAt = Date()
            try store.updateDuplicate(copy)
            onResolved()
            dismiss()
        } catch {}
    }

    private func navigateToApp(_ appId: String) {
        appState.navigateToTab = "Applications"
        appState.navigateToApplicationId = appId
        dismissSheet()
    }

    private func navigateToCompany(_ companyId: String) {
        appState.navigateToTab = "Companies"
        appState.navigateToCompanyId = companyId
        dismissSheet()
    }
}
