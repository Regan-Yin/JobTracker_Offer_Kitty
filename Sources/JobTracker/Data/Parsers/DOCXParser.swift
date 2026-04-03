import Foundation
import ZIPFoundation

enum DOCXParser {
    /// Extracts plain text from a .docx file (ZIP + word/document.xml).
    static func extractText(from fileURL: URL) throws -> String {
        let archive = try Archive(url: fileURL, accessMode: .read)
        guard let entry = archive.first(where: { $0.path == "word/document.xml" || $0.path.hasSuffix("word/document.xml") }) else {
            throw DOCXError.missingDocumentXML
        }
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent("jobtracker-docx-\(UUID().uuidString).xml", isDirectory: false)
        defer { try? FileManager.default.removeItem(at: temp) }
        _ = try archive.extract(entry, to: temp)
        let data = try Data(contentsOf: temp)
        return stripXMLToText(String(data: data, encoding: .utf8) ?? "")
    }

    private static func stripXMLToText(_ xml: String) -> String {
        var s = xml
        // Remove tags crudely; good enough for keyword heuristics
        s = s.replacingOccurrences(of: "(?s)<[^>]+>", with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: "&lt;", with: "<")
        s = s.replacingOccurrences(of: "&gt;", with: ">")
        s = s.replacingOccurrences(of: "&amp;", with: "&")
        s = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum DOCXError: Error {
    case missingDocumentXML
}
