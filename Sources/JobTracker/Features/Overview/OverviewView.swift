import Charts
import SwiftUI

// MARK: - Stage ordering for funnel computation

private let stageOrdinal: [String: Int] = [
    ApplicationStage.submitted.rawValue: 0,
    ApplicationStage.oaAssessment.rawValue: 1,
    ApplicationStage.recruiterScreen.rawValue: 2,
    ApplicationStage.hiringManager.rawValue: 3,
    ApplicationStage.firstRound.rawValue: 4,
    ApplicationStage.secondRound.rawValue: 5,
    ApplicationStage.caseTechnical.rawValue: 5,
    ApplicationStage.finalRound.rawValue: 6,
    ApplicationStage.referenceCheck.rawValue: 7,
    ApplicationStage.offer.rawValue: 8,
]

private let funnelLabels: [(label: String, minOrdinal: Int)] = [
    ("Applied", 0),
    ("OA / Assessment", 1),
    ("Screen", 2),
    ("Interview", 4),
    ("Final Round", 6),
    ("Offer", 8),
]

// MARK: - Outcome colors

private let outcomeColors: KeyValuePairs<String, Color> = [
    "Active": Color(red: 0.45, green: 0.55, blue: 0.95),
    "Rejected": Color(red: 0.95, green: 0.45, blue: 0.4),
    "Offered": Color(red: 0.4, green: 0.85, blue: 0.5),
    "Withdrawn": Color(red: 0.6, green: 0.6, blue: 0.65),
    "Closed": Color(red: 0.5, green: 0.5, blue: 0.55),
]

// MARK: - Overview

struct OverviewView: View {
    @EnvironmentObject private var appState: AppState
    @State private var kpis = KPISet.empty
    @State private var stageCounts: [(String, Int)] = []
    @State private var recentEvents: [EventLogRecord] = []
    @State private var outcomeCounts: [(String, Int)] = []
    @State private var industryAppCounts: [(String, Int)] = []
    @State private var companySizeAppCounts: [(String, Int)] = []
    @State private var rejectionByStageCounts: [(String, Int)] = []
    @State private var funnelData: [(String, Int)] = []
    @State private var monthlyAppCounts: [(Date, Int)] = []
    @State private var topCompanyCounts: [(String, Int)] = []
    @State private var outcomeByIndustry: [OutcomeIndustryItem] = []
    @State private var duplicates: [DuplicateSuggestionRecord] = []
    @State private var showDuplicateSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Overview")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(JobTrackerTheme.textPrimary)

