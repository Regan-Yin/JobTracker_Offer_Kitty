import Foundation
import GRDB

enum MergeService {
    static func mergeCompanies(database: AppDatabase, keepId: String, mergeId: String) throws {
        guard keepId != mergeId else { return }
        try database.writer.write { db in
            try db.execute(
                sql: "UPDATE applications SET companyId = ? WHERE companyId = ?",
                arguments: [keepId, mergeId]
            )
            try db.execute(
                sql: "UPDATE document_artifacts SET companyId = ? WHERE companyId = ?",
                arguments: [keepId, mergeId]
            )
            try db.execute(
                sql: "UPDATE event_logs SET companyId = ? WHERE companyId = ?",
                arguments: [keepId, mergeId]
            )
            try db.execute(
                sql: "UPDATE reminders SET companyId = ? WHERE companyId = ?",
                arguments: [keepId, mergeId]
            )
            try db.execute(
                sql: "UPDATE networking_contacts SET companyId = ? WHERE companyId = ?",
                arguments: [keepId, mergeId]
            )
            _ = try CompanyRecord.deleteOne(db, key: mergeId)
        }
    }

    static func mergeApplications(database: AppDatabase, keepId: String, mergeId: String) throws {
        guard keepId != mergeId else { return }
        try database.writer.write { db in
            try db.execute(
                sql: "UPDATE document_artifacts SET applicationId = ? WHERE applicationId = ?",
                arguments: [keepId, mergeId]
            )
            try db.execute(
                sql: "UPDATE event_logs SET applicationId = ? WHERE applicationId = ?",
                arguments: [keepId, mergeId]
            )
            try db.execute(
                sql: "UPDATE reminders SET applicationId = ? WHERE applicationId = ?",
                arguments: [keepId, mergeId]
            )
            _ = try ApplicationRecord.deleteOne(db, key: mergeId)
        }
    }
}
