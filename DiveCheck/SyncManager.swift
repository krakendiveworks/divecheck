import Foundation

/// Coordinates syncing AppStore's entire persisted state (see
/// AppStoreSnapshot.swift) plus every file in PhotoStorage/DocumentStorage
/// to whichever provider is picked in Settings > Backup & Sync. One shared
/// instance, wired up to the live AppStore once at launch (see
/// `AppStore.init`) and held for the app's lifetime.
///
/// Model: the whole app state is treated as a single JSON snapshot (same
/// idea as CloudSync's existing per-key iCloud sync, just widened to cover
/// everything, including photos/PDFs as separate flat files alongside it)
/// rather than diffing individual records. Conflict rule is last-full-
/// snapshot-wins by timestamp -- simplest thing that's correct for one
/// person's own devices, matching how CloudSync's per-key sync already
/// behaves today.
final class SyncManager: ObservableObject {
    static let shared = SyncManager()

    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncedAt: Date?
    @Published private(set) var lastError: String?
    @Published private(set) var accountLabel: String?
    @Published var provider: SyncProvider {
        didSet {
            guard oldValue != provider else { return }
            CloudSync.saveString(provider.rawValue, forKey: Keys.provider)
            activateBackend()
        }
    }

    weak var appStore: AppStore?
    private var backend: CloudSyncBackend?
    private var pendingPushTask: Task<Void, Never>?
    private var mediaAddedObserver: NSObjectProtocol?
    private var mediaDeletedObserver: NSObjectProtocol?
    private var providerChangeObserver: NSObjectProtocol?

    private enum Keys {
        static let provider = "DiveCheck.syncProvider"
        static let lastSyncedAt = "DiveCheck.syncLastSyncedAt"
    }

    private static let snapshotFilename = "DiveCheckData.json"

