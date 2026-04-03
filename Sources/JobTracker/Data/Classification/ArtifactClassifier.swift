import Foundation

enum ArtifactClassifier {
    static func classify(fileName: String, fileExtension: String, text: String?) -> DocumentType {
        let lower = fileName.lowercased()
        let combined = lower + " " + (text?.lowercased() ?? "")

        let resumeHints = ["resume", "cv", "curriculum vitae"]
        let coverHints = ["cover", "cover letter", "coverletter", " cl", "cl.", "letter"]

        var resumeScore = 0
        var coverScore = 0

        for h in resumeHints where combined.contains(h) { resumeScore += 3 }
        for h in coverHints where combined.contains(h.trimmingCharacters(in: .whitespaces)) { coverScore += 3 }

        if let t = text, !t.isEmpty {
            let tl = t.lowercased()
            if tl.contains("experience") && tl.contains("education") { resumeScore += 2 }
            if tl.contains("skills") || tl.contains("summary") { resumeScore += 1 }
            if tl.contains("dear ") || tl.contains("i am writing") || tl.contains("sincerely") { coverScore += 2 }
            if tl.contains("re:") || tl.contains("position:") || tl.contains("applying for") { coverScore += 2 }
        }

        if coverScore >= resumeScore && coverScore >= 2 { return .coverLetter }
        if resumeScore >= coverScore && resumeScore >= 2 { return .resume }
        if coverScore > 0 || resumeScore > 0 {
            return coverScore > resumeScore ? .coverLetter : .resume
        }
        return .unknown
    }
}
