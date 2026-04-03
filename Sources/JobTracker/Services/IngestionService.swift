import Foundation
import GRDB
import OSLog

private let log = Logger(subsystem: "com.jobtracker", category: "ingestion")

struct IngestionService {
    var database: AppDatabase

    func ingest(rootFolder: URL) throws -> ScanSummary {
        let files = try FolderScanner.scan(root: rootFolder)
        let rootPath = rootFolder.standardizedFileURL.path

        var companiesCreated = 0
        var applicationsCreated = 0
        let artifactsCount = files.count

        try database.writer.write { db in
            var companyIdByFolder: [String: String] = [:]

            let existingCompanies = try CompanyRecord.fetchAll(db)
            for c in existingCompanies {
                companyIdByFolder[c.displayName] = c.id
            }

            let distinctFolders = Set(files.map(\.companyFolderName))
            for folder in distinctFolders {
                let normalized = CompanyNormalizer.normalize(folder)
                if let existing = try CompanyRecord.filter(Column("normalizedName") == normalized).fetchOne(db) {
                    companyIdByFolder[folder] = existing.id
                    continue
                }
                let id = UUID().uuidString
                let now = Date()
                var row = CompanyRecord(
                    id: id,
                    normalizedName: normalized,
                    displayName: folder,
                    industryCategory: nil,
                    companySizeCategory: nil,
                    importanceScoreAuto: 10,
                    importanceScoreManualOverride: nil,
                    importanceTier: "Low",
                    notes: nil,
                    mappingStatus: MappingStatus.unmapped.rawValue,
                    createdAt: now,
                    updatedAt: now,
                    lastActivityAt: nil,
                    isIgnored: false
                )
                try row.insert(db)
                companyIdByFolder[folder] = id
                companiesCreated += 1
            }

            var scannedPaths = Set<String>()
            let fileByPath = Dictionary(uniqueKeysWithValues: files.map { ($0.url.path, $0) })

            for file in files {
                scannedPaths.insert(file.url.path)
                let companyId = companyIdByFolder[file.companyFolderName]!

                var text: String?
                var extractStatus = TextExtractStatus.notAttempted.rawValue
                var preview: String?

                if file.fileExtension == "docx" {
                    do {
                        text = try DOCXParser.extractText(from: file.url)
                        extractStatus = TextExtractStatus.success.rawValue
                        if let t = text {
                            preview = String(t.prefix(400))
                        }
                    } catch {
                        extractStatus = TextExtractStatus.failed.rawValue
                        log.error("DOCX parse failed: \(error.localizedDescription, privacy: .public)")
                    }
                } else {
                    extractStatus = TextExtractStatus.unsupported.rawValue
                }

                let docType = ArtifactClassifier.classify(
                    fileName: file.url.lastPathComponent,
                    fileExtension: file.fileExtension,
                    text: text
                )

                if var existing = try DocumentArtifactRecord.filter(Column("filePath") == file.url.path).fetchOne(db) {
                    // Protect user-edited data: skip overwriting companyId and documentType
                    // if the linked application was manually edited
                    let isUserEdited: Bool = {
                        guard let appId = existing.applicationId else { return false }
                        guard let linkedApp = try? ApplicationRecord.fetchOne(db, key: appId) else { return false }
                        return linkedApp.sourceType != SourceType.autoDetected.rawValue
                    }()
                    if !isUserEdited {
                        existing.companyId = companyId
                        existing.documentType = docType.rawValue
                    }
                    existing.textExtractStatus = extractStatus
                    existing.textExtractPreview = preview
                    existing.createdTime = file.created
                    existing.modifiedTime = file.modified
                    existing.lastScannedAt = Date()
                    existing.isDeletedFromDisk = false
                    try existing.update(db)
                } else {
                    var artifact = DocumentArtifactRecord(
                        id: UUID().uuidString,
                        companyId: companyId,
                        applicationId: nil,
                        filePath: file.url.path,
                        fileName: file.url.lastPathComponent,
                        fileExtension: file.fileExtension,
                        parentFolderName: file.parentFolderName,
                        relativePathFromRoot: file.relativePath,
                        documentType: docType.rawValue,
                        textExtractStatus: extractStatus,
                        textExtractPreview: preview,
                        createdTime: file.created,
                        modifiedTime: file.modified,
                        lastScannedAt: Date(),
                        contentHash: nil,
                        isDeletedFromDisk: false
                    )
                    try artifact.insert(db)
                }
            }

            try markMissingArtifactsDeleted(db: db, scannedPaths: scannedPaths)

            let allCompanyIds = Array(Set(companyIdByFolder.values))
            for cid in allCompanyIds {
                let covers = try DocumentArtifactRecord
                    .filter(Column("companyId") == cid)
                    .filter(Column("documentType") == DocumentType.coverLetter.rawValue)
                    .fetchAll(db)
                let resumes = try DocumentArtifactRecord
                    .filter(Column("companyId") == cid)
                    .filter(Column("documentType") == DocumentType.resume.rawValue)
                    .fetchAll(db)

                if covers.isEmpty, !resumes.isEmpty {
                    var draftApp = try ApplicationRecord
                        .filter(Column("companyId") == cid)
                        .filter(Column("isDraftCandidate") == true)
                        .fetchOne(db)
                    if draftApp == nil {
                        let newId = UUID().uuidString
                        let mod = resumes.compactMap(\.modifiedTime).max()
                        var row = ApplicationRecord(
                            id: newId,
                            companyId: cid,
                            roleTitle: "Unknown Role",
                            departmentName: nil,
                            currentStage: ApplicationStage.submitted.rawValue,
                            outcome: ApplicationOutcome.active.rawValue,
                            lastFailedStage: nil,
                            applicationTime: mod,
                            priorityScoreAuto: 30,
                            priorityScoreManualOverride: nil,
                            priorityTier: "Low",
                            sourceType: SourceType.autoDetected.rawValue,
                            confidenceScore: 20,
                            statusNeedsReview: true,
                            notes: "Draft: resume only (no cover letter detected)",
                            createdAt: Date(),
                            updatedAt: Date(),
                            lastActivityAt: mod,
                            isDraftCandidate: true,
                            isIgnored: false
                        )
                        try row.insert(db)
                        draftApp = row
                        applicationsCreated += 1
                    }
                    guard let d = draftApp else { continue }
                    for var r in resumes where r.applicationId == nil {
                        r.applicationId = d.id
                        try r.update(db)
                    }
                } else {
                    for cover in covers where cover.applicationId == nil {
                        guard let scanned = fileByPath[cover.filePath] else { continue }
                        let text: String?
                        if scanned.fileExtension == "docx" {
                            text = try? DOCXParser.extractText(from: scanned.url)
                        } else {
                            text = nil
                        }
                        let inferred = RoleInference.infer(
                            subfolderName: scanned.subfolderForRole,
                            fileName: scanned.url.lastPathComponent,
                            text: text
                        )
                        let roleTitle = RoleTitleSanitizer.sanitize(inferred.roleTitle)
                        let needsReview = inferred.confidence < 40 || roleTitle == "Unknown Role"
                        let appId = UUID().uuidString
                        let appTime = scanned.modified
                        let prio = ScoringService.priorityScore(
                            stage: .submitted,
                            outcome: .active,
                            needsReview: needsReview,
                            hasOverdueReminder: false
                        )
                        var appRow = ApplicationRecord(
                            id: appId,
                            companyId: cid,
                            roleTitle: roleTitle,
                            departmentName: nil,
                            currentStage: ApplicationStage.submitted.rawValue,
                            outcome: ApplicationOutcome.active.rawValue,
                            lastFailedStage: nil,
                            applicationTime: appTime,
                            priorityScoreAuto: prio,
                            priorityScoreManualOverride: nil,
                            priorityTier: ScoringService.tierFromScore(prio),
                            sourceType: SourceType.autoDetected.rawValue,
                            confidenceScore: inferred.confidence,
                            statusNeedsReview: needsReview,
                            notes: nil,
                            createdAt: Date(),
                            updatedAt: Date(),
                            lastActivityAt: appTime,
                            isDraftCandidate: false,
                            isIgnored: false
                        )
                        try appRow.insert(db)
                        applicationsCreated += 1
                        var cArt = cover
                        cArt.applicationId = appId
                        try cArt.update(db)
                    }
                    if let firstApp = try ApplicationRecord
                        .filter(Column("companyId") == cid)
                        .order(Column("createdAt").asc)
                        .fetchOne(db) {
                        for var r in resumes where r.applicationId == nil {
                            r.applicationId = firstApp.id
                            try r.update(db)
                        }
                    }
                }

                try recomputeCompanyScore(db: db, companyId: cid)
            }

            var ev = EventLogRecord(
                id: UUID().uuidString,
                companyId: nil,
                applicationId: nil,
                eventType: "Folder scan completed",
                eventTime: Date(),
                eventSource: EventSource.scan.rawValue,
                title: "Scan completed",
                details: "Files: \(files.count), root: \(rootPath)",
                createdAt: Date()
            )
            try ev.insert(db)
        }

        let dupC = try DuplicateService.suggestCompanyDuplicates(db: database)
        let dupA = try DuplicateService.suggestApplicationDuplicates(db: database)

        try database.writer.write { db in
            let apps = try ApplicationRecord.fetchAll(db)
            for var a in apps {
                let stage = ApplicationStage(rawValue: a.currentStage) ?? .submitted
                let outcome = ApplicationOutcome(rawValue: a.outcome) ?? .active
                let p = ScoringService.priorityScore(
                    stage: stage,
                    outcome: outcome,
                    needsReview: a.statusNeedsReview,
                    hasOverdueReminder: false
                )
                a.priorityScoreAuto = p
                a.priorityTier = ScoringService.tierFromScore(p)
                try a.update(db)
            }
        }

        return ScanSummary(
            artifactsFound: artifactsCount,
            companiesCreated: companiesCreated,
            applicationsCreated: applicationsCreated,
            duplicatesSuggested: dupC + dupA
        )
    }

