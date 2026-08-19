import Foundation

/// A complete, self-contained snapshot of every record AppStore persists --
/// this is what "all captured/saved data" means for Backup & Sync: every
/// checklist, dive log entry, piece of equipment, saved location/buddy,
/// EAP, certification, training record, dive computer, and the Diver
/// Medical ID, plus every preference/flag alongside them. Deliberately
/// excludes the photo/PDF file bytes themselves -- those sync separately
/// as flat files alongside this snapshot (see SyncManager.swift) rather
/// than being embedded as base64 here, for the same reason
/// PhotoStorage/DocumentStorage already keep them out of CloudSync's JSON
/// blobs: keeping this snapshot small and fast to encode/decode on every
/// save.
struct AppStoreSnapshot: Codable {
    /// When this snapshot was built. SyncManager compares this against
    /// what it last pulled/pushed to decide whether a remote snapshot is
    /// newer than local state -- last-full-snapshot-wins across
    /// devices/providers, the same per-key behavior CloudSync's existing
    /// iCloud key-value sync already has today, just applied to the whole
    /// state at once instead of per field.
    var modifiedAt: Date

    var categories: [DiveCategory]
    var savedChecklists: [SavedChecklist]
    var equipmentLocker: [EquipmentItem]
    var diveLogEntries: [DiveLogEntry]
    var savedLocations: [SavedLocation]
    var savedBuddies: [DiveBuddy]
    var emergencyActionPlans: [EmergencyActionPlan]
    var certifications: [Certification]
    var savedCertifications: [SavedCertification]
    var trainingAgencies: [TrainingAgency]
    var isTrainingSectionEnabled: Bool
    var trainingProfessionalAgency: String?
    var trainingProfessionalNumber: String?
    var diveComputers: [DiveComputer]
    var diverMedicalID: DiverMedicalID?
    var savedDiverMedicalIDs: [SavedDiverMedicalID]
    var defaultDepthUnit: DepthUnit
    var defaultTemperatureUnit: TemperatureUnit
    var defaultWeightUnit: WeightUnit
    var isAdminModeEnabled: Bool
    var hasAcknowledgedDisclaimer: Bool
    var disclaimerAcknowledgedDate: Date?
}

extension AppStore {
    /// Builds a snapshot of everything currently in memory, stamped with
    /// the current time.
    func makeSyncSnapshot() -> AppStoreSnapshot {
        AppStoreSnapshot(
            modifiedAt: Date(),
            categories: categories,
            savedChecklists: savedChecklists,
            equipmentLocker: equipmentLocker,
            diveLogEntries: diveLogEntries,
            savedLocations: savedLocations,
            savedBuddies: savedBuddies,
            emergencyActionPlans: emergencyActionPlans,
            certifications: certifications,
            savedCertifications: savedCertifications,
            trainingAgencies: trainingAgencies,
            isTrainingSectionEnabled: isTrainingSectionEnabled,
            trainingProfessionalAgency: trainingProfessionalAgency,
            trainingProfessionalNumber: trainingProfessionalNumber,
            diveComputers: diveComputers,
            diverMedicalID: diverMedicalID,
            savedDiverMedicalIDs: savedDiverMedicalIDs,
            defaultDepthUnit: defaultDepthUnit,
            defaultTemperatureUnit: defaultTemperatureUnit,
            defaultWeightUnit: defaultWeightUnit,
            isAdminModeEnabled: isAdminModeEnabled,
            hasAcknowledgedDisclaimer: hasAcknowledgedDisclaimer,
            disclaimerAcknowledgedDate: disclaimerAcknowledgedDate
        )
    }

    /// Overwrites every persisted property with what's in `snapshot` --
    /// used when a pulled remote snapshot turns out to be newer than local
    /// state. Each property's own didSet still fires as normal (so the
    /// usual local-save path runs and every screen bound to AppStore
    /// updates immediately), but `CloudSync.isApplyingRemoteSnapshot`
    /// suppresses the redundant re-push those didSets would otherwise
    /// trigger -- see CloudSync.swift.
    func applySyncSnapshot(_ snapshot: AppStoreSnapshot) {
        CloudSync.isApplyingRemoteSnapshot = true
        defer { CloudSync.isApplyingRemoteSnapshot = false }

        categories = Self.reordered(snapshot.categories)
        savedChecklists = snapshot.savedChecklists
        equipmentLocker = snapshot.equipmentLocker
        diveLogEntries = snapshot.diveLogEntries
        savedLocations = snapshot.savedLocations
        savedBuddies = snapshot.savedBuddies
        emergencyActionPlans = snapshot.emergencyActionPlans
        certifications = snapshot.certifications
        savedCertifications = snapshot.savedCertifications
        trainingAgencies = snapshot.trainingAgencies
        isTrainingSectionEnabled = snapshot.isTrainingSectionEnabled
        trainingProfessionalAgency = snapshot.trainingProfessionalAgency
        trainingProfessionalNumber = snapshot.trainingProfessionalNumber
        diveComputers = snapshot.diveComputers
        diverMedicalID = snapshot.diverMedicalID
        savedDiverMedicalIDs = snapshot.savedDiverMedicalIDs
        defaultDepthUnit = snapshot.defaultDepthUnit
        defaultTemperatureUnit = snapshot.defaultTemperatureUnit
        defaultWeightUnit = snapshot.defaultWeightUnit
        isAdminModeEnabled = snapshot.isAdminModeEnabled
        hasAcknowledgedDisclaimer = snapshot.hasAcknowledgedDisclaimer
        disclaimerAcknowledgedDate = snapshot.disclaimerAcknowledgedDate
    }
}

extension JSONEncoder {
    static let diveCheckSync: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

extension JSONDecoder {
    static let diveCheckSync: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
