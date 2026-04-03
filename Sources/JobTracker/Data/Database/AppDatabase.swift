import Foundation
import GRDB

enum AppDatabaseError: Error {
    case migrationFailed(String)
}

struct AppDatabase {
    let writer: DatabaseWriter

    static func makeShared() throws -> AppDatabase {
        let folder = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("JobTracker", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let dbURL = folder.appendingPathComponent("jobtracker.sqlite")
        var config = Configuration()
        config.foreignKeysEnabled = true
        let pool = try DatabasePool(path: dbURL.path, configuration: config)
        try Self.migrator.migrate(pool)
        return AppDatabase(writer: pool)
    }

    static var databaseFileURL: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("JobTracker", isDirectory: true)
        return folder.appendingPathComponent("jobtracker.sqlite")
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: "companies") { t in
                t.column("id", .text).primaryKey()
                t.column("normalizedName", .text).notNull().indexed()
                t.column("displayName", .text).notNull()
                t.column("industryCategory", .text)
                t.column("companySizeCategory", .text)
                t.column("importanceScoreAuto", .integer).notNull()
                t.column("importanceScoreManualOverride", .integer)
                t.column("importanceTier", .text).notNull()
                t.column("notes", .text)
                t.column("mappingStatus", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("lastActivityAt", .datetime)
                t.column("isIgnored", .boolean).notNull().defaults(to: false)
            }
            try db.create(table: "applications") { t in
                t.column("id", .text).primaryKey()
                t.column("companyId", .text).notNull().references("companies", onDelete: .cascade).indexed()
                t.column("roleTitle", .text).notNull()
                t.column("departmentName", .text)
                t.column("currentStage", .text).notNull().indexed()
                t.column("outcome", .text).notNull().indexed()
                t.column("lastFailedStage", .text)
                t.column("applicationTime", .datetime).indexed()
                t.column("priorityScoreAuto", .integer).notNull()
                t.column("priorityScoreManualOverride", .integer)
                t.column("priorityTier", .text).notNull()
                t.column("sourceType", .text).notNull()
                t.column("confidenceScore", .integer).notNull()
                t.column("statusNeedsReview", .boolean).notNull()
                t.column("notes", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("lastActivityAt", .datetime)
                t.column("isDraftCandidate", .boolean).notNull()
                t.column("isIgnored", .boolean).notNull().defaults(to: false)
            }
            try db.create(table: "document_artifacts") { t in
                t.column("id", .text).primaryKey()
                t.column("companyId", .text).references("companies", onDelete: .setNull)
                t.column("applicationId", .text).references("applications", onDelete: .setNull)
                t.column("filePath", .text).notNull().unique().indexed()
                t.column("fileName", .text).notNull()
                t.column("fileExtension", .text).notNull()
                t.column("parentFolderName", .text)
                t.column("relativePathFromRoot", .text).notNull()
                t.column("documentType", .text).notNull()
                t.column("textExtractStatus", .text).notNull()
                t.column("textExtractPreview", .text)
                t.column("createdTime", .datetime)
                t.column("modifiedTime", .datetime).indexed()
                t.column("lastScannedAt", .datetime).notNull()
                t.column("contentHash", .text)
                t.column("isDeletedFromDisk", .boolean).notNull().defaults(to: false)
            }
            try db.create(table: "event_logs") { t in
                t.column("id", .text).primaryKey()
                t.column("companyId", .text).references("companies", onDelete: .setNull)
                t.column("applicationId", .text).references("applications", onDelete: .setNull)
                t.column("eventType", .text).notNull()
                t.column("eventTime", .datetime).notNull().indexed()
                t.column("eventSource", .text).notNull()
                t.column("title", .text).notNull()
                t.column("details", .text)
                t.column("createdAt", .datetime).notNull()
            }
            try db.create(table: "reminders") { t in
                t.column("id", .text).primaryKey()
                t.column("companyId", .text).references("companies", onDelete: .setNull)
                t.column("applicationId", .text).references("applications", onDelete: .setNull)
                t.column("title", .text).notNull()
                t.column("note", .text)
                t.column("dueAt", .datetime).indexed()
                t.column("status", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("completedAt", .datetime)
            }
            try db.create(table: "duplicate_suggestions") { t in
                t.column("id", .text).primaryKey()
                t.column("entityType", .text).notNull()
                t.column("leftEntityId", .text).notNull()
                t.column("rightEntityId", .text).notNull()
                t.column("reason", .text).notNull()
                t.column("score", .double).notNull()
                t.column("status", .text).notNull()
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            try db.create(table: "networking_contacts") { t in
                t.column("id", .text).primaryKey()
                t.column("fullName", .text).notNull()
                t.column("companyId", .text).references("companies", onDelete: .setNull)
                t.column("jobTitle", .text)
                t.column("linkedinUrl", .text)
                t.column("relationshipType", .text).notNull()
                t.column("lastContactAt", .datetime)
                t.column("coffeeChatStatus", .text).notNull()
                t.column("followUpDueAt", .datetime)
                t.column("notes", .text)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
            try db.create(table: "company_mapping_presets") { t in
                t.column("companyNormalizedName", .text).primaryKey()
                t.column("industryCategory", .text)
                t.column("companySizeCategory", .text)
                t.column("lastConfirmedAt", .datetime).notNull()
            }
        }
        return migrator
    }
}
