import SwiftUI

private enum ApplicationsDefaults {
    static let didSanitizeRoleTitles = "didSanitizeRoleTitlesV2"
}

/// Proportional column widths that adapt to available space.
private struct AppColumnWidths {
    let applied: CGFloat
    let company: CGFloat
    let role: CGFloat
    let stage: CGFloat
    let outcome: CGFloat
    let review: CGFloat

    init(totalWidth: CGFloat) {
        let w = max(totalWidth - 24, 400) // minus padding
        applied = w * 0.12
        company = w * 0.15
        role = w * 0.30
        stage = w * 0.15
        outcome = w * 0.13
        review = w * 0.10
    }
}

private let defaultCols = AppColumnWidths(totalWidth: 764)

struct ApplicationsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var rows: [(ApplicationRecord, CompanyRecord?)] = []
    @State private var selectedId: String?
    @State private var showAddSheet = false

    @State private var listWidth: CGFloat = 764

    // Filters
    @State private var filterText = ""
    @State private var filterDateFrom: Date? = nil
    @State private var filterDateTo: Date? = nil
    @State private var filterCompanyId: String? = nil
    @State private var filterStage: String? = nil
    @State private var filterOutcome: String? = nil

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                Text("Applications")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(JobTrackerTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                filterBar

                applicationsTableHeader

                GeometryReader { geo in
                    let lw = max(geo.size.width - 381, 400)
                    HStack(spacing: 0) {
                        applicationsList
                            .frame(width: lw)

                        Divider()

                        detailColumn
                            .frame(width: 380)
                    }
                    .onAppear { listWidth = lw }
                    .onChange(of: geo.size.width) { _, _ in listWidth = lw }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(JobTrackerTheme.background)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Label("Add application", systemImage: "plus")
                    }
                    .help("Add a new application manually")
                }
            }
            .onAppear {
                if !UserDefaults.standard.bool(forKey: ApplicationsDefaults.didSanitizeRoleTitles) {
                    do {
                        _ = try JobStore(db: appState.database).sanitizeAllApplicationRoleTitles()
                        UserDefaults.standard.set(true, forKey: ApplicationsDefaults.didSanitizeRoleTitles)
                    } catch {}
                }
                reload()
                if let navId = appState.navigateToApplicationId {
                    selectedId = navId
                    appState.navigateToApplicationId = nil
                }
            }
            .onChange(of: appState.navigateToApplicationId) { _, newValue in
                if let appId = newValue {
                    selectedId = appId
                    appState.navigateToApplicationId = nil
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddApplicationSheet(
                    database: appState.database,
                    onSaved: { newId in
                        showAddSheet = false
                        reload()
                        selectedId = newId
                    },
                    onCancel: { showAddSheet = false }
                )
            }
        }
    }

    // MARK: - Filter bar

    private var filterBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                TextField("Search role or company…", text: $filterText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 220)

                // Date from
                HStack(spacing: 4) {
                    Text("From")
                        .font(.caption)
                        .foregroundStyle(JobTrackerTheme.muted)
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { filterDateFrom ?? Calendar.current.date(byAdding: .year, value: -1, to: Date())! },
                            set: { filterDateFrom = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .frame(width: 100)
                    if filterDateFrom != nil {
                        Button { filterDateFrom = nil } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(JobTrackerTheme.muted)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Date to
                HStack(spacing: 4) {
                    Text("To")
                        .font(.caption)
                        .foregroundStyle(JobTrackerTheme.muted)
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { filterDateTo ?? Date() },
                            set: { filterDateTo = $0 }
                        ),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .frame(width: 100)
                    if filterDateTo != nil {
                        Button { filterDateTo = nil } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(JobTrackerTheme.muted)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Company picker
                Picker("Company", selection: $filterCompanyId) {
                    Text("All Companies").tag(String?.none)
                    ForEach(distinctCompanies, id: \.id) { c in
                        Text(c.displayName).tag(Optional(c.id))
                    }
                }
                .frame(maxWidth: 150)

                // Stage picker
                Picker("Stage", selection: $filterStage) {
                    Text("All Stages").tag(String?.none)
                    ForEach(ApplicationStage.allCases, id: \.rawValue) { s in
                        Text(s.rawValue).tag(Optional(s.rawValue))
                    }
                }
                .frame(maxWidth: 130)

                // Outcome picker
                Picker("Outcome", selection: $filterOutcome) {
                    Text("All Outcomes").tag(String?.none)
                    ForEach(ApplicationOutcome.allCases, id: \.rawValue) { o in
                        Text(o.rawValue).tag(Optional(o.rawValue))
                    }
                }
                .frame(maxWidth: 120)

                if hasActiveFilters {
                    Button("Clear") { clearFilters() }
                        .font(.caption)
                }

                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private var applicationsTableHeader: some View {
        let cols = AppColumnWidths(totalWidth: listWidth)
        return HStack(spacing: 8) {
            Text("Applied")
                .frame(width: cols.applied, alignment: .leading)
            Text("Company")
                .frame(width: cols.company, alignment: .leading)
            Text("Role")
                .frame(width: cols.role, alignment: .leading)
            Text("Stage")
                .frame(width: cols.stage, alignment: .leading)
            Text("Outcome")
                .frame(width: cols.outcome, alignment: .leading)
            Text("Flags")
                .frame(width: cols.review, alignment: .leading)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(JobTrackerTheme.muted)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(JobTrackerTheme.elevated)
    }

    private var applicationsList: some View {
        List(selection: $selectedId) {
            ForEach(filteredRows, id: \.0.id) { row in
                applicationRow(pair: row)
                    .tag(row.0.id)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    private func applicationRow(pair: (ApplicationRecord, CompanyRecord?)) -> some View {
        let app = pair.0
        let co = pair.1
        let cols = AppColumnWidths(totalWidth: listWidth)
        return HStack(alignment: .center, spacing: 8) {
            Text(shortDate(app.applicationTime))
                .lineLimit(1)
                .frame(width: cols.applied, alignment: .leading)
            Text(co?.displayName ?? "—")
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: cols.company, alignment: .leading)
            Text(RoleTitleSanitizer.sanitize(app.roleTitle))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: cols.role, alignment: .leading)
            Text(app.currentStage)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(width: cols.stage, alignment: .leading)
            Text(app.outcome)
                .lineLimit(1)
                .frame(width: cols.outcome, alignment: .leading)
            Group {
                if app.statusNeedsReview {
                    Text("Review")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(JobTrackerTheme.accent.opacity(0.25))
                        .clipShape(Capsule())
                } else {
                    Text("—")
                        .foregroundStyle(JobTrackerTheme.muted)
                }
            }
            .frame(width: cols.review, alignment: .leading)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var detailColumn: some View {
        if let sid = selectedId, let pair = rows.first(where: { $0.0.id == sid }) {
            ApplicationDetailView(
                application: pair.0,
                company: pair.1,
                onSave: { reload() },
                onDeleted: {
                    selectedId = nil
                    reload()
                }
            )
            .environmentObject(appState)
            .id(sid)
        } else {
            Text("Select an application or add a new one")
                .foregroundStyle(JobTrackerTheme.muted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Filtering

    private var filteredRows: [(ApplicationRecord, CompanyRecord?)] {
        var result = rows

        // Keyword search
        let t = filterText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !t.isEmpty {
            result = result.filter { pair in
                let title = RoleTitleSanitizer.sanitize(pair.0.roleTitle).lowercased()
                return title.contains(t)
                    || pair.0.roleTitle.lowercased().contains(t)
                    || (pair.1?.displayName.lowercased().contains(t) ?? false)
                    || pair.0.currentStage.lowercased().contains(t)
                    || pair.0.outcome.lowercased().contains(t)
            }
        }

        // Date from
        if let from = filterDateFrom {
            let startOfDay = Calendar.current.startOfDay(for: from)
            result = result.filter { ($0.0.applicationTime ?? .distantPast) >= startOfDay }
        }

        // Date to
        if let to = filterDateTo {
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: to)) ?? to
            result = result.filter { ($0.0.applicationTime ?? .distantFuture) < endOfDay }
        }

        // Company
        if let cid = filterCompanyId {
            result = result.filter { $0.0.companyId == cid }
        }

        // Stage
        if let stage = filterStage {
            result = result.filter { $0.0.currentStage == stage }
        }

        // Outcome
        if let outcome = filterOutcome {
            result = result.filter { $0.0.outcome == outcome }
        }

        return result
    }

    private var distinctCompanies: [CompanyRecord] {
        var seen = Set<String>()
        return rows.compactMap { $0.1 }
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.displayName < $1.displayName }
    }

    private var hasActiveFilters: Bool {
        !filterText.isEmpty
            || filterDateFrom != nil
            || filterDateTo != nil
            || filterCompanyId != nil
            || filterStage != nil
            || filterOutcome != nil
    }

    private func clearFilters() {
        filterText = ""
        filterDateFrom = nil
        filterDateTo = nil
        filterCompanyId = nil
        filterStage = nil
        filterOutcome = nil
    }

    private func shortDate(_ d: Date?) -> String {
        guard let d else { return "—" }
        return d.formatted(date: .numeric, time: .omitted)
    }

    private func reload() {
        let store = JobStore(db: appState.database)
        do {
            let apps = try store.allApplications().filter { !$0.isIgnored }
            let companies = Dictionary(uniqueKeysWithValues: try store.allCompanies().map { ($0.id, $0) })
            rows = apps.map { ($0, companies[$0.companyId]) }.sorted {
                ($0.0.applicationTime ?? .distantPast) > ($1.0.applicationTime ?? .distantPast)
            }
        } catch {
            rows = []
        }
    }
}

// MARK: - Detail (editable, auto-save)

struct ApplicationDetailView: View {
    @EnvironmentObject private var appState: AppState
    @State private var application: ApplicationRecord
    var company: CompanyRecord?
    var onSave: () -> Void
    var onDeleted: () -> Void
    @State private var showSaved = false
    @State private var saveTask: Task<Void, Never>?
    @State private var isDirty = false
    @State private var companyName: String = ""
    @State private var companySaveTask: Task<Void, Never>?
    @State private var showDeleteConfirm = false

    init(
        application: ApplicationRecord,
        company: CompanyRecord?,
        onSave: @escaping () -> Void,
        onDeleted: @escaping () -> Void
    ) {
        _application = State(initialValue: application)
        self.company = company
        _companyName = State(initialValue: company?.displayName ?? "")
        self.onSave = onSave
        self.onDeleted = onDeleted
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Spacer()
                    if showSaved {
                        Text("Saved")
                            .font(.caption)
                            .foregroundStyle(JobTrackerTheme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(JobTrackerTheme.accent.opacity(0.15))
                            .clipShape(Capsule())
                            .transition(.opacity)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Company")
                        .font(.caption)
                        .foregroundStyle(JobTrackerTheme.muted)
                    if company != nil {
                        TextField("Company name", text: $companyName)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: companyName) { _, _ in debouncedSaveCompany() }
                    } else {
                        Text("No company linked")
                            .font(.subheadline)
                            .foregroundStyle(JobTrackerTheme.muted)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Role title")
                        .font(.caption)
                        .foregroundStyle(JobTrackerTheme.muted)
                    TextField("Role title", text: $application.roleTitle)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: application.roleTitle) { _, _ in debouncedSave() }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Stage")
                        .font(.caption)
                        .foregroundStyle(JobTrackerTheme.muted)
                    Picker("Stage", selection: $application.currentStage) {
                        ForEach(ApplicationStage.allCases, id: \.rawValue) { s in
                            Text(s.rawValue).tag(s.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .onChange(of: application.currentStage) { _, _ in save() }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Outcome")
                        .font(.caption)
                        .foregroundStyle(JobTrackerTheme.muted)
                    Picker("Outcome", selection: $application.outcome) {
                        ForEach(ApplicationOutcome.allCases, id: \.rawValue) { o in
                            Text(o.rawValue).tag(o.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .onChange(of: application.outcome) { _, _ in save() }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Last failed stage")
                        .font(.caption)
                        .foregroundStyle(JobTrackerTheme.muted)
                    Picker("Last failed stage", selection: Binding(
                        get: { application.lastFailedStage ?? "" },
                        set: { application.lastFailedStage = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("—").tag("")
                        ForEach(LastFailedStage.allCases, id: \.rawValue) { s in
                            Text(s.rawValue).tag(s.rawValue)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .onChange(of: application.lastFailedStage) { _, _ in save() }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(JobTrackerTheme.muted)
                    TextField("Notes", text: bindingNotes(), axis: .vertical)
                        .lineLimit(4...12)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: application.notes) { _, _ in debouncedSave() }
                }

                Button("Delete application\u{2026}") {
                    showDeleteConfirm = true
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.red)
                .padding(.top, 8)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(JobTrackerTheme.surface)
        .alert("Delete this application?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteApplication()
            }
        } message: {
            Text("This permanently removes the application from your tracker. This cannot be undone.")
        }
        .onDisappear {
            saveTask?.cancel()
            companySaveTask?.cancel()
            if isDirty { saveNow() }
            let trimmed = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
            if company?.id != nil, !trimmed.isEmpty, trimmed != company?.displayName {
                saveCompanyName()
            }
        }
    }

    // MARK: - Application save

    private func save() {
        saveTask?.cancel()
        isDirty = false
        application.updatedAt = Date()
        application.sourceType = SourceType.mixed.rawValue
        do {
            try JobStore(db: appState.database).saveApplication(application)
            onSave()
            showSavedIndicator()
        } catch {}
    }

    private func debouncedSave() {
        isDirty = true
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            save()
        }
    }

    private func saveNow() {
        application.updatedAt = Date()
        application.sourceType = SourceType.mixed.rawValue
        do {
            try JobStore(db: appState.database).saveApplication(application)
            onSave()
        } catch {}
    }

    // MARK: - Company name save

    private func debouncedSaveCompany() {
        companySaveTask?.cancel()
        companySaveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            saveCompanyName()
        }
    }

    private func saveCompanyName() {
        guard company != nil else { return }
        let trimmed = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != company?.displayName else { return }
        do {
            let store = JobStore(db: appState.database)
            // Find or create a company with the new name, then reassign only this application
            let newCompanyId = try store.findOrCreateCompany(displayName: trimmed)
            application.companyId = newCompanyId
            application.updatedAt = Date()
            application.sourceType = SourceType.mixed.rawValue
            try store.saveApplication(application)
            onSave()
            showSavedIndicator()
        } catch {}
    }

    private func showSavedIndicator() {
        withAnimation { showSaved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showSaved = false }
        }
    }

    private func bindingNotes() -> Binding<String> {
        Binding(
            get: { application.notes ?? "" },
            set: { application.notes = $0.isEmpty ? nil : $0 }
        )
    }

    private func deleteApplication() {
        let id = application.id
        do {
            try JobStore(db: appState.database).deleteApplication(id: id)
            onDeleted()
        } catch {}
    }
}

// MARK: - Add application (manual, spec-aligned)

private struct AddApplicationSheet: View {
    var database: AppDatabase
    var onSaved: (String) -> Void
    var onCancel: () -> Void

    @State private var companies: [CompanyRecord] = []
    @State private var useNewCompany = false
    @State private var selectedCompanyId: String = ""
    @State private var newCompanyName = ""
    @State private var roleTitle = ""
    @State private var department = ""
    @State private var applicationTime = Date()
    @State private var currentStage = ApplicationStage.submitted.rawValue
    @State private var outcome = ApplicationOutcome.active.rawValue
    @State private var notes = ""
    @State private var errorMessage: String?
    @State private var showDuplicateAlert = false
    @State private var duplicateAlertCount = 0
    @State private var savedAppId = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Company") {
                    Toggle("Create new company", isOn: $useNewCompany)
                    if useNewCompany {
                        TextField("Company name", text: $newCompanyName)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        Picker("Company", selection: $selectedCompanyId) {
                            Text("Select…").tag("")
                            ForEach(companies, id: \.id) { c in
                                Text(c.displayName).tag(c.id)
                            }
                        }
                    }
                }
                Section("Role") {
                    TextField("Role title", text: $roleTitle)
                    TextField("Department (optional)", text: $department)
                }
                Section("Status") {
                    DatePicker("Application date", selection: $applicationTime, displayedComponents: [.date])
                    Picker("Stage", selection: $currentStage) {
                        ForEach(ApplicationStage.allCases, id: \.rawValue) { s in
                            Text(s.rawValue).tag(s.rawValue)
                        }
                    }
                    Picker("Outcome", selection: $outcome) {
                        ForEach(ApplicationOutcome.allCases, id: \.rawValue) { o in
                            Text(o.rawValue).tag(o.rawValue)
                        }
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }
                if let err = errorMessage {
                    Text(err)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            .formStyle(.grouped)
            .padding()
            .navigationTitle("New application")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .keyboardShortcut(.defaultAction)
                }
            }
            .onAppear(perform: loadCompanies)
            .alert("Possible duplicates found", isPresented: $showDuplicateAlert) {
                Button("OK") { onSaved(savedAppId) }
            } message: {
                Text("\(duplicateAlertCount) possible duplicate(s) detected. Review them in the Overview.")
            }
        }
        .frame(minWidth: 480, minHeight: 520)
    }

    private func loadCompanies() {
        do {
            companies = try JobStore(db: database).allCompanies().filter { !$0.isIgnored }.sorted { $0.displayName < $1.displayName }
            if selectedCompanyId.isEmpty, let first = companies.first {
                selectedCompanyId = first.id
            }
        } catch {
            companies = []
        }
    }

    private func save() {
        errorMessage = nil
        let store = JobStore(db: database)
        let companyId: String
        do {
            if useNewCompany {
                companyId = try store.findOrCreateCompany(displayName: newCompanyName)
            } else {
                guard !selectedCompanyId.isEmpty else {
                    errorMessage = "Choose a company or create a new one."
                    return
                }
                companyId = selectedCompanyId
            }
        } catch {
            errorMessage = "Could not resolve company."
            return
        }

        let title = RoleTitleSanitizer.sanitize(roleTitle.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !title.isEmpty else {
            errorMessage = "Role title is required."
            return
        }

        let stage = ApplicationStage(rawValue: currentStage) ?? .submitted
        let oc = ApplicationOutcome(rawValue: outcome) ?? .active
        let needsReview = false
        let prio = ScoringService.priorityScore(
            stage: stage,
            outcome: oc,
            needsReview: needsReview,
            hasOverdueReminder: false
        )
        let now = Date()
        let appId = UUID().uuidString
        let app = ApplicationRecord(
            id: appId,
            companyId: companyId,
            roleTitle: title,
            departmentName: department.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : department.trimmingCharacters(in: .whitespacesAndNewlines),
            currentStage: currentStage,
            outcome: outcome,
            lastFailedStage: nil,
            applicationTime: applicationTime,
            priorityScoreAuto: prio,
            priorityScoreManualOverride: nil,
            priorityTier: ScoringService.tierFromScore(prio),
            sourceType: SourceType.manualInput.rawValue,
            confidenceScore: 100,
            statusNeedsReview: needsReview,
            notes: notes.isEmpty ? nil : notes,
            createdAt: now,
            updatedAt: now,
            lastActivityAt: applicationTime,
            isDraftCandidate: false,
            isIgnored: false
        )

        do {
            try store.saveApplication(app)
            let ev = EventLogRecord(
                id: UUID().uuidString,
                companyId: companyId,
                applicationId: appId,
                eventType: "Manual application added",
                eventTime: now,
                eventSource: EventSource.manual.rawValue,
                title: "Application added",
                details: title,
                createdAt: now
            )
            try store.insertEvent(ev)
            let newDups = try DuplicateService.suggestApplicationDuplicates(db: database)
            if newDups > 0 {
                savedAppId = appId
                duplicateAlertCount = newDups
                showDuplicateAlert = true
            } else {
                onSaved(appId)
            }
        } catch {
            errorMessage = "Could not save application."
        }
    }
}

extension ApplicationRecord: Identifiable {}
