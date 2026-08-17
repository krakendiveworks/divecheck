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
    private static var directory: URL {
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
