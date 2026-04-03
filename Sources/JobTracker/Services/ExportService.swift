import Foundation

enum ExportService {
    static func escapeCSVField(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") || s.contains("\r") {
            let doubled = s.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(doubled)\""
        }
        return s
    }

    static func applicationsCSV(rows: [(ApplicationRecord, CompanyRecord?)]) -> String {
        var lines: [String] = []
        let headers = [
            "id", "company", "role", "department", "stage", "outcome", "last_failed_stage",
            "application_time", "priority_tier", "importance_tier", "industry", "company_size",
            "source_type", "confidence", "needs_review", "notes",
        ]
        lines.append(headers.joined(separator: ","))
        for (app, co) in rows {
            let fields: [String] = [
                app.id,
                co?.displayName ?? "",
                RoleTitleSanitizer.sanitize(app.roleTitle),
                app.departmentName ?? "",
                app.currentStage,
                app.outcome,
                app.lastFailedStage ?? "",
                iso(app.applicationTime),
                app.priorityTier,
                co?.importanceTier ?? "",
                co?.industryCategory ?? "",
                co?.companySizeCategory ?? "",
                app.sourceType,
                String(app.confidenceScore),
                app.statusNeedsReview ? "yes" : "no",
                app.notes ?? "",
            ]
            lines.append(fields.map(escapeCSVField).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    static func companiesCSV(rows: [CompanyRecord]) -> String {
        var lines: [String] = []
        let headers = [
            "id", "display_name", "industry", "company_size", "importance_tier",
            "mapping_status", "notes", "last_activity",
        ]
        lines.append(headers.joined(separator: ","))
        for c in rows {
            let fields: [String] = [
                c.id,
                c.displayName,
                c.industryCategory ?? "",
                c.companySizeCategory ?? "",
                c.importanceTier,
                c.mappingStatus,
                c.notes ?? "",
                iso(c.lastActivityAt),
            ]
            lines.append(fields.map(escapeCSVField).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    static func eventsCSV(rows: [EventLogRecord]) -> String {
        var lines: [String] = []
        let headers = [
            "id", "event_type", "event_time", "source", "title", "details", "company_id", "application_id",
        ]
        lines.append(headers.joined(separator: ","))
        for e in rows {
            let fields: [String] = [
                e.id,
                e.eventType,
                iso(e.eventTime),
                e.eventSource,
                e.title,
                e.details ?? "",
                e.companyId ?? "",
                e.applicationId ?? "",
            ]
            lines.append(fields.map(escapeCSVField).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private static func iso(_ d: Date?) -> String {
        guard let d else { return "" }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: d)
    }
}
