import Foundation

// MARK: - Stages & outcomes

enum ApplicationStage: String, CaseIterable, Codable, Sendable {
    case submitted = "Submitted"
    case oaAssessment = "OA / Assessment"
    case recruiterScreen = "Recruiter Screen"
    case hiringManager = "Hiring Manager / Line Manager"
    case firstRound = "First Round Interview"
    case secondRound = "Second Round Interview"
    case finalRound = "Final Round"
    case caseTechnical = "Case / Technical / Presentation"
    case referenceCheck = "Reference Check"
    case offer = "Offer"
    case rejected = "Rejected"
    case ghosted = "Ghosted / No Response"
    case closedUnknown = "Closed / Unknown"
}

enum ApplicationOutcome: String, CaseIterable, Codable, Sendable {
    case active = "Active"
    case rejected = "Rejected"
    case offered = "Offered"
    case withdrawn = "Withdrawn"
    case closed = "Closed"
}

enum LastFailedStage: String, CaseIterable, Codable, Sendable {
    case oaAssessment = "OA / Assessment"
    case recruiterScreen = "Recruiter Screen"
    case hiringManager = "Hiring Manager / Line Manager"
    case firstRound = "First Round Interview"
    case secondRound = "Second Round Interview"
    case finalRound = "Final Round"
    case caseTechnical = "Case / Technical / Presentation"
    case referenceCheck = "Reference Check"
}

enum IndustryCategory: String, CaseIterable, Codable, Sendable {
    case technologySaaS = "Technology / SaaS"
    case financialServices = "Financial Services"
    case banking = "Banking / Capital Markets"
    case consulting = "Consulting"
    case retail = "Retail / Consumer"
    case ecommerce = "E-commerce"
    case healthcare = "Healthcare"
    case education = "Education"
    case government = "Government / Public Sector"
    case energy = "Energy / Utilities"
    case industrial = "Industrial / Manufacturing"
    case transportation = "Transportation / Logistics"
    case media = "Media / Entertainment"
    case realEstate = "Real Estate"
    case nonprofit = "Nonprofit"
    case other = "Other"
}

enum CompanySizeCategory: String, CaseIterable, Codable, Sendable {
    case startup = "Startup"
    case smallBusiness = "Small Business"
    case midMarket = "Mid-Market"
    case enterprise = "Enterprise"
    case publiclyListed = "Publicly Listed"
    case governmentCrown = "Government / Crown Corp"
    case nonprofitNgo = "Nonprofit / NGO"
    case unknown = "Unknown"
}

enum ImportanceTier: String, CaseIterable, Codable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    static func fromScore(_ score: Int) -> ImportanceTier {
        switch score {
        case ..<25: return .low
        case 25..<50: return .medium
        case 50..<75: return .high
        default: return .critical
        }
    }
}

enum PriorityTier: String, CaseIterable, Codable, Sendable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    static func fromScore(_ score: Int) -> PriorityTier {
        let band = ImportanceTier.fromScore(score)
        return PriorityTier(rawValue: band.rawValue) ?? .low
    }
}

enum MappingStatus: String, Codable, Sendable {
    case unmapped = "unmapped"
    case mapped = "mapped"
    case needsReview = "needs_review"
}

enum DocumentType: String, Codable, Sendable {
    case coverLetter = "cover_letter"
    case resume = "resume"
    case unknown
}

enum TextExtractStatus: String, Codable, Sendable {
    case notAttempted = "not_attempted"
    case success
    case failed
    case unsupported
}

enum EventSource: String, Codable, Sendable {
    case system
    case manual
    case scan
    case merge
    case mapping
}

enum SourceType: String, Codable, Sendable {
    case autoDetected = "auto_detected"
    case manualInput = "manual_input"
    case mixed
}

enum ReminderStatus: String, Codable, Sendable {
    case open
    case completed
    case dismissed
    case overdue
}

enum DuplicateEntityType: String, Codable, Sendable {
    case company
    case application
}

enum DuplicateSuggestionStatus: String, Codable, Sendable {
    case pending
    case merged
    case ignored
    case resolvedManually = "resolved_manually"
}

// RelationshipType and CoffeeChatStatus enums removed from active use.
// DB table networking_contacts and NetworkingContactRecord are retained for backward compatibility.
