import Foundation
import GRDB

/// Typed database operations for the job tracker.
struct JobStore {
    var db: AppDatabase

    func allCompanies() throws -> [CompanyRecord] {
        try db.writer.read { db in
            try CompanyRecord.order(Column("displayName")).fetchAll(db)
        }
    }

    func allApplications() throws -> [ApplicationRecord] {
        try db.writer.read { db in
            try ApplicationRecord.fetchAll(db)
        }
    }

    func company(id: String) throws -> CompanyRecord? {
        try db.writer.read { db in
            try CompanyRecord.fetchOne(db, key: id)
        }
    }

    func application(id: String) throws -> ApplicationRecord? {
        try db.writer.read { db in
            try ApplicationRecord.fetchOne(db, key: id)
        }
    }

    func applications(forCompanyId cid: String) throws -> [ApplicationRecord] {
        try db.writer.read { db in
            try ApplicationRecord.filter(Column("companyId") == cid).fetchAll(db)
        }
    }

    func allEvents() throws -> [EventLogRecord] {
        try db.writer.read { db in
            try EventLogRecord.order(Column("eventTime").desc).fetchAll(db)
        }
    }

    func allReminders() throws -> [ReminderRecord] {
        try db.writer.read { db in
            try ReminderRecord.order(Column("dueAt").asc).fetchAll(db)
        }
    }

    func pendingDuplicates() throws -> [DuplicateSuggestionRecord] {
        try db.writer.read { db in
            try DuplicateSuggestionRecord.filter(Column("status") == "pending").fetchAll(db)
        }
    }

    func allContacts() throws -> [NetworkingContactRecord] {
        try db.writer.read { db in
            try NetworkingContactRecord.order(Column("fullName")).fetchAll(db)
        }
    }

    func mappingPreset(for normalized: String) throws -> CompanyMappingPresetRecord? {
        try db.writer.read { db in
            try CompanyMappingPresetRecord.fetchOne(db, key: normalized)
        }
    }

    func saveCompany(_ row: CompanyRecord) throws {
        var copy = row
        try db.writer.write { db in
            try copy.save(db)
        }
    }

    func saveApplication(_ row: ApplicationRecord) throws {
        var copy = row
        copy.roleTitle = RoleTitleSanitizer.sanitize(copy.roleTitle)
        try db.writer.write { db in
            try copy.save(db)
        }
    }

    /// One-time cleanup: strip name prefixes from every stored role title.
    func sanitizeAllApplicationRoleTitles() throws -> Int {
        var changed = 0
        try db.writer.write { db in
            let apps = try ApplicationRecord.fetchAll(db)
            for var app in apps {
                let cleaned = RoleTitleSanitizer.sanitize(app.roleTitle)
                guard cleaned != app.roleTitle else { continue }
                app.roleTitle = cleaned
                app.updatedAt = Date()
                try app.update(db)
                changed += 1
            }
        }
        return changed
    }

    /// Returns existing company id when normalized name matches, otherwise inserts a new company.
    func findOrCreateCompany(displayName: String) throws -> String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            struct EmptyCompanyName: Error {}
            throw EmptyCompanyName()
        }
        let normalized = CompanyNormalizer.normalize(trimmed)
        return try db.writer.write { db in
            if let existing = try CompanyRecord.filter(Column("normalizedName") == normalized).fetchOne(db) {
                return existing.id
            }
            let id = UUID().uuidString
            let now = Date()
            var row = CompanyRecord(
                id: id,
                normalizedName: normalized,
                displayName: trimmed,
                industryCategory: nil,
                companySizeCategory: nil,
                importanceScoreAuto: 10,
                importanceScoreManualOverride: nil,
                importanceTier: ImportanceTier.low.rawValue,
                notes: nil,
                mappingStatus: MappingStatus.unmapped.rawValue,
                createdAt: now,
                updatedAt: now,
                lastActivityAt: nil,
                isIgnored: false
            )
            try row.insert(db)
            return id
        }
    }

    func insertEvent(_ row: EventLogRecord) throws {
        try db.writer.write { db in
            var copy = row
            try copy.insert(db)
        }
    }

    func insertReminder(_ row: ReminderRecord) throws {
        try db.writer.write { db in
            var copy = row
            try copy.insert(db)
        }
    }

    func updateReminder(_ row: ReminderRecord) throws {
        try db.writer.write { db in
            let copy = row
            try copy.update(db)
        }
    }

    func insertContact(_ row: NetworkingContactRecord) throws {
        try db.writer.write { db in
            var copy = row
            try copy.insert(db)
        }
    }

    func updateContact(_ row: NetworkingContactRecord) throws {
        try db.writer.write { db in
            let copy = row
            try copy.update(db)
        }
    }

    func deleteContact(id: String) throws {
        try db.writer.write { db in
            _ = try NetworkingContactRecord.deleteOne(db, key: id)
        }
    }

    func upsertMappingPreset(_ row: CompanyMappingPresetRecord) throws {
        try db.writer.write { db in
            var copy = row
            try copy.save(db)
        }
    }

    func updateDuplicate(_ row: DuplicateSuggestionRecord) throws {
        try db.writer.write { db in
            let copy = row
            try copy.update(db)
        }
    }

    func deleteApplication(id: String) throws {
        try db.writer.write { db in
            _ = try ApplicationRecord.deleteOne(db, key: id)
        }
    }

    func deleteCompany(id: String) throws {
        try db.writer.write { db in
            _ = try CompanyRecord.deleteOne(db, key: id)
        }
    }
}
