import Foundation

/// Strips leading candidate name tokens and common folder-style prefixes from inferred role titles.
enum RoleTitleSanitizer {
    /// Ordered: broader phrases first, then given-name tokens.
    private static let strippingPatterns: [String] = [
        "(?i)^Cover\\s+Letters\\s+",
        // Add fork-specific name or folder-prefix patterns here if needed.
    ]

    static func sanitize(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        for pattern in strippingPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { continue }
            let range = NSRange(s.startIndex..., in: s)
            s = regex.stringByReplacingMatches(in: s, options: [], range: range, withTemplate: "")
        }
        s = s.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return s.isEmpty ? raw.trimmingCharacters(in: .whitespacesAndNewlines) : s
    }
}
