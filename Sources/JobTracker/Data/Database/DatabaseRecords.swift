import Foundation
import GRDB

struct CompanyRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord {
    static let databaseTableName = "companies"

    var id: String
    var normalizedName: String
    var displayName: String
    var industryCategory: String?
    var companySizeCategory: String?
    var importanceScoreAuto: Int
    var importanceScoreManualOverride: Int?
    var importanceTier: String
    var notes: String?
    var mappingStatus: String
    var createdAt: Date
    var updatedAt: Date
    var lastActivityAt: Date?
    var isIgnored: Bool

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let normalizedName = Column(CodingKeys.normalizedName)
    }
}

struct ApplicationRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord {
    static let databaseTableName = "applications"

    var id: String
    var companyId: String
    var roleTitle: String
    var departmentName: String?
    var currentStage: String
    var outcome: String
    var lastFailedStage: String?
    var applicationTime: Date?
    var priorityScoreAuto: Int
    var priorityScoreManualOverride: Int?
    var priorityTier: String
    var sourceType: String
    var confidenceScore: Int
    var statusNeedsReview: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var lastActivityAt: Date?
    var isDraftCandidate: Bool
    var isIgnored: Bool

    enum Columns {
        static let companyId = Column(CodingKeys.companyId)
        static let currentStage = Column(CodingKeys.currentStage)
        static let outcome = Column(CodingKeys.outcome)
    }
}

struct DocumentArtifactRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord {
    static let databaseTableName = "document_artifacts"

    var id: String
    var companyId: String?
    var applicationId: String?
    var filePath: String
    var fileName: String
    var fileExtension: String
    var parentFolderName: String?
    var relativePathFromRoot: String
    var documentType: String
    var textExtractStatus: String
    var textExtractPreview: String?
    var createdTime: Date?
    var modifiedTime: Date?
    var lastScannedAt: Date
    var contentHash: String?
    var isDeletedFromDisk: Bool
}

struct EventLogRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord {
    static let databaseTableName = "event_logs"

    var id: String
    var companyId: String?
    var applicationId: String?
    var eventType: String
    var eventTime: Date
    var eventSource: String
    var title: String
    var details: String?
    var createdAt: Date
}

struct ReminderRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord {
    static let databaseTableName = "reminders"

    var id: String
    var companyId: String?
    var applicationId: String?
    var title: String
    var note: String?
    var dueAt: Date?
    var status: String
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
}

struct DuplicateSuggestionRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord {
    static let databaseTableName = "duplicate_suggestions"

    var id: String
    var entityType: String
    var leftEntityId: String
    var rightEntityId: String
    var reason: String
    var score: Double
    var status: String
    var createdAt: Date
    var updatedAt: Date
}

struct NetworkingContactRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord {
    static let databaseTableName = "networking_contacts"

    var id: String
    var fullName: String
    var companyId: String?
    var jobTitle: String?
    var linkedinUrl: String?
    var relationshipType: String
    var lastContactAt: Date?
    var coffeeChatStatus: String
    var followUpDueAt: Date?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
}

struct CompanyMappingPresetRecord: Codable, FetchableRecord, MutablePersistableRecord, TableRecord {
    static let databaseTableName = "company_mapping_presets"

    var companyNormalizedName: String
    var industryCategory: String?
    var companySizeCategory: String?
    var lastConfirmedAt: Date
}
