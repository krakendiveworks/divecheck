import Foundation

/// One destination DiveCheck can automatically back up its data to --
/// picked in Settings > Backup & Sync. `SyncManager` talks to whichever
/// backend is active purely through this protocol, so it never needs to
/// know whether it's actually iCloud Drive or Google Drive on the other
/// end -- see iCloudDriveBackend.swift and GoogleDriveBackend.swift.
///
/// Both backends store everything in one flat, app-owned remote folder --
/// the full-state snapshot (see AppStoreSnapshot.swift) plus every file
/// from PhotoStorage/DocumentStorage, each keyed by a unique remote
/// filename (see SyncManager's naming helpers). No subdirectories, no
/// per-record files -- simplest thing that can work correctly.
protocol CloudSyncBackend {
    init()

    /// Human-readable label for Settings -- e.g. "iCloud Drive", or the
    /// signed-in Google account's email once GoogleDriveBackend is wired
    /// up.
    var accountLabel: String { get }

    /// Uploads/overwrites the file at `remoteName`.
    func upload(_ data: Data, remoteName: String) async throws

    /// Downloads the file at `remoteName`, or nil if nothing's there yet.
    func download(remoteName: String) async throws -> Data?

    /// Every filename currently stored remotely -- used to know which
    /// local media files still need uploading, and which remote media
    /// files need pulling down to this device.
    func listRemoteFilenames() async throws -> Set<String>

    func delete(remoteName: String) async throws
}

/// Which cloud destination (if any) is active. Persisted via CloudSync so
/// the choice itself follows the user's other settings -- see
/// SyncManager.swift.
enum SyncProvider: String, Codable, CaseIterable {
    case none
    case iCloud
    case googleDrive

    var displayName: String {
        switch self {
        case .none: return "Off"
        case .iCloud: return "iCloud Drive"
        case .googleDrive: return "Google Drive"
        }
    }
}

enum SyncBackendError: LocalizedError {
    case notSignedIn
    case unavailable(String)

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Not signed in."
        case .unavailable(let reason):
            return reason
        }
    }
}

/// Which on-disk folder a synced media file belongs in -- PhotoStorage's
/// DivePhotos or DocumentStorage's DiveDocuments. Both backends keep every
/// synced file in one flat remote folder, so this gets baked into the
/// remote filename (see SyncManager.remoteName/parse) to make round-
/// tripping a downloaded file back to the right local folder unambiguous.
enum MediaDirectory: String, Codable {
    case photos
    case documents
}

extension Notification.Name {
    /// Posted by PhotoStorage/DocumentStorage whenever a file is written
    /// to disk (save, replace, or duplicate) -- userInfo: ["filename":
    /// String, "directory": MediaDirectory.rawValue]. SyncManager observes
    /// this to upload new/changed media without every call site needing to
    /// know sync exists.
    static let diveCheckMediaFileAdded = Notification.Name("DiveCheck.mediaFileAdded")

    /// Same userInfo shape as above, posted on delete.
    static let diveCheckMediaFileDeleted = Notification.Name("DiveCheck.mediaFileDeleted")
}