                // Duplicate notification
                HStack(spacing: 10) {
                    if appState.pendingDuplicateCount > 0 {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text("\(appState.pendingDuplicateCount) possible duplicate(s) found")
                            .foregroundStyle(JobTrackerTheme.textPrimary)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("No duplicates")
                            .foregroundStyle(JobTrackerTheme.muted)
                    }
                    Spacer()
                    Button("Re-check") { recheckDuplicates() }
                        .font(.caption)
                    if appState.pendingDuplicateCount > 0 {
                        Button("Review") { showDuplicateSheet = true }
                            .buttonStyle(.borderedProminent)
                            .tint(JobTrackerTheme.accent)
                    }
                }
                .padding(12)
                .background(JobTrackerTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            appState.pendingDuplicateCount > 0
                                ? Color.yellow.opacity(0.3)
                                : Color.clear,
                            lineWidth: 1
                        )
                )

                // KPI cards
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    KPICard(title: "Total applications", value: "\(kpis.totalApplications)")
                    KPICard(title: "Active", value: "\(kpis.activeApplications)")
                    KPICard(title: "Companies", value: "\(kpis.distinctCompanies)")
                    KPICard(title: "Offers", value: "\(kpis.offers)")
                    KPICard(title: "Rejections", value: "\(kpis.rejections)")
                    KPICard(title: "Withdrawn", value: "\(kpis.withdrawn)")
                    KPICard(title: "App → Interview", value: kpis.appToInterviewRate)
                    KPICard(title: "Interview → Offer", value: kpis.interviewToOfferRate)
                    KPICard(title: "Needs review", value: "\(kpis.needsReview)")
                }

                // Charts in 2-column grid
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 20) {

                    // Applications by stage
                    chartCard("Applications by stage") {
                        if !stageCounts.isEmpty {
                            Chart(stageCounts, id: \.0) { item in
                                BarMark(
                                    x: .value("Stage", item.0),
                                    y: .value("Count", item.1)
                                )
                                .foregroundStyle(JobTrackerTheme.accent.opacity(0.85))
                            }
                            .frame(height: 220)
                        }
                    }

                    // Outcome distribution (donut)
                    chartCard("Outcome distribution") {
                        if !outcomeCounts.isEmpty {
                            Chart(outcomeCounts, id: \.0) { item in
                                SectorMark(
                                    angle: .value("Count", item.1),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(by: .value("Outcome", item.0))
                            }
                            .chartForegroundStyleScale(outcomeColors)
                            .frame(height: 250)
                        }
                    }

                    // Applications by industry
                    chartCard("Applications by industry") {
                        if !industryAppCounts.isEmpty {
                            Chart(industryAppCounts, id: \.0) { item in
                                BarMark(
                                    x: .value("Count", item.1),
                                    y: .value("Industry", item.0)
                                )
                                .foregroundStyle(JobTrackerTheme.accent.opacity(0.8))
                            }
                            .frame(height: max(180, CGFloat(industryAppCounts.count) * 28))
                        }
                    }

                    // Applications by company size
                    chartCard("Applications by company size") {
                        if !companySizeAppCounts.isEmpty {
                            Chart(companySizeAppCounts, id: \.0) { item in
                                BarMark(
                                    x: .value("Count", item.1),
                                    y: .value("Size", item.0)
                                )
                                .foregroundStyle(JobTrackerTheme.accent.opacity(0.75))
                            }
                            .frame(height: max(160, CGFloat(companySizeAppCounts.count) * 28))
                        }
                    }

                    // Rejection by failed stage
                    chartCard("Rejections by stage") {
                        if !rejectionByStageCounts.isEmpty {
                            Chart(rejectionByStageCounts, id: \.0) { item in
                                BarMark(
                                    x: .value("Count", item.1),
                                    y: .value("Stage", item.0)
                                )
                                .foregroundStyle(Color(red: 0.95, green: 0.45, blue: 0.4).opacity(0.8))
                            }
                            .frame(height: max(160, CGFloat(rejectionByStageCounts.count) * 28))
                        } else {
                            Text("No rejections recorded yet")
                                .foregroundStyle(JobTrackerTheme.muted)
                                .frame(height: 80)
                        }
                    }

                    // Top companies
                    chartCard("Top companies by applications") {
                        if !topCompanyCounts.isEmpty {
                            Chart(topCompanyCounts.prefix(15), id: \.0) { item in
                                BarMark(
                                    x: .value("Count", item.1),
                                    y: .value("Company", item.0)
                                )
                                .foregroundStyle(JobTrackerTheme.accent.opacity(0.7))
                            }
                            .frame(height: max(180, CGFloat(min(topCompanyCounts.count, 15)) * 26))
                        }
                    }
                }

                // Full-width charts

                // Pipeline funnel
                chartCard("Pipeline funnel") {
                    if !funnelData.isEmpty {
                        Chart(funnelData, id: \.0) { item in
                            BarMark(
                                x: .value("Count", item.1),
                                y: .value("Stage", item.0)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [JobTrackerTheme.accent, JobTrackerTheme.accent.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        }
                        .chartYAxis {
                            AxisMarks(preset: .aligned)
                        }
                        .frame(height: CGFloat(funnelData.count) * 40)
                    }
                }

                // Applications over time
                chartCard("Applications over time") {
                    if !monthlyAppCounts.isEmpty {
                        Chart(monthlyAppCounts, id: \.0) { item in
                            AreaMark(
                                x: .value("Month", item.0),
                                y: .value("Applications", item.1)
                            )
                            .foregroundStyle(JobTrackerTheme.accent.opacity(0.2))
                            LineMark(
                                x: .value("Month", item.0),
                                y: .value("Applications", item.1)
                            )
                            .foregroundStyle(JobTrackerTheme.accent)
                            PointMark(
                                x: .value("Month", item.0),
                                y: .value("Applications", item.1)
                            )
                            .foregroundStyle(JobTrackerTheme.accent)
                        }
                        .frame(height: 220)
                    }
                }

                // Outcome by industry
                chartCard("Outcome by industry") {
                    if !outcomeByIndustry.isEmpty {
                        Chart(outcomeByIndustry) { item in
                            BarMark(
                                x: .value("Count", item.count),
                                y: .value("Industry", item.industry)
                            )
                            .foregroundStyle(by: .value("Outcome", item.outcome))
                        }
                        .chartForegroundStyleScale(outcomeColors)
                        .frame(height: max(200, CGFloat(Set(outcomeByIndustry.map(\.industry)).count) * 36))
                    }
                }

                // Recent activity
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent activity")
                        .font(.headline)
                        .foregroundStyle(JobTrackerTheme.textPrimary)
                    ForEach(recentEvents.prefix(12), id: \.id) { e in
                        HStack(alignment: .top) {
                            Text(e.eventTime, style: .date)
                                .font(.caption)
                                .foregroundStyle(JobTrackerTheme.muted)
                                .frame(width: 88, alignment: .leading)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.title)
                                    .foregroundStyle(JobTrackerTheme.textPrimary)
                                if let d = e.details {
                                    Text(d)
                                        .font(.caption)
                                        .foregroundStyle(JobTrackerTheme.muted)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(JobTrackerTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(24)
        }
        .background(JobTrackerTheme.background)
        .onAppear { reload() }
        .sheet(isPresented: $showDuplicateSheet) {
            duplicateReviewSheet
        }
    }

    // MARK: - Duplicate review sheet

    private var duplicateReviewSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if duplicates.isEmpty {
                        Text("No pending duplicates")
                            .foregroundStyle(JobTrackerTheme.muted)
                            .padding()
                    }
                    ForEach(duplicates, id: \.id) { d in
                        NavigationLink {
                            DuplicateComparisonView(
                                suggestion: d,
                                onResolved: { reloadDuplicates() },
                                dismissSheet: { showDuplicateSheet = false }
                            )
                            .environmentObject(appState)
                        } label: {
                            DuplicateRow(suggestion: d) {
                                reloadDuplicates()
                            }
                            .environmentObject(appState)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Duplicate Review")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showDuplicateSheet = false }
                }
            }
        }
        .frame(minWidth: 850, minHeight: 600)
    }

    // MARK: - Chart card wrapper

    private func chartCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(JobTrackerTheme.textPrimary)
            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(JobTrackerTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Data loading

    private func reload() {
        let store = JobStore(db: appState.database)
        do {
            let apps = try store.allApplications().filter { !$0.isIgnored }
            let cos = try store.allCompanies().filter { !$0.isIgnored }
            let companyMap = Dictionary(uniqueKeysWithValues: cos.map { ($0.id, $0) })

            kpis = KPISet.compute(applications: apps, companies: cos)

            // Stage counts
            var sCounts: [String: Int] = [:]
            for a in apps { sCounts[a.currentStage, default: 0] += 1 }
            stageCounts = sCounts.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }

            // Outcome counts
            var oCounts: [String: Int] = [:]
            for a in apps { oCounts[a.outcome, default: 0] += 1 }
            outcomeCounts = oCounts.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }

            // Industry app counts
            var iCounts: [String: Int] = [:]
            for a in apps {
                let industry = companyMap[a.companyId]?.industryCategory ?? "Unmapped"
                iCounts[industry, default: 0] += 1
            }
            industryAppCounts = iCounts.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }

            // Company size app counts
            var csCounts: [String: Int] = [:]
            for a in apps {
                let size = companyMap[a.companyId]?.companySizeCategory ?? "Unknown"
                csCounts[size, default: 0] += 1
            }
            companySizeAppCounts = csCounts.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }

            // Rejection by failed stage
            var rCounts: [String: Int] = [:]
            for a in apps where a.outcome == ApplicationOutcome.rejected.rawValue {
                let stage = a.lastFailedStage ?? "Unknown"
                rCounts[stage, default: 0] += 1
            }
            rejectionByStageCounts = rCounts.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }

            // Pipeline funnel
            computeFunnel(apps: apps)

            // Monthly app counts
            let calendar = Calendar.current
            var monthly: [DateComponents: Int] = [:]
            for a in apps {
                guard let t = a.applicationTime else { continue }
                let comps = calendar.dateComponents([.year, .month], from: t)
                monthly[comps, default: 0] += 1
            }
            monthlyAppCounts = monthly.compactMap { comps, count in
                guard let date = calendar.date(from: comps) else { return nil as (Date, Int)? }
                return (date, count)
            }.sorted { $0.0 < $1.0 }

            // Top companies
            var coAppCounts: [String: Int] = [:]
            for a in apps {
                let name = companyMap[a.companyId]?.displayName ?? "Unknown"
                coAppCounts[name, default: 0] += 1
            }
            topCompanyCounts = coAppCounts.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }

            // Outcome by industry
            var obi: [String: [String: Int]] = [:]
            for a in apps {
                let industry = companyMap[a.companyId]?.industryCategory ?? "Unmapped"
                obi[industry, default: [:]][a.outcome, default: 0] += 1
            }
            outcomeByIndustry = obi.flatMap { industry, outcomes in
                outcomes.map { OutcomeIndustryItem(industry: industry, outcome: $0.key, count: $0.value) }
            }.sorted { $0.industry < $1.industry }

            recentEvents = try store.allEvents().prefix(20).map { $0 }

            // Duplicates
            duplicates = try store.pendingDuplicates()
            appState.refreshDuplicateCount()
        } catch {
            kpis = KPISet.empty
        }
    }

    private func reloadDuplicates() {
        do {
            duplicates = try JobStore(db: appState.database).pendingDuplicates()
            appState.refreshDuplicateCount()
        } catch {}
    }

    private func recheckDuplicates() {
        do {
            _ = try DuplicateService.suggestCompanyDuplicates(db: appState.database)
            _ = try DuplicateService.suggestApplicationDuplicates(db: appState.database)
            reloadDuplicates()
        } catch {}
    }

    private func computeFunnel(apps: [ApplicationRecord]) {
        // For each app, determine the max stage ordinal reached
        // considering both currentStage and lastFailedStage
        var reachCounts: [Int: Int] = [:]

        for a in apps {
            let currentOrd = stageOrdinal[a.currentStage] ?? 0
            let failedOrd: Int
            if let fs = a.lastFailedStage {
                failedOrd = stageOrdinal[fs] ?? 0
            } else {
                failedOrd = 0
            }
            let maxOrd = max(currentOrd, failedOrd)

            // Also count offered outcome as reaching offer stage
            let offered = a.outcome == ApplicationOutcome.offered.rawValue
            let effectiveMax = offered ? max(maxOrd, 8) : maxOrd

            for f in funnelLabels where effectiveMax >= f.minOrdinal {
                reachCounts[f.minOrdinal, default: 0] += 1
            }
        }

        funnelData = funnelLabels.map { ($0.label, reachCounts[$0.minOrdinal] ?? 0) }
    }
}

