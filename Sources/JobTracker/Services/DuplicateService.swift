import Foundation
import GRDB

enum DuplicateService {
    /// Strip all spaces for fuzzy matching ("WorkSafe BC" == "WorkSafeBC")
    private static func spaceless(_ s: String) -> String {
        CompanyNormalizer.normalize(s).replacingOccurrences(of: " ", with: "")
    }

    static func suggestCompanyDuplicates(db: AppDatabase) throws -> Int {
        let companies = try db.writer.read { db in
            try CompanyRecord.filter(Column("isIgnored") == false).fetchAll(db)
        }
        var count = 0
        try db.writer.write { db in
            for i in 0..<companies.count {
                for j in (i + 1)..<companies.count {
                    let a = companies[i]
                    let b = companies[j]
                    let sim = CompanyNormalizer.similarity(a.displayName, b.displayName)
                    let spacelessMatch = spaceless(a.displayName) == spaceless(b.displayName)
                    guard sim >= 0.80 || a.normalizedName == b.normalizedName || spacelessMatch else { continue }

                    // Only skip if a pending suggestion already exists (allow re-detection after ignore)
                    let pendingExists = try DuplicateSuggestionRecord
                        .filter(Column("entityType") == "company")
                        .filter(Column("status") == "pending")
                        .filter(
                            (Column("leftEntityId") == a.id && Column("rightEntityId") == b.id)
                                || (Column("leftEntityId") == b.id && Column("rightEntityId") == a.id)
                        )
                        .fetchCount(db) > 0
                    if pendingExists { continue }

                    let effectiveSim = spacelessMatch ? max(sim, 0.95) : sim
                    let reason = spacelessMatch && sim < 0.85
                        ? "Same name (spacing differs)"
                        : "Similar name (\(Int(effectiveSim * 100))%)"

                    var row = DuplicateSuggestionRecord(
                        id: UUID().uuidString,
                        entityType: "company",
                        leftEntityId: a.id,
                        rightEntityId: b.id,
                        reason: reason,
                        score: effectiveSim,
                        status: "pending",
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    try row.insert(db)
                    count += 1
                }
            }
        }
        return count
    }

    static func suggestApplicationDuplicates(db: AppDatabase) throws -> Int {
        let apps = try db.writer.read { db in
            try ApplicationRecord.filter(Column("isIgnored") == false).fetchAll(db)
        }
        var count = 0
        try db.writer.write { db in
            for i in 0..<apps.count {
                for j in (i + 1)..<apps.count {
                    let a = apps[i]
                    let b = apps[j]
                    guard a.companyId == b.companyId else { continue }
                    let sameRole = a.roleTitle.trimmingCharacters(in: .whitespaces).lowercased()
                        == b.roleTitle.trimmingCharacters(in: .whitespaces).lowercased()
                    guard sameRole else { continue }
                    let exists = try DuplicateSuggestionRecord
                        .filter(Column("entityType") == "application")
                        .filter(
                            (Column("leftEntityId") == a.id && Column("rightEntityId") == b.id)
                                || (Column("leftEntityId") == b.id && Column("rightEntityId") == a.id)
                        )
                        .fetchCount(db) > 0
                    if exists { continue }
                    var row = DuplicateSuggestionRecord(
                        id: UUID().uuidString,
                        entityType: "application",
                        leftEntityId: a.id,
                        rightEntityId: b.id,
                        reason: "Same company and role title",
                        score: 0.9,
                        status: "pending",
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    try row.insert(db)
                    count += 1
                }
            }
        }
        return count
    }
}
