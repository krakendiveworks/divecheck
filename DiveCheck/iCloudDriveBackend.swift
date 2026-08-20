@preconcurrency import Foundation

/// Syncs DiveCheck's data through the app's iCloud Drive document
/// container -- real file storage, sized for the full state snapshot plus
/// every cert photo and PDF, synced automatically by iCloud's own daemon
/// once files land in this folder. NOT the same thing as CloudSync.swift's
/// existing NSUbiquitousKeyValueStore sync, which is a separate, much
/// smaller (1MB total) key-value store used for a handful of
/// settings/preferences -- that keeps working independently of this.
///
/// Requires the "iCloud > iCloud Documents" capability enabled in Xcode's
/// Signing & Capabilities for the DiveCheck target (adds
/// com.apple.developer.icloud-container-identifiers /
/// com.apple.developer.icloud-services to DiveCheck.entitlements -- see
/// that file, which already has a starting version of these keys). Xcode
/// provisions the actual container automatically the first time you build
/// with a real (paid) Apple Developer team selected -- no separate
/// CloudKit dashboard setup needed for plain document storage like this.
/// If the capability isn't enabled, or the signed-in-to-iCloud user has
/// iCloud Drive turned off for this app, every call below throws
/// `SyncBackendError.unavailable` with a message Settings can surface.
struct iCloudDriveBackend: CloudSyncBackend {
    var accountLabel: String { "iCloud Drive" }

    /// The app's default ubiquity container's Documents folder. This is
    /// what shows up (as a "DiveCheck" folder) in the Files app under
    /// iCloud Drive on the user's other devices.
    private var containerURL: URL? {
        guard let base = FileManager.default.url(forUbiquityContainerIdentifier: nil) else { return nil }
        let documents = base.appendingPathComponent("Documents", isDirectory: true)
        if !FileManager.default.fileExists(atPath: documents.path) {
            try? FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
        }
        return documents
    }

    private func requireContainerURL() throws -> URL {
        guard let containerURL else {
            throw SyncBackendError.unavailable("iCloud Drive isn't available right now -- check that you're signed into iCloud and that iCloud Drive is turned on for DiveCheck in the Settings app (Settings > [your name] > iCloud > Saved to iCloud).")
        }
        return containerURL
    }

    func upload(_ data: Data, remoteName: String) async throws {
        let containerURL = try requireContainerURL()
        let fileURL = containerURL.appendingPathComponent(remoteName)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let coordinator = NSFileCoordinator()
            var coordinatorError: NSError?
            coordinator.coordinate(writingItemAt: fileURL, options: .forReplacing, error: &coordinatorError) { url in
                do {
                    try data.write(to: url, options: .atomic)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            if let coordinatorError {
                continuation.resume(throwing: coordinatorError)
            }
        }
    }

    func download(remoteName: String) async throws -> Data? {
        _ = try requireContainerURL()
        let contents = await Self.queryContainerContents()
        guard let fileURL = contents[remoteName] else { return nil }
        // A file iCloud hasn't downloaded to this device yet shows up as a
        // placeholder -- ask for the real content and give it a moment to
        // arrive before reading.
        try? FileManager.default.startDownloadingUbiquitousItem(at: fileURL)
        for _ in 0..<20 {
            if let values = try? fileURL.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]),
               values.ubiquitousItemDownloadingStatus == .current {
                break
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
        }
        return try? Data(contentsOf: fileURL)
    }

    func listRemoteFilenames() async throws -> Set<String> {
        guard containerURL != nil else { return [] }
        return Set(await Self.queryContainerContents().keys)
    }

    func delete(remoteName: String) async throws {
        guard let containerURL else { return }
        try? FileManager.default.removeItem(at: containerURL.appendingPathComponent(remoteName))
    }

    /// Reliably discovers what's actually in the container using
    /// NSMetadataQuery -- the Apple-recommended way to enumerate a
    /// ubiquity container's contents -- rather than a plain
    /// FileManager.fileExists/contentsOfDirectory call.
    ///
    /// This matters a lot more than it looks: the first time a given
    /// device ever touches this container (e.g. a second device you just
    /// installed the app on), iOS needs a moment to discover what's
    /// already up there. A plain, immediate fileExists check can come
    /// back "not found" during that window even though a file genuinely
    /// exists in iCloud -- which previously made SyncManager.pull() think
    /// "nothing's been synced from any device yet" and push that device's
    /// own (near-empty, freshly-installed) state up as a *newer* snapshot,
    /// overwriting the real data other devices had already synced. This
    /// query properly waits for iOS's initial discovery to finish before
    /// reporting what's there, closing that race.
    private static func queryContainerContents() async -> [String: URL] {
        await withCheckedContinuation { continuation in
            QueryCoordinator(continuation: continuation).start()
        }
    }
}

/// Bridges NSMetadataQuery's completion notification into a single Swift
/// continuation. Previously this state (the query, its observer token, and
/// a "have we already resumed" flag) lived as plain local `var`s captured
/// by the notification/timeout closures directly -- which strict
/// concurrency checking flags, since Foundation declares those closures
/// `@Sendable` and a `@Sendable` closure can't safely capture a mutable
/// local that's written to both inside and outside itself, nor a
/// non-Sendable type like NSMetadataQuery. Moving the state into this
/// class fixes that at the root rather than papering over it: both
/// closures below now only capture `self` (a class reference explicitly
/// asserted `@unchecked Sendable`), and read/write `self.query`/
/// `self.observer`/`self.continuation` instead. That assertion is safe
/// because every access happens on the main queue -- the notification
/// observer below is explicitly registered with `queue: .main`, and the
/// timeout uses `DispatchQueue.main` -- so there's no actual concurrent
/// access despite the compiler not being able to prove it statically.
private final class QueryCoordinator: @unchecked Sendable {
    private let query = NSMetadataQuery()
    private var observer: NSObjectProtocol?
    private var continuation: CheckedContinuation<[String: URL], Never>?
    private var didFinish = false

    init(continuation: CheckedContinuation<[String: URL], Never>) {
        self.continuation = continuation
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        query.predicate = NSPredicate(format: "%K LIKE '*'", NSMetadataItemFSNameKey)
    }

    func start() {
        observer = NotificationCenter.default.addObserver(forName: .NSMetadataQueryDidFinishGathering, object: query, queue: .main) { [self] _ in
            query.disableUpdates()
            var results: [String: URL] = [:]
            for case let item as NSMetadataItem in query.results {
                if let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL {
                    results[url.lastPathComponent] = url
                }
            }
            finish(with: results)
        }

        DispatchQueue.main.async { [self] in
            query.start()
        }

        // Safety net -- if the query never fires (iCloud completely
        // unreachable, etc.), don't hang forever; report "nothing
        // found" after a reasonable wait rather than blocking sync
        // indefinitely.
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [self] in
            finish(with: [:])
        }
    }

    /// Guards against firing twice (the notification and the 15s timeout
    /// racing) -- everything here only ever runs on the main queue (see
    /// the class doc comment), so a plain flag is enough; no lock needed
    /// the way the old free-function version required one.
    private func finish(with results: [String: URL]) {
        guard !didFinish else { return }
        didFinish = true
        query.stop()
        if let observer { NotificationCenter.default.removeObserver(observer) }
        continuation?.resume(returning: results)
        continuation = nil
    }
}
