import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ExportsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var previewCount = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Exports")
                .font(.title2.weight(.semibold))

            Text(previewCount)
                .font(.callout)
                .foregroundStyle(JobTrackerTheme.muted)

            HStack(spacing: 12) {
                Button("Export applications (CSV)…") { exportApplications() }
                Button("Export companies (CSV)…") { exportCompanies() }
                Button("Export event log (CSV)…") { exportEvents() }
            }
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(JobTrackerTheme.background)
        .onAppear(perform: updatePreview)
    }

    private func updatePreview() {
        let store = JobStore(db: appState.database)
        do {
            let a = try store.allApplications().count
            let c = try store.allCompanies().count
            let e = try store.allEvents().count
            previewCount = "Applications: \(a) · Companies: \(c) · Events: \(e)"
        } catch {
            previewCount = ""
        }
    }

    private func exportApplications() {
        let store = JobStore(db: appState.database)
        do {
            let apps = try store.allApplications()
            let companies = Dictionary(uniqueKeysWithValues: try store.allCompanies().map { ($0.id, $0) })
            let rows: [(ApplicationRecord, CompanyRecord?)] = apps.map { ($0, companies[$0.companyId]) }
            let csv = ExportService.applicationsCSV(rows: rows)
            save(data: csv, suggestedName: "applications_export.csv")
        } catch {}
    }

    private func exportCompanies() {
        let store = JobStore(db: appState.database)
        do {
            let rows = try store.allCompanies()
            let csv = ExportService.companiesCSV(rows: rows)
            save(data: csv, suggestedName: "companies_export.csv")
        } catch {}
    }

    private func exportEvents() {
        let store = JobStore(db: appState.database)
        do {
            let rows = try store.allEvents()
            let csv = ExportService.eventsCSV(rows: rows)
            save(data: csv, suggestedName: "events_export.csv")
        } catch {}
    }

    private func save(data: String, suggestedName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = suggestedName
        if panel.runModal() == .OK, let url = panel.url {
            try? data.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
