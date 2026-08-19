import Foundation

/// Stores uploaded document files (currently just the WRSTC medical form
/// PDF on the Diver Medical ID) as plain files in the app's Documents
/// directory, referenced by filename only -- same directory-of-files
/// pattern as PhotoStorage.swift, just without the JPEG-specific resizing/
/// compression, since documents are handled as opaque binary data rather
/// than images.
enum DocumentStorage {
    /// Exposed (not private) so SyncManager can enumerate/target this
    /// folder directly for Backup & Sync without duplicating the path.
    static var directory: URL {
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
            notifyAdded(filename)
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
        NotificationCenter.default.post(name: .diveCheckMediaFileDeleted, object: nil, userInfo: ["filename": filename, "directory": MediaDirectory.documents.rawValue])
    }

    /// Copies an existing stored document to a fresh UUID-named file
    /// (preserving its extension) and returns the new filename. Used when
    /// snapshotting a record that references a document (e.g. "Save to
    /// History" on the Diver Medical ID's WRSTC form) so the snapshot owns
    /// an independent copy of the file -- a later replace/remove on the
    /// live record's document won't invalidate what was saved.
    static func duplicate(_ filename: String) -> String? {
        let source = directory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: source.path) else { return nil }
        let fileExtension = (filename as NSString).pathExtension
        let newFilename = "\(UUID().uuidString).\(fileExtension)"
        let destination = directory.appendingPathComponent(newFilename)
        do {
            try FileManager.default.copyItem(at: source, to: destination)
            notifyAdded(newFilename)
            return newFilename
        } catch {
            return nil
        }
    }

    /// Posts the notification SyncManager listens for to upload a
    /// freshly-written file -- shared by both `save` and `duplicate` since
    /// both create a new file on disk that needs to reach the cloud.
    private static func notifyAdded(_ filename: String) {
        NotificationCenter.default.post(name: .diveCheckMediaFileAdded, object: nil, userInfo: ["filename": filename, "directory": MediaDirectory.documents.rawValue])
    }
}
