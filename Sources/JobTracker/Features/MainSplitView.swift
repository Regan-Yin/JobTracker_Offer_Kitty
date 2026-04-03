import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable, Hashable {
    case overview = "Overview"
    case applications = "Applications"
    case companies = "Companies"
    case exports = "Exports"
    case settings = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .applications: return "doc.text.fill"
        case .companies: return "building.2.fill"
        case .exports: return "square.and.arrow.up"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainSplitView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selection: SidebarItem = .overview

    var body: some View {
        NavigationSplitView {
            NavigationStack {
                List {
                    ForEach(SidebarItem.allCases) { item in
                        Button {
                            selection = item
                        } label: {
                            Label(item.rawValue, systemImage: item.systemImage)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 8))
                        .listRowBackground(
                            selection == item
                                ? JobTrackerTheme.accent.opacity(0.2)
                                : Color.clear
                        )
                    }
                }
                .listStyle(.sidebar)
                .navigationTitle("Job Tracker")
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 320)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .clipped()
        }
        .tint(JobTrackerTheme.accent)
        .onChange(of: appState.navigateToTab) { _, newValue in
            if let tab = newValue, let item = SidebarItem(rawValue: tab) {
                selection = item
                appState.navigateToTab = nil
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .overview: OverviewView()
        case .applications: ApplicationsView()
        case .companies: CompaniesView()
        case .exports: ExportsView()
        case .settings: SettingsView()
        }
    }
}