// MARK: - Supporting types

struct OutcomeIndustryItem: Identifiable {
    let id = UUID()
    let industry: String
    let outcome: String
    let count: Int
}

// MARK: - KPI Set

struct KPISet {
    var totalApplications: Int
    var activeApplications: Int
    var distinctCompanies: Int
    var offers: Int
    var rejections: Int
    var needsReview: Int
    var withdrawn: Int
    var closed: Int
    var appToInterviewRate: String
    var interviewToOfferRate: String

    static let empty = KPISet(
        totalApplications: 0,
        activeApplications: 0,
        distinctCompanies: 0,
        offers: 0,
        rejections: 0,
        needsReview: 0,
        withdrawn: 0,
        closed: 0,
        appToInterviewRate: "—",
        interviewToOfferRate: "—"
    )

    static func compute(applications: [ApplicationRecord], companies: [CompanyRecord]) -> KPISet {
        let total = applications.count
        let active = applications.filter { $0.outcome == ApplicationOutcome.active.rawValue }.count
        let offers = applications.filter { $0.outcome == ApplicationOutcome.offered.rawValue }.count
        let rej = applications.filter { $0.outcome == ApplicationOutcome.rejected.rawValue }.count
        let rev = applications.filter(\.statusNeedsReview).count
        let withdrawn = applications.filter { $0.outcome == ApplicationOutcome.withdrawn.rawValue }.count
        let closed = applications.filter { $0.outcome == ApplicationOutcome.closed.rawValue }.count

        // Interview-stage count: apps that reached at least recruiter screen level
        let interviewStages: Set<String> = [
            ApplicationStage.recruiterScreen.rawValue,
            ApplicationStage.hiringManager.rawValue,
            ApplicationStage.firstRound.rawValue,
            ApplicationStage.secondRound.rawValue,
            ApplicationStage.finalRound.rawValue,
            ApplicationStage.caseTechnical.rawValue,
            ApplicationStage.referenceCheck.rawValue,
            ApplicationStage.offer.rawValue,
        ]
        let interviewCount = applications.filter { app in
            interviewStages.contains(app.currentStage) ||
            (app.lastFailedStage != nil && interviewStages.contains(app.lastFailedStage!))
        }.count

        let appToInterview: String
        if total > 0 {
            appToInterview = String(format: "%.0f%%", Double(interviewCount) / Double(total) * 100)
        } else {
            appToInterview = "—"
        }

        let intToOffer: String
        if interviewCount > 0 {
            intToOffer = String(format: "%.0f%%", Double(offers) / Double(interviewCount) * 100)
        } else {
            intToOffer = "—"
        }

        return KPISet(
            totalApplications: total,
            activeApplications: active,
            distinctCompanies: Set(applications.map(\.companyId)).count,
            offers: offers,
            rejections: rej,
            needsReview: rev,
            withdrawn: withdrawn,
            closed: closed,
            appToInterviewRate: appToInterview,
            interviewToOfferRate: intToOffer
        )
    }
}

// MARK: - KPI Card

struct KPICard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(JobTrackerTheme.muted)
            Text(value)
                .font(.title2.weight(.semibold))
                .foregroundStyle(JobTrackerTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(JobTrackerTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(JobTrackerTheme.border, lineWidth: 1)
        )
    }
}