    private init() {
        provider = CloudSync.loadString(forKey: Keys.provider).flatMap(SyncProvider.init(rawValue:)) ?? .none
        // Deliberately UserDefaults only, NOT CloudSync -- this has to stay
        // purely local to this device. It previously went through
        // CloudSync.loadString/saveString like `provider` above, which
        // also mirrors the value into iCloud's key-value store -- meaning
        // a brand-new device would inherit another device's already-synced
        // "last applied" timestamp before ever actually downloading and
        // applying a snapshot itself. That made pull()'s newer-than check
        // (below) conclude "already up to date" and silently skip applying
        // real data on a fresh device -- exactly what happened testing on
        // a new iPad after the phone was already syncing.
        if let interval = UserDefaults.standard.object(forKey: Keys.lastSyncedAt) as? Double {
            lastSyncedAt = Date(timeIntervalSince1970: interval)
        }
        mediaAddedObserver = NotificationCenter.default.addObserver(forName: .diveCheckMediaFileAdded, object: nil, queue: .main) { [weak self] note in
            self?.handleMediaFileAdded(note)
        }
        mediaDeletedObserver = NotificationCenter.default.addObserver(forName: .diveCheckMediaFileDeleted, object: nil, queue: .main) { [weak self] note in
            self?.handleMediaFileDeleted(note)
        }
        // Picking a provider in Settings on one device pushes that choice
        // up through CloudSync's iCloud key-value store (see `provider`'s
        // didSet), same as any other setting -- but unlike AppStore's own
        // persisted fields, nothing was listening for that choice arriving
        // on a SECOND device. Without this, a fresh install (or the
        // Simulator) would only pick up "this account already has iCloud
        // Drive turned on" at the exact moment SyncManager.init() happens
        // to run after the key-value store's initial download finishes --
        // easy to miss on first launch, and never rechecked afterward.
        // Mirrors AppStore's own cloudSyncObserver pattern below.
        providerChangeObserver = NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: CloudSync.store, queue: .main) { [weak self] notification in
            self?.handleExternalProviderChange(notification)
        }
        activateBackend()
    }

    deinit {
        if let mediaAddedObserver { NotificationCenter.default.removeObserver(mediaAddedObserver) }
        if let mediaDeletedObserver { NotificationCenter.default.removeObserver(mediaDeletedObserver) }
        if let providerChangeObserver { NotificationCenter.default.removeObserver(providerChangeObserver) }
    }

    private func handleExternalProviderChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
              changedKeys.contains(Keys.provider),
              let newProvider = CloudSync.loadString(forKey: Keys.provider).flatMap(SyncProvider.init(rawValue:)),
              newProvider != provider
        else { return }
        provider = newProvider
    }

    // MARK: - Provider lifecycle

    private func activateBackend() {
        switch provider {
        case .none:
            backend = nil
            accountLabel = nil
        case .iCloud:
            backend = iCloudDriveBackend()
            accountLabel = backend?.accountLabel
            Task { await pull() }
        }
    }

    // MARK: - Push (local -> remote)

    /// Call after any local change AppStore persists (wired up centrally
    /// in CloudSync.swift, so every persisted field is covered without
    /// AppStore's individual save methods needing to know sync exists).
    /// Debounces so rapid edits collapse into one upload a few seconds
    /// after things go quiet, instead of uploading on every keystroke.
    func scheduleSync() {
        guard provider != .none else { return }
        pendingPushTask?.cancel()
        pendingPushTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            await push()
        }
    }

    /// Explicit "Sync Now" from Settings -- pushes immediately rather than
    /// waiting out the debounce.
    func syncNow() async {
        pendingPushTask?.cancel()
        await pull()
        await push()
    }

    private func push() async {
        guard let backend, let appStore else { return }
        await MainActor.run { isSyncing = true }
        let snapshot = await MainActor.run { appStore.makeSyncSnapshot() }
        do {
            let data = try JSONEncoder.diveCheckSync.encode(snapshot)
            try await backend.upload(data, remoteName: Self.snapshotFilename)
            try await uploadPendingMedia(backend: backend)
            await recordSuccessfulSync(at: snapshot.modifiedAt)
        } catch {
            await MainActor.run { lastError = error.localizedDescription }
        }
        await MainActor.run { isSyncing = false }
    }

    // MARK: - Pull (remote -> local)

    /// Downloads the remote snapshot (if any) and, when it's newer than
    /// what's already loaded locally, overwrites local state with it.
    /// Downloads any media files referenced remotely that aren't on disk
    /// yet first, so the applied snapshot never briefly points at photos
    /// that haven't arrived. Called on provider activation and from
    /// Settings' "Sync Now".
    func pull() async {
        guard let backend, let appStore else { return }
        await MainActor.run { isSyncing = true }
        do {
            guard let data = try await backend.download(remoteName: Self.snapshotFilename) else {
                // Nothing remote yet -- seed it with whatever's local.
                await MainActor.run { lastError = nil }
                await MainActor.run { isSyncing = false }
                await push()
                return
            }
            let snapshot = try JSONDecoder.diveCheckSync.decode(AppStoreSnapshot.self, from: data)
            let localTimestamp = lastSyncedAt
            if localTimestamp == nil || snapshot.modifiedAt > localTimestamp! {
                try await downloadAllMedia(backend: backend)
                await MainActor.run { appStore.applySyncSnapshot(snapshot) }
                await recordSuccessfulSync(at: snapshot.modifiedAt)
            } else {
                await MainActor.run { lastError = nil }
            }
        } catch {
            await MainActor.run { lastError = error.localizedDescription }
        }
        await MainActor.run { isSyncing = false }
    }

    @MainActor
    private func recordSuccessfulSync(at date: Date) {
        lastSyncedAt = date
        lastError = nil
        // Local-only -- see the doc comment on the matching read in init().
        UserDefaults.standard.set(date.timeIntervalSince1970, forKey: Keys.lastSyncedAt)
    }

    // MARK: - Media files

    private func handleMediaFileAdded(_ note: Notification) {
        guard provider != .none, let backend,
              let filename = note.userInfo?["filename"] as? String,
              let directoryRaw = note.userInfo?["directory"] as? String,
              let directory = MediaDirectory(rawValue: directoryRaw)
        else { return }
        let remoteName = Self.remoteName(filename: filename, directory: directory)
        let localURL = Self.localURL(filename: filename, directory: directory)
        Task {
            guard let data = try? Data(contentsOf: localURL) else { return }
            try? await backend.upload(data, remoteName: remoteName)
        }
    }

    private func handleMediaFileDeleted(_ note: Notification) {
        guard provider != .none, let backend,
              let filename = note.userInfo?["filename"] as? String,
              let directoryRaw = note.userInfo?["directory"] as? String,
              let directory = MediaDirectory(rawValue: directoryRaw)
        else { return }
        let remoteName = Self.remoteName(filename: filename, directory: directory)
        Task {
            try? await backend.delete(remoteName: remoteName)
        }
    }

    private func uploadPendingMedia(backend: CloudSyncBackend) async throws {
        let remoteFilenames = (try? await backend.listRemoteFilenames()) ?? []
        for directory in [MediaDirectory.photos, .documents] {
            let localDir = Self.localDirectoryURL(for: directory)
            guard let files = try? FileManager.default.contentsOfDirectory(at: localDir, includingPropertiesForKeys: nil) else { continue }
            for fileURL in files {
                let remoteName = Self.remoteName(filename: fileURL.lastPathComponent, directory: directory)
                guard !remoteFilenames.contains(remoteName) else { continue }
                guard let data = try? Data(contentsOf: fileURL) else { continue }
                try? await backend.upload(data, remoteName: remoteName)
            }
        }
    }

    private func downloadAllMedia(backend: CloudSyncBackend) async throws {
        let remoteFilenames = (try? await backend.listRemoteFilenames()) ?? []
        for remoteName in remoteFilenames {
            guard let (filename, directory) = Self.parse(remoteName: remoteName) else { continue }
            let localURL = Self.localURL(filename: filename, directory: directory)
            guard !FileManager.default.fileExists(atPath: localURL.path) else { continue }
            guard let data = try? await backend.download(remoteName: remoteName) else { continue }
            try? data.write(to: localURL)
        }
    }

    // MARK: - Naming helpers

    static func remoteName(filename: String, directory: MediaDirectory) -> String {
        "\(directory.rawValue)__\(filename)"
    }

    static func parse(remoteName: String) -> (filename: String, directory: MediaDirectory)? {
        guard remoteName != snapshotFilename else { return nil }
        let parts = remoteName.components(separatedBy: "__")
        guard parts.count >= 2, let directory = MediaDirectory(rawValue: parts[0]) else { return nil }
        let filename = parts.dropFirst().joined(separator: "__")
        return (filename, directory)
    }

    private static func localDirectoryURL(for directory: MediaDirectory) -> URL {
        directory == .photos ? PhotoStorage.directory : DocumentStorage.directory
    }

    private static func localURL(filename: String, directory: MediaDirectory) -> URL {
        localDirectoryURL(for: directory).appendingPathComponent(filename)
    }
}