    private func markMissingArtifactsDeleted(db: Database, scannedPaths: Set<String>) throws {
        let all = try DocumentArtifactRecord.fetchAll(db)
        for var a in all {
            if !scannedPaths.contains(a.filePath), !a.isDeletedFromDisk {
                a.isDeletedFromDisk = true
                try a.update(db)
            }
        }
    }

    private func recomputeCompanyScore(db: Database, companyId: String) throws {
        guard var company = try CompanyRecord.fetchOne(db, key: companyId) else { return }
        let apps = try ApplicationRecord.filter(Column("companyId") == companyId).fetchAll(db)
        let arts = try DocumentArtifactRecord.filter(Column("companyId") == companyId).fetchAll(db)
        let hasResume = arts.contains { $0.documentType == DocumentType.resume.rawValue }
        let hasCover = arts.contains { $0.documentType == DocumentType.coverLetter.rawValue }
        let appCount = apps.count
        let mapped = company.industryCategory != nil && company.companySizeCategory != nil
        let lastAct = apps.compactMap(\.lastActivityAt).max()
        let imp = ScoringService.importanceScore(
            hasResume: hasResume,
            hasCoverLetter: hasCover,
            applicationCount: appCount,
            hasMappedIndustry: mapped,
            lastActivity: lastAct,
            hasInterviewOrOAOrOfferEvent: false
        )
        company.importanceScoreAuto = imp
        if company.importanceScoreManualOverride == nil {
            company.importanceTier = ImportanceTier.fromScore(imp).rawValue
        }
        company.lastActivityAt = lastAct
        company.updatedAt = Date()
        try company.update(db)
    }
}
