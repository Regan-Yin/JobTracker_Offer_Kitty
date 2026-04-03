import Foundation

enum ScoringService {
    static func importanceScore(
        hasResume: Bool,
        hasCoverLetter: Bool,
        applicationCount: Int,
        hasMappedIndustry: Bool,
        lastActivity: Date?,
        hasInterviewOrOAOrOfferEvent: Bool
    ) -> Int {
        var s = 10
        if hasResume { s += 15 }
        if hasCoverLetter { s += 20 }
        if applicationCount >= 2 { s += 15 }
        if applicationCount >= 3 { s += 10 }
        if let la = lastActivity {
            if Date().timeIntervalSince(la) < 14 * 24 * 3600 { s += 10 }
        }
        if hasMappedIndustry { s += 5 }
        if hasInterviewOrOAOrOfferEvent { s += 15 }
        return min(100, max(0, s))
    }

    static func priorityScore(
        stage: ApplicationStage,
        outcome: ApplicationOutcome,
        needsReview: Bool,
        hasOverdueReminder: Bool
    ) -> Int {
        if outcome != .active {
            return hasOverdueReminder ? 20 : 5
        }
        var p = 20
        switch stage {
        case .submitted: p = 25
        case .oaAssessment: p = 45
        case .recruiterScreen, .hiringManager: p = 50
        case .firstRound, .secondRound: p = 60
        case .finalRound: p = 75
        case .caseTechnical: p = 55
        case .referenceCheck: p = 70
        case .offer: p = 100
        case .rejected, .ghosted, .closedUnknown: p = 8
        }
        if needsReview { p += 10 }
        if hasOverdueReminder { p += 15 }
        return min(100, max(0, p))
    }

    static func tierFromScore(_ score: Int) -> String {
        ImportanceTier.fromScore(score).rawValue
    }
}
