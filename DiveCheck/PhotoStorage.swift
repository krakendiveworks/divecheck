import Foundation
import UIKit

/// Stores dive log photos as plain files in the app's Documents directory,
/// referenced from a DiveLogEntry by filename only (`photoFilenames`) --
/// not embedded as base64 in the JSON blob AppStore persists to
/// UserDefaults/iCloud Key-Value storage. Photos can be large and that
/// store caps out around 1MB total, so keeping them as separate files is
/// what keeps photos out of CloudSync's way (see CloudSync.swift) rather
/// than blowing the sync budget or bloating every app launch's JSON decode.
enum PhotoStorage {
    /// Exposed (not private) so SyncManager can enumerate/target this
    /// folder directly for Backup & Sync without duplicating the path.
    static var directory: URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DivePhotos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    /// Saves image data to disk (as JPEG, downscaled if very large) and
    /// returns the generated filename to store on the DiveLogEntry.
    static func save(_ data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let resized = resized(image, maxDimension: 2000)
        guard let jpegData = resized.jpegData(compressionQuality: 0.8) else { return nil }

        let filename = "\(UUID().uuidString).jpg"
        let url = directory.appendingPathComponent(filename)
        do {
            try jpegData.write(to: url)
            notifyAdded(filename)
            return filename
        } catch {
            return nil
        }
    }

    static func load(_ filename: String) -> UIImage? {
        let url = directory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(_ filename: String) {
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(filename))
        NotificationCenter.default.post(name: .diveCheckMediaFileDeleted, object: nil, userInfo: ["filename": filename, "directory": MediaDirectory.photos.rawValue])
    }

    /// Copies an existing stored photo to a fresh UUID-named file and
    /// returns the new filename. Used when snapshotting a record that
    /// references a photo (e.g. "Save to History" on a Certification) so
    /// the snapshot owns an independent copy of the file -- a later
    /// replace/remove on the live record's photo won't invalidate what was
    /// saved.
    static func duplicate(_ filename: String) -> String? {
        let source = directory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: source.path) else { return nil }
        let newFilename = "\(UUID().uuidString).jpg"
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
        NotificationCenter.default.post(name: .diveCheckMediaFileAdded, object: nil, userInfo: ["filename": filename, "directory": MediaDirectory.photos.rawValue])
    }

    private static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let largestSide = max(image.size.width, image.size.height)
        guard largestSide > maxDimension else { return image }
        let scale = maxDimension / largestSide
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
