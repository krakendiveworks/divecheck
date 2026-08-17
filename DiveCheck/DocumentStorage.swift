import Foundation

/// Stores uploaded document files (currently just the WRSTC medical form
/// PDF on the Diver Medical ID) as plain files in the app's Documents
/// directory, referenced by filename only -- same directory-of-files
/// pattern as PhotoStorage.swift, just without the JPEG-specific resizing/
/// compression, since documents are handled as opaque binary data rather
/// than images.
enum DocumentStorage {
    private static var directory: URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DiveDocuments", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    /// Copies the file at `sourceURL` into app storage and returns the
    /// generated filename to save on the owning model. `sourceURL` is
    /// typically a security-scoped URL handed back by `.fileImporter`
    /// (e.g. a file picked from iCloud Drive or another app's Files
    /// provider), so the read is bracketed in start/stop
    /// accessing-security-scoped-resource calls.
    static func save(from sourceURL: URL, fileExtension: String = "pdf") -> String? {
        let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { sourceURL.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: sourceURL) else { return nil }
        let filename = "\(UUID().uuidString).\(fileExtension)"
        let destination = directory.appendingPathComponent(filename)
        do {
            try data.write(to: destination)
            return filename
        } catch {
            return nil
        }
    }

    static func url(for filename: String) -> URL {
        directory.appendingPathComponent(filename)
    }

    static func delete(_ filename: String) {
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(filename))
    }
}
