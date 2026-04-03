import Foundation

struct ScannedFile: Sendable {
    let url: URL
    let relativePath: String
    let companyFolderName: String
    let parentFolderName: String?
    let subfolderForRole: String?
    let fileExtension: String
    let created: Date?
    let modified: Date?
}

enum FolderScanner {
    static func scan(root: URL) throws -> [ScannedFile] {
        let fm = FileManager.default
        let rootPath = root.standardizedFileURL.path
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .creationDateKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var results: [ScannedFile] = []
        while let item = enumerator.nextObject() as? URL {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: item.path, isDirectory: &isDir), !isDir.boolValue else { continue }
            let name = item.lastPathComponent
            if name.hasPrefix("~$") || name.hasPrefix(".") { continue }
            let ext = item.pathExtension.lowercased()
            guard ext == "docx" || ext == "doc" else { continue }

            let rel = String(item.path.dropFirst(rootPath.count)).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let components = rel.split(separator: "/").map(String.init)
            guard let first = components.first, !first.isEmpty else { continue }
            let companyFolder = first

            var subfolderForRole: String?
            if components.count >= 3 {
                // root/Company/Subfolder/file
                subfolderForRole = components[components.count - 2]
            }

            let parentFolder: String? = components.count >= 2 ? components[components.count - 2] : nil

            let vals = try item.resourceValues(forKeys: [.creationDateKey, .contentModificationDateKey])
            let created = vals.creationDate
            let modified = vals.contentModificationDate

            results.append(
                ScannedFile(
                    url: item,
                    relativePath: rel,
                    companyFolderName: companyFolder,
                    parentFolderName: parentFolder,
                    subfolderForRole: subfolderForRole,
                    fileExtension: ext,
                    created: created,
                    modified: modified
                )
            )
        }
        return results
    }
}
