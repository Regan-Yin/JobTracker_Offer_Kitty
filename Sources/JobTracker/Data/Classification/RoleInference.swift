import Foundation

struct RoleInferenceResult: Sendable {
    let roleTitle: String
    let confidence: Int
}

enum RoleInference {
    static func infer(
        subfolderName: String?,
        fileName: String,
        text: String?
    ) -> RoleInferenceResult {
        if let sub = subfolderName?.trimmingCharacters(in: .whitespacesAndNewlines), !sub.isEmpty,
           looksLikeRoleBucket(sub) {
            return RoleInferenceResult(roleTitle: prettify(sub), confidence: 78)
        }

        let stem = URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent
        if !stem.isEmpty, stem.lowercased() != "cover", stem.lowercased() != "cover letter" {
            let cleaned = prettify(stem)
            if cleaned.count > 2 {
                return RoleInferenceResult(roleTitle: cleaned, confidence: 72)
            }
        }

        if let t = text {
            if let r = matchPattern(#"Re:\s*(.+?)(?:\n|$)"#, in: t) {
                return RoleInferenceResult(roleTitle: r, confidence: 95)
            }
            if let r = matchPattern(#"(?i)position:\s*(.+?)(?:\n|$)"#, in: t) {
                return RoleInferenceResult(roleTitle: r, confidence: 92)
            }
            if let r = matchPattern(#"(?i)application for\s+(.+?)(?:\n|\.|$)"#, in: t) {
                return RoleInferenceResult(roleTitle: r, confidence: 88)
            }
            if let r = matchPattern(#"(?i)applying for (?:the )?(.+?)(?: position| role)"#, in: t) {
                return RoleInferenceResult(roleTitle: r, confidence: 85)
            }
        }

        return RoleInferenceResult(roleTitle: "Unknown Role", confidence: 25)
    }

    private static func looksLikeRoleBucket(_ name: String) -> Bool {
        let n = name.lowercased()
        if n == "documents" || n == "misc" || n == "archive" { return false }
        return true
    }

    private static func prettify(_ s: String) -> String {
        var x = s.replacingOccurrences(of: "_", with: " ")
        x = x.replacingOccurrences(of: "-", with: " ")
        x = x.trimmingCharacters(in: .whitespacesAndNewlines)
        return x
    }

    private static func matchPattern(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let m = regex.firstMatch(in: text, options: [], range: range),
              m.numberOfRanges >= 2,
              let r = Range(m.range(at: 1), in: text) else { return nil }
        let cap = String(text[r]).trimmingCharacters(in: .whitespacesAndNewlines)
        return cap.isEmpty ? nil : cap
    }
}
