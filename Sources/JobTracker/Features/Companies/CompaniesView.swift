import SwiftUI

struct CompaniesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var companies: [CompanyRecord] = []
    @State private var selectedId: String?
    @State private var appCounts: [String: Int] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Companies")
                .font(.title2.weight(.semibold))
                .foregroundStyle(JobTrackerTheme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

            HStack(spacing: 0) {
                List(selection: $selectedId) {
                    ForEach(companies, id: \.id) { c in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(c.displayName)
                                Text("\(appCounts[c.id, default: 0]) applications · \(c.importanceTier)")
                                    .font(.caption)
                                    .foregroundStyle(JobTrackerTheme.muted)
                            }
                            Spacer()
                            if c.mappingStatus != MappingStatus.mapped.rawValue {
                                Text("Map")
                                    .font(.caption2)
                                    .padding(4)
                                    .background(JobTrackerTheme.accent.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        .tag(c.id)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                companyDetailColumn
                    .frame(width: 380)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(JobTrackerTheme.background)
        .onAppear {
            reload()
            if let navId = appState.navigateToCompanyId {
                selectedId = navId
                appState.navigateToCompanyId = nil
            }
        }
        .onChange(of: appState.navigateToCompanyId) { _, newValue in
            if let cid = newValue {
                selectedId = cid
                appState.navigateToCompanyId = nil
            }
        }
    }

    @ViewBuilder
    private var companyDetailColumn: some View {
        if let sid = selectedId, let c = companies.first(where: { $0.id == sid }) {
            CompanyDetailView(
                company: c,
                onSave: { reload() },
                onDeleted: {
                    selectedId = nil
                    reload()
                }
            )
            .environmentObject(appState)
            .id(sid)
        } else {
            Text("Select a company")
                .foregroundStyle(JobTrackerTheme.muted)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func reload() {
        let store = JobStore(db: appState.database)
        do {
            companies = try store.allCompanies().filter { !$0.isIgnored }.sorted { $0.displayName < $1.displayName }
            let apps = try store.allApplications()
            var counts: [String: Int] = [:]
            for a in apps where !a.isIgnored {
                counts[a.companyId, default: 0] += 1
            }
            appCounts = counts
        } catch {
            companies = []
        }
    }
}

struct CompanyDetailView: View {
    @EnvironmentObject private var appState: AppState
    @State private var company: CompanyRecord
    var onSave: () -> Void
    var onDeleted: () -> Void
    @State private var showSaved = false
    @State private var saveTask: Task<Void, Never>?
    @State private var isDirty = false
    @State private var showDeleteConfirm = false

    init(company: CompanyRecord, onSave: @escaping () -> Void, onDeleted: @escaping () -> Void) {
        _company = State(initialValue: company)
        self.onSave = onSave
        self.onDeleted = onDeleted
    }

    var body: some View {
        ScrollView {
            Form {
                Section {
                    HStack {
                        Text("Company")
                            .font(.headline)
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
                    TextField("Display name", text: $company.displayName)
                        .onChange(of: company.displayName) { _, _ in debouncedSave() }
                    Picker("Industry", selection: $company.industryCategory) {
                        Text("—").tag(String?.none)
                        ForEach(IndustryCategory.allCases, id: \.rawValue) { i in
                            Text(i.rawValue).tag(Optional(i.rawValue))
                        }
                    }
                    .onChange(of: company.industryCategory) { _, _ in save() }
                    Picker("Company size", selection: $company.companySizeCategory) {
                        Text("—").tag(String?.none)
                        ForEach(CompanySizeCategory.allCases, id: \.rawValue) { s in
                            Text(s.rawValue).tag(Optional(s.rawValue))
                        }
                    }
                    .onChange(of: company.companySizeCategory) { _, _ in save() }
                    Toggle("Manual importance score override", isOn: Binding(
                        get: { company.importanceScoreManualOverride != nil },
                        set: { on in
                            company.importanceScoreManualOverride = on ? company.importanceScoreAuto : nil
                            save()
                        }
                    ))
                    if company.importanceScoreManualOverride != nil {
                        Stepper(
                            "Score: \(company.importanceScoreManualOverride ?? 0)",
                            value: Binding(
                                get: { company.importanceScoreManualOverride ?? 0 },
                                set: {
                                    company.importanceScoreManualOverride = $0
                                    save()
                                }
                            ),
                            in: 0...100
                        )
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: bindingNotes(), axis: .vertical)
                        .lineLimit(2...8)
                        .onChange(of: company.notes) { _, _ in debouncedSave() }
                }

                Section {
                    Button("Delete company\u{2026}") {
                        showDeleteConfirm = true
                    }
                    .foregroundStyle(.red)
                }
            }
            .formStyle(.grouped)
            .padding()
        }
        .background(JobTrackerTheme.surface)
        .alert("Delete this company?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteCompany()
            }
        } message: {
            Text("This permanently removes the company and all applications linked to it. This cannot be undone.")
        }
        .onDisappear {
            saveTask?.cancel()
            if isDirty { saveNow() }
        }
    }

    private func save() {
        saveTask?.cancel()
        isDirty = false
        company.normalizedName = CompanyNormalizer.normalize(company.displayName)
        company.updatedAt = Date()
        if company.industryCategory != nil && company.companySizeCategory != nil {
            company.mappingStatus = MappingStatus.mapped.rawValue
        }
        if let manual = company.importanceScoreManualOverride {
            company.importanceTier = ImportanceTier.fromScore(manual).rawValue
        } else {
            company.importanceTier = ImportanceTier.fromScore(company.importanceScoreAuto).rawValue
        }
        do {
            try JobStore(db: appState.database).saveCompany(company)
            let preset = CompanyMappingPresetRecord(
                companyNormalizedName: company.normalizedName,
                industryCategory: company.industryCategory,
                companySizeCategory: company.companySizeCategory,
                lastConfirmedAt: Date()
            )
            try JobStore(db: appState.database).upsertMappingPreset(preset)
            onSave()
            withAnimation { showSaved = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation { showSaved = false }
            }
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
        company.normalizedName = CompanyNormalizer.normalize(company.displayName)
        company.updatedAt = Date()
        if company.industryCategory != nil && company.companySizeCategory != nil {
            company.mappingStatus = MappingStatus.mapped.rawValue
        }
        if let manual = company.importanceScoreManualOverride {
            company.importanceTier = ImportanceTier.fromScore(manual).rawValue
        } else {
            company.importanceTier = ImportanceTier.fromScore(company.importanceScoreAuto).rawValue
        }
        do {
            try JobStore(db: appState.database).saveCompany(company)
            let preset = CompanyMappingPresetRecord(
                companyNormalizedName: company.normalizedName,
                industryCategory: company.industryCategory,
                companySizeCategory: company.companySizeCategory,
                lastConfirmedAt: Date()
            )
            try JobStore(db: appState.database).upsertMappingPreset(preset)
            onSave()
        } catch {}
    }

    private func bindingNotes() -> Binding<String> {
        Binding(
            get: { company.notes ?? "" },
            set: { company.notes = $0.isEmpty ? nil : $0 }
        )
    }

    private func deleteCompany() {
        let id = company.id
        do {
            try JobStore(db: appState.database).deleteCompany(id: id)
            onDeleted()
        } catch {}
    }
}

extension CompanyRecord: Identifiable {}
