import Foundation

/// Lightweight iCloud sync for AppStore's data, built on
/// `NSUbiquitousKeyValueStore` rather than a full CloudKit/Core Data
/// migration. Every array AppStore persists already round-trips through
/// JSON into UserDefaults, so syncing is just mirroring that same JSON blob
/// into iCloud's key-value store in addition to UserDefaults, and reacting
/// when another of the user's devices changes it.
///
/// Tradeoffs, so future-you doesn't have to rediscover them:
/// - `NSUbiquitousKeyValueStore` caps out around 1MB total across all keys
///   and 1MB per value. That's plenty for dive logs/equipment/locations/EAPs
///   as text (dive log photos stay device-local instead of syncing), but it
///   is NOT plenty once you add the seed-derived content trees on top --
///   see `saveLocalOnly`/`loadLocalOnly` below for why `categories` and
///   `trainingAgencies` specifically don't go through here anymore.
/// - This requires no CloudKit container or dashboard setup -- just the
///   "iCloud" capability with "Key-value storage" checked in Xcode's
///   Signing & Capabilities for the DiveCheck target (which needs a real
///   Apple Developer team selected). Without that capability enabled, these
///   calls are harmless no-ops and the app behaves exactly as it did before
///   (UserDefaults-only, this device only).
enum CloudSync {
    static let store = NSUbiquitousKeyValueStore.default

    /// Set by AppStore.applySyncSnapshot (see AppStoreSnapshot.swift) while
    /// overwriting local state from a newly-pulled remote Backup & Sync
    /// snapshot, so the didSet-triggered local saves that overwrite fires
    /// don't turn around and immediately re-push the exact same data back
    /// up to SyncManager.
    static var isApplyingRemoteSnapshot = false

    /// Tells SyncManager (see SyncManager.swift) that persisted state
    /// changed, so it can schedule pushing an updated Backup & Sync
    /// snapshot -- called from every save method below, which between them
    /// cover everything AppStore persists, so this one hook is all Backup
    /// & Sync needs to stay current with the rest of the app.
    static func notifySyncManager() {
        guard !isApplyingRemoteSnapshot else { return }
        SyncManager.shared.scheduleSync()
    }

    /// Encodes `value` and writes it to both UserDefaults (so the next
    /// launch reads instantly even if iCloud is unavailable) and the iCloud
    /// key-value store (so the user's other devices pick it up).
    static func save<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
        store.set(data, forKey: key)
        notifySyncManager()
    }

    /// Loads `key`, preferring the iCloud copy so a second device (or a
    /// reinstall) picks up data that already exists in the cloud. Falls
    /// back to the local UserDefaults copy when iCloud has nothing yet --
    /// either the iCloud capability isn't enabled, or this is the very
    /// first save anywhere -- and in that case pushes the local copy up to
    /// iCloud immediately so it starts syncing from here on.
    static func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        if let data = store.data(forKey: key), let decoded = try? JSONDecoder().decode(T.self, from: data) {
            UserDefaults.standard.set(data, forKey: key)
            return decoded
        }
        if let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode(T.self, from: data) {
            store.set(data, forKey: key)
            return decoded
        }
        return nil
    }

    /// Mirrors a plain string default (e.g. a unit preference) to iCloud
    /// alongside UserDefaults, same idea as `save(_:forKey:)` but for
    /// values that are already strings rather than JSON blobs.
    static func saveString(_ value: String, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
        store.set(value, forKey: key)
        notifySyncManager()
    }

    static func loadString(forKey key: String) -> String? {
        if let value = store.string(forKey: key) {
            UserDefaults.standard.set(value, forKey: key)
            return value
        }
        if let value = UserDefaults.standard.string(forKey: key) {
            store.set(value, forKey: key)
            return value
        }
        return nil
    }

    /// Same idea as `saveString`/`loadString`, for plain Bool settings (e.g.
    /// Admin Mode) that don't need JSON encoding.
    static func saveBool(_ value: Bool, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
        store.set(value, forKey: key)
        notifySyncManager()
    }

    /// Returns nil (rather than `false`) when the key has never been set on
    /// either side, so callers can tell "never configured" apart from
    /// "explicitly turned off" and apply their own default.
    static func loadBool(forKey key: String) -> Bool? {
        if store.object(forKey: key) != nil {
            let value = store.bool(forKey: key)
            UserDefaults.standard.set(value, forKey: key)
            return value
        }
        if UserDefaults.standard.object(forKey: key) != nil {
            let value = UserDefaults.standard.bool(forKey: key)
            store.set(value, forKey: key)
            return value
        }
        return nil
    }

    /// Call once at app/store startup, before the first `load` call, so
    /// `NSUbiquitousKeyValueStore` has a chance to pull down whatever's
    /// already in iCloud from another device.
    static func synchronize() {
        store.synchronize()
    }

    /// UserDefaults-only persistence -- no iCloud involved at all.
    ///
    /// `categories` and `trainingAgencies` (the main checklist tree and the
    /// Training tree) used to round-trip through `save`/`load` like
    /// everything else, but they're the two largest things AppStore
    /// persists by far, and they kept growing as more starter content got
    /// added (SDI/PADI checklists, the whole Divemaster program, etc). Once
    /// their combined size got close to `NSUbiquitousKeyValueStore`'s 1MB
    /// total-across-all-keys quota, writes started silently failing or
    /// getting evicted -- which looked exactly like "a whole category or
    /// checklist keeps vanishing again after it was pushed and confirmed
    /// working," on whichever device had the most real iCloud history to
    /// collide with (typically a physical device that's actually been used
    /// for a while, not a fresh Simulator). A version-marker guard closed
    /// one specific race in that space but couldn't fix a hard quota limit.
    ///
    /// The real fix is to stop asking a 1MB key-value store to hold
    /// megabytes of seed-derived content it was never sized for. Since
    /// every device already regenerates the same starter content from
    /// `SeedData`/`TrainingSeedData` locally, there's nothing to gain from
    /// syncing the *structure* across devices anyway -- only the checkmarks
    /// and custom edits on top of it would be worth syncing, and this app
    /// doesn't currently split those apart from the structure. Until it
    /// does, `categories` and `trainingAgencies` stay purely local
    /// (UserDefaults, no size cap worth worrying about at this scale) and
    /// everything else -- dive log, equipment, locations, buddies, EAPs,
    /// certifications, dive computers, medical ID, preferences -- keeps
    /// syncing via `save`/`load` as before.
    static func saveLocalOnly<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
        notifySyncManager()
    }

    static func loadLocalOnly<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
