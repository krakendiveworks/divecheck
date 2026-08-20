import Foundation
import SwiftUI

/// Owns the full checklist tree (categories -> subcategories/checklists ->
/// items) and persists it to disk as JSON. Provides Binding helpers so leaf
/// views (ChecklistDetailView) can edit deeply nested state directly.
final class AppStore: ObservableObject {
    @Published var categories: [DiveCategory] {
        didSet { save() }
    }

    /// Every category shown under Plan > Checklists -- everything in
    /// `categories` except "Scuba Class Packing", which is surfaced as the
    /// first entry under Training instead (see `scubaClassPackingCategory`
    /// below and TrainingAgenciesListView). It's still just a regular
    /// DiveCategory stored in `categories` like any other -- persistence,
    /// reseeding, and sync are all untouched by this; only which screen
    /// displays it changes.
    var checklistCategories: [DiveCategory] {
        categories.filter { $0.name != SeedData.scubaClassPackingCategoryName }
    }

    /// The "Scuba Class Packing" category, surfaced as the first entry
    /// under Training -- see `checklistCategories` above.
    var scubaClassPackingCategory: DiveCategory? {
        categories.first { $0.name == SeedData.scubaClassPackingCategoryName }
    }

    @Published var savedChecklists: [SavedChecklist] {
        didSet { saveHistory() }
    }

    @Published var equipmentLocker: [EquipmentItem] {
        didSet { saveEquipment() }
    }

    @Published var diveLogEntries: [DiveLogEntry] {
        didSet { saveDiveLog() }
    }

    @Published var savedLocations: [SavedLocation] {
        didSet { saveLocations() }
    }

    @Published var savedBuddies: [DiveBuddy] {
        didSet { saveBuddies() }
    }

    @Published var emergencyActionPlans: [EmergencyActionPlan] {
        didSet { saveEAPs() }
    }

    @Published var certifications: [Certification] {
        didSet { saveCertifications() }
    }

    /// Saved snapshots of certifications -- "Save to History" on
    /// CertificationDetailView, mirroring `savedChecklists` above.
    @Published var savedCertifications: [SavedCertification] {
        didSet { saveSavedCertifications() }
    }

    /// Training section content (Settings > Training toggle) -- grouped by
    /// agency, then certification level, then dive/skill checklist. Its own
    /// independent tree with its own reseed-version gate (see
    /// TrainingSeedData.contentVersion) so adding a new agency later
    /// doesn't force a reseed of the main checklist tree, equipment, etc.
    @Published var trainingAgencies: [TrainingAgency] {
        didSet { saveTrainingAgencies() }
    }

    /// Shows/hides the Training row on the main menu. Off by default --
    /// this section is meant for instructors/divemasters tracking
    /// certification requirements, not general use, so SettingsView gates
    /// turning it on behind entering `trainingProfessionalAgency`/
    /// `trainingProfessionalNumber` below. That gate lives in the UI layer
    /// (SettingsView's toggle binding); AppStore itself doesn't re-check it
    /// here, so this stays a plain Bool like the app's other feature flags.
    @Published var isTrainingSectionEnabled: Bool {
        didSet { CloudSync.saveBool(isTrainingSectionEnabled, forKey: trainingSectionEnabledKey) }
    }

    /// Certifying agency the diver is credentialed with (e.g. "PADI",
    /// "SDI") -- required, together with `trainingProfessionalNumber`
    /// below, before SettingsView allows turning on `isTrainingSectionEnabled`.
    /// Nil until the diver fills it in; shown read-only in Settings >
    /// Training once set, the same way `disclaimerAcknowledgedDate` is
    /// shown read-only in Settings > Disclaimer.
    @Published var trainingProfessionalAgency: String? {
        didSet {
            if let trainingProfessionalAgency, !trainingProfessionalAgency.isEmpty {
                CloudSync.saveString(trainingProfessionalAgency, forKey: trainingProfessionalAgencyKey)
            }
        }
    }

    /// The diver's professional/instructor number with `trainingProfessionalAgency`
    /// above -- see that property's doc comment.
    @Published var trainingProfessionalNumber: String? {
        didSet {
            if let trainingProfessionalNumber, !trainingProfessionalNumber.isEmpty {
                CloudSync.saveString(trainingProfessionalNumber, forKey: trainingProfessionalNumberKey)
            }
        }
    }

    /// Saved dive computers -- see DiveComputer.swift for why these exist
    /// separately from the raw `DiveLogEntry.sourceDevice` string.
    @Published var diveComputers: [DiveComputer] {
        didSet { saveDiveComputers() }
    }

    /// A single personal medical ID card, not per-Location like EAPs -- for
    /// when the diver themselves is the one who's hurt. Nil until the user
    /// fills one in.
    @Published var diverMedicalID: DiverMedicalID? {
        didSet { saveMedicalID() }
    }

    /// Saved snapshots of the Diver Medical ID card -- "Save to History"
    /// on DiverMedicalIDView, mirroring `savedChecklists` above.
    @Published var savedDiverMedicalIDs: [SavedDiverMedicalID] {
        didSet { saveSavedDiverMedicalIDs() }
    }

    /// Default units applied to new Dive Log entries only -- changing a
    /// default doesn't retroactively touch already-logged dives, same as
    /// picking a different unit on an existing entry doesn't affect others.
    @Published var defaultDepthUnit: DepthUnit {
        didSet { CloudSync.saveString(defaultDepthUnit.rawValue, forKey: defaultDepthUnitKey) }
    }
    @Published var defaultTemperatureUnit: TemperatureUnit {
        didSet { CloudSync.saveString(defaultTemperatureUnit.rawValue, forKey: defaultTemperatureUnitKey) }
    }
    @Published var defaultWeightUnit: WeightUnit {
        didSet { CloudSync.saveString(defaultWeightUnit.rawValue, forKey: defaultWeightUnitKey) }
    }

    /// Unlocks Dive Log multi-select (Select All, bulk delete, bulk edit --
    /// see DiveLogListView/BulkEditDiveLogView). Off by default; this is
    /// the kind of "affects lots of entries at once" power-user toggle
    /// that shouldn't be one accidental tap away from the normal Dive Log
    /// screen.
    @Published var isAdminModeEnabled: Bool {
        didSet { CloudSync.saveBool(isAdminModeEnabled, forKey: adminModeKey) }
    }

    /// Gates the whole app behind DisclaimerView until the diver explicitly
    /// accepts it -- false (never shown/accepted) for a brand-new install,
    /// and synced via iCloud like the other flags below so acknowledging
    /// it on one device doesn't re-prompt on another.
    @Published var hasAcknowledgedDisclaimer: Bool {
        didSet { CloudSync.saveBool(hasAcknowledgedDisclaimer, forKey: disclaimerAcknowledgedKey) }
    }

    /// When the diver accepted the disclaimer -- nil until they do. Shown
    /// (read-only) in the Settings > Disclaimer section alongside the
    /// disclaimer text itself, stored as an ISO 8601 string since CloudSync
    /// has no dedicated Date helper.
    @Published var disclaimerAcknowledgedDate: Date? {
        didSet {
            if let disclaimerAcknowledgedDate {
                CloudSync.saveString(Self.dateFormatter.string(from: disclaimerAcknowledgedDate), forKey: disclaimerAcknowledgedDateKey)
            }
        }
    }

    private static let dateFormatter = ISO8601DateFormatter()

    /// `categories` is persisted via `CloudSync.saveLocalOnly`/
    /// `loadLocalOnly` (UserDefaults only, no iCloud) -- see the doc
    /// comment on those for why.
    private let storageKey = "DiveCheck.categories.v2"
    private let historyKey = "DiveCheck.history.v1"
    private let seedVersionKey = "DiveCheck.seedVersion"
    private let equipmentKey = "DiveCheck.equipment.v1"
    private let diveLogKey = "DiveCheck.divelog.v1"
    private let locationsKey = "DiveCheck.locations.v1"
    private let buddiesKey = "DiveCheck.buddies.v1"
    private let eapKey = "DiveCheck.eap.v1"
    private let certificationsKey = "DiveCheck.certifications.v1"
    private let savedCertificationsKey = "DiveCheck.savedCertifications.v1"
    /// Also local-only (see `storageKey` above) -- same reasoning, and the
    /// Training tree is the other half of what was pushing the iCloud
    /// key-value store toward its quota.
    private let trainingAgenciesKey = "DiveCheck.trainingAgencies.v1"
    private let trainingSeedVersionKey = "DiveCheck.trainingSeedVersion"
    private let trainingSectionEnabledKey = "DiveCheck.trainingSectionEnabled"
    private let trainingProfessionalAgencyKey = "DiveCheck.trainingProfessionalAgency"
    private let trainingProfessionalNumberKey = "DiveCheck.trainingProfessionalNumber"
    private let diveComputersKey = "DiveCheck.divecomputers.v1"
    private let medicalIDKey = "DiveCheck.medicalID.v1"
    private let savedMedicalIDsKey = "DiveCheck.savedMedicalIDs.v1"
    private let defaultDepthUnitKey = "DiveCheck.defaultDepthUnit"
    private let defaultTemperatureUnitKey = "DiveCheck.defaultTemperatureUnit"
    private let defaultWeightUnitKey = "DiveCheck.defaultWeightUnit"
    private let adminModeKey = "DiveCheck.adminModeEnabled"
    private let disclaimerAcknowledgedKey = "DiveCheck.disclaimerAcknowledged.v1"
    private let disclaimerAcknowledgedDateKey = "DiveCheck.disclaimerAcknowledgedDate.v1"

    /// Opaque token for the iCloud external-change observer, removed in
    /// `deinit`.
    private var cloudSyncObserver: NSObjectProtocol?

    init() {
        // Pull down whatever's already in iCloud (from another of the
        // user's devices) before reading anything below, so a fresh
        // install or second device sees synced data on first launch rather
        // than starting empty. Harmless no-op if the iCloud capability
        // isn't enabled -- see CloudSync.swift.
        CloudSync.synchronize()

        // Persisted checklist data survives between launches (so your
        // checkmarks and any custom items stick around), but that means an
        // app update with new starter content would otherwise never be
        // seen — the old saved copy would just keep loading forever. This
        // version gate forces a one-time reseed whenever the bundled
        // starter content changes; bump SeedData.contentVersion any time
        // the starter checklists themselves are edited.
        let storedVersion = UserDefaults.standard.integer(forKey: seedVersionKey)
        let needsReseed = storedVersion < SeedData.contentVersion

        if !needsReseed,
           let decoded = CloudSync.loadLocalOnly([DiveCategory].self, forKey: storageKey),
           !decoded.isEmpty {
            categories = Self.reordered(decoded)
        } else {
            categories = Self.reordered(SeedData.makeCategories())
        }
        UserDefaults.standard.set(SeedData.contentVersion, forKey: seedVersionKey)

        savedChecklists = CloudSync.load([SavedChecklist].self, forKey: historyKey) ?? []
        equipmentLocker = CloudSync.load([EquipmentItem].self, forKey: equipmentKey) ?? []
        diveLogEntries = CloudSync.load([DiveLogEntry].self, forKey: diveLogKey) ?? []
        savedLocations = CloudSync.load([SavedLocation].self, forKey: locationsKey) ?? []
        savedBuddies = CloudSync.load([DiveBuddy].self, forKey: buddiesKey) ?? []
        emergencyActionPlans = CloudSync.load([EmergencyActionPlan].self, forKey: eapKey) ?? []
        certifications = CloudSync.load([Certification].self, forKey: certificationsKey) ?? []
        savedCertifications = CloudSync.load([SavedCertification].self, forKey: savedCertificationsKey) ?? []

        // Same reseed-gate idea as the main checklist tree above, but with
        // its own version key so bumping one doesn't force a reseed of the
        // other.
        let trainingStoredVersion = UserDefaults.standard.integer(forKey: trainingSeedVersionKey)
        let trainingNeedsReseed = trainingStoredVersion < TrainingSeedData.contentVersion

        if !trainingNeedsReseed,
           let decodedTraining = CloudSync.loadLocalOnly([TrainingAgency].self, forKey: trainingAgenciesKey),
           !decodedTraining.isEmpty {
            trainingAgencies = decodedTraining
        } else {
            trainingAgencies = TrainingSeedData.makeAgencies()
        }
        UserDefaults.standard.set(TrainingSeedData.contentVersion, forKey: trainingSeedVersionKey)

        diveComputers = CloudSync.load([DiveComputer].self, forKey: diveComputersKey) ?? []
        diverMedicalID = CloudSync.load(DiverMedicalID.self, forKey: medicalIDKey)
        savedDiverMedicalIDs = CloudSync.load([SavedDiverMedicalID].self, forKey: savedMedicalIDsKey) ?? []

        // Falls back to the same defaults DiveLogEntry itself already used
        // (feet/Fahrenheit/lbs) so nothing changes for anyone who hasn't
        // visited Settings yet.
        defaultDepthUnit = CloudSync.loadString(forKey: defaultDepthUnitKey)
            .flatMap(DepthUnit.init(rawValue:)) ?? .feet
        defaultTemperatureUnit = CloudSync.loadString(forKey: defaultTemperatureUnitKey)
            .flatMap(TemperatureUnit.init(rawValue:)) ?? .fahrenheit
        defaultWeightUnit = CloudSync.loadString(forKey: defaultWeightUnitKey)
            .flatMap(WeightUnit.init(rawValue:)) ?? .lbs
        isAdminModeEnabled = CloudSync.loadBool(forKey: adminModeKey) ?? false
        isTrainingSectionEnabled = CloudSync.loadBool(forKey: trainingSectionEnabledKey) ?? false
        trainingProfessionalAgency = CloudSync.loadString(forKey: trainingProfessionalAgencyKey)
        trainingProfessionalNumber = CloudSync.loadString(forKey: trainingProfessionalNumberKey)
        hasAcknowledgedDisclaimer = CloudSync.loadBool(forKey: disclaimerAcknowledgedKey) ?? false
        disclaimerAcknowledgedDate = CloudSync.loadString(forKey: disclaimerAcknowledgedDateKey)
            .flatMap { Self.dateFormatter.date(from: $0) }

        cloudSyncObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: CloudSync.store,
            queue: .main
        ) { [weak self] notification in
            self?.reloadFromCloud(notification)
        }

        // Backup & Sync (see SyncManager.swift) needs a live reference to
        // this instance to build/apply full-state snapshots -- there's
        // only ever one AppStore for the app's lifetime, so wiring this up
        // here rather than passing it around everywhere is simplest.
        SyncManager.shared.appStore = self
    }

    deinit {
        if let cloudSyncObserver {
            NotificationCenter.default.removeObserver(cloudSyncObserver)
        }
    }

    /// Called when another of the user's devices pushes a change via
    /// iCloud. Only the keys iCloud reports as changed are reloaded, and
    /// each is only reassigned if it actually decodes, so this doesn't
    /// clobber other in-flight local state.
    private func reloadFromCloud(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String]
        else { return }

        for key in changedKeys {
            switch key {
            case historyKey:
                if let decoded = CloudSync.load([SavedChecklist].self, forKey: historyKey) { savedChecklists = decoded }
            case equipmentKey:
                if let decoded = CloudSync.load([EquipmentItem].self, forKey: equipmentKey) { equipmentLocker = decoded }
            case diveLogKey:
                if let decoded = CloudSync.load([DiveLogEntry].self, forKey: diveLogKey) { diveLogEntries = decoded }
            case locationsKey:
                if let decoded = CloudSync.load([SavedLocation].self, forKey: locationsKey) { savedLocations = decoded }
            case buddiesKey:
                if let decoded = CloudSync.load([DiveBuddy].self, forKey: buddiesKey) { savedBuddies = decoded }
            case eapKey:
                if let decoded = CloudSync.load([EmergencyActionPlan].self, forKey: eapKey) { emergencyActionPlans = decoded }
            case certificationsKey:
                if let decoded = CloudSync.load([Certification].self, forKey: certificationsKey) { certifications = decoded }
            case savedCertificationsKey:
                if let decoded = CloudSync.load([SavedCertification].self, forKey: savedCertificationsKey) { savedCertifications = decoded }
            case trainingSectionEnabledKey:
                if let decoded = CloudSync.loadBool(forKey: trainingSectionEnabledKey) { isTrainingSectionEnabled = decoded }
            case trainingProfessionalAgencyKey:
                if let decoded = CloudSync.loadString(forKey: trainingProfessionalAgencyKey) { trainingProfessionalAgency = decoded }
            case trainingProfessionalNumberKey:
                if let decoded = CloudSync.loadString(forKey: trainingProfessionalNumberKey) { trainingProfessionalNumber = decoded }
            case diveComputersKey:
                if let decoded = CloudSync.load([DiveComputer].self, forKey: diveComputersKey) { diveComputers = decoded }
            case medicalIDKey:
                diverMedicalID = CloudSync.load(DiverMedicalID.self, forKey: medicalIDKey)
            case savedMedicalIDsKey:
                if let decoded = CloudSync.load([SavedDiverMedicalID].self, forKey: savedMedicalIDsKey) { savedDiverMedicalIDs = decoded }
            case defaultDepthUnitKey:
                if let decoded = CloudSync.loadString(forKey: defaultDepthUnitKey).flatMap(DepthUnit.init(rawValue:)) { defaultDepthUnit = decoded }
            case defaultTemperatureUnitKey:
                if let decoded = CloudSync.loadString(forKey: defaultTemperatureUnitKey).flatMap(TemperatureUnit.init(rawValue:)) { defaultTemperatureUnit = decoded }
            case defaultWeightUnitKey:
                if let decoded = CloudSync.loadString(forKey: defaultWeightUnitKey).flatMap(WeightUnit.init(rawValue:)) { defaultWeightUnit = decoded }
            case adminModeKey:
                if let decoded = CloudSync.loadBool(forKey: adminModeKey) { isAdminModeEnabled = decoded }
            case disclaimerAcknowledgedKey:
                if let decoded = CloudSync.loadBool(forKey: disclaimerAcknowledgedKey) { hasAcknowledgedDisclaimer = decoded }
            case disclaimerAcknowledgedDateKey:
                if let decoded = CloudSync.loadString(forKey: disclaimerAcknowledgedDateKey).flatMap({ Self.dateFormatter.date(from: $0) }) { disclaimerAcknowledgedDate = decoded }
            default:
                break
            }
        }
    }

    /// Applies the canonical home-screen order (Open Circuit, Closed
    /// Circuit, Technical Diving, Travel), so reordering the seed data also
    /// fixes already-installed/persisted state. Any unrecognized/custom
    /// categories are kept, appended after the known ones. Not private --
    /// AppStoreSnapshot.swift's applySyncSnapshot(_:) also reorders a
    /// pulled remote snapshot's categories the same way.
    static func reordered(_ cats: [DiveCategory]) -> [DiveCategory] {
        let order = SeedData.canonicalOrder
        return cats.enumerated().sorted { lhs, rhs in
            let li = order.firstIndex(of: lhs.element.name) ?? Int.max
            let ri = order.firstIndex(of: rhs.element.name) ?? Int.max
            if li != ri { return li < ri }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }

    private func save() {
        CloudSync.saveLocalOnly(categories, forKey: storageKey)
    }

    private func saveHistory() {
        CloudSync.save(savedChecklists, forKey: historyKey)
    }

    private func saveEquipment() {
        CloudSync.save(equipmentLocker, forKey: equipmentKey)
        for item in equipmentLocker {
            NotificationScheduler.scheduleEquipmentReminder(itemID: item.id, name: item.name, dueDate: item.nextServiceDue)
        }
    }

    private func saveDiveLog() {
        CloudSync.save(diveLogEntries, forKey: diveLogKey)
    }

    private func saveLocations() {
        CloudSync.save(savedLocations, forKey: locationsKey)
    }

    private func saveBuddies() {
        CloudSync.save(savedBuddies, forKey: buddiesKey)
    }

    private func saveEAPs() {
        CloudSync.save(emergencyActionPlans, forKey: eapKey)
        for plan in emergencyActionPlans {
            let locationName = location(withID: plan.locationID)?.name ?? ""
            NotificationScheduler.scheduleEAPReviewReminder(planID: plan.id, locationName: locationName, lastReviewedAt: plan.lastReviewedAt)
        }
    }

    private func saveCertifications() {
        CloudSync.save(certifications, forKey: certificationsKey)
    }

    private func saveSavedCertifications() {
        CloudSync.save(savedCertifications, forKey: savedCertificationsKey)
    }

    private func saveTrainingAgencies() {
        CloudSync.saveLocalOnly(trainingAgencies, forKey: trainingAgenciesKey)
    }

    private func saveDiveComputers() {
        CloudSync.save(diveComputers, forKey: diveComputersKey)
    }

    private func saveMedicalID() {
        if let diverMedicalID {
            CloudSync.save(diverMedicalID, forKey: medicalIDKey)
        } else {
            UserDefaults.standard.removeObject(forKey: medicalIDKey)
            CloudSync.store.removeObject(forKey: medicalIDKey)
            // The branch above doesn't go through CloudSync.save(_:forKey:),
            // so it wouldn't otherwise tell SyncManager anything changed --
            // without this, clearing the Diver Medical ID wouldn't reach
            // Backup & Sync until some other field happened to change too.
            CloudSync.notifySyncManager()
        }
    }

    private func saveSavedDiverMedicalIDs() {
        CloudSync.save(savedDiverMedicalIDs, forKey: savedMedicalIDsKey)
    }

    // MARK: - Lookups

    private func categoryIndex(_ id: UUID) -> Int? {
        categories.firstIndex { $0.id == id }
    }

    private func trainingAgencyIndex(_ id: UUID) -> Int? {
        trainingAgencies.firstIndex { $0.id == id }
    }

    private func trainingRosterProgramIndex(agencyID: UUID, programID: UUID) -> (agency: Int, program: Int)? {
        guard let ai = trainingAgencyIndex(agencyID),
              let pi = trainingAgencies[ai].rosterPrograms.firstIndex(where: { $0.id == programID })
        else { return nil }
        return (ai, pi)
    }

    private func trainingCandidateIndex(agencyID: UUID, programID: UUID, candidateID: UUID) -> (agency: Int, program: Int, candidate: Int)? {
        guard let (ai, pi) = trainingRosterProgramIndex(agencyID: agencyID, programID: programID),
              let cdi = trainingAgencies[ai].rosterPrograms[pi].candidates.firstIndex(where: { $0.id == candidateID })
        else { return nil }
        return (ai, pi, cdi)
    }

    // MARK: - Bindings into the tree

    /// Binding to a checklist that lives directly under a category.
    func binding(categoryID: UUID, checklistID: UUID) -> Binding<Checklist> {
        Binding<Checklist>(
            get: {
                guard let ci = self.categoryIndex(categoryID),
                      let li = self.categories[ci].checklists.firstIndex(where: { $0.id == checklistID })
                else { return Checklist(name: "") }
                return self.categories[ci].checklists[li]
            },
            set: { newValue in
                guard let ci = self.categoryIndex(categoryID),
                      let li = self.categories[ci].checklists.firstIndex(where: { $0.id == checklistID })
                else { return }
                self.categories[ci].checklists[li] = newValue
            }
        )
    }

    /// Binding to a checklist that lives under a subcategory (equipment unit).
    func binding(categoryID: UUID, subcategoryID: UUID, checklistID: UUID) -> Binding<Checklist> {
        Binding<Checklist>(
            get: {
                guard let ci = self.categoryIndex(categoryID),
                      let si = self.categories[ci].subcategories.firstIndex(where: { $0.id == subcategoryID }),
                      let li = self.categories[ci].subcategories[si].checklists.firstIndex(where: { $0.id == checklistID })
                else { return Checklist(name: "") }
                return self.categories[ci].subcategories[si].checklists[li]
            },
            set: { newValue in
                guard let ci = self.categoryIndex(categoryID),
                      let si = self.categories[ci].subcategories.firstIndex(where: { $0.id == subcategoryID }),
                      let li = self.categories[ci].subcategories[si].checklists.firstIndex(where: { $0.id == checklistID })
                else { return }
                self.categories[ci].subcategories[si].checklists[li] = newValue
            }
        )
    }

    /// Binding to a dive/skill checklist inside the Training tree.
    func trainingBinding(agencyID: UUID, certificationID: UUID, checklistID: UUID) -> Binding<Checklist> {
        Binding<Checklist>(
            get: {
                guard let ai = self.trainingAgencyIndex(agencyID),
                      let ci = self.trainingAgencies[ai].certifications.firstIndex(where: { $0.id == certificationID }),
                      let li = self.trainingAgencies[ai].certifications[ci].checklists.firstIndex(where: { $0.id == checklistID })
                else { return Checklist(name: "") }
                return self.trainingAgencies[ai].certifications[ci].checklists[li]
            },
            set: { newValue in
                guard let ai = self.trainingAgencyIndex(agencyID),
                      let ci = self.trainingAgencies[ai].certifications.firstIndex(where: { $0.id == certificationID }),
                      let li = self.trainingAgencies[ai].certifications[ci].checklists.firstIndex(where: { $0.id == checklistID })
                else { return }
                self.trainingAgencies[ai].certifications[ci].checklists[li] = newValue
            }
        )
    }

    /// Binding to one candidate's personal copy of a roster program
    /// checklist (e.g. a Divemaster candidate's "Waterskills Exercises"),
    /// independent of every other candidate's copy and of the program's
    /// shared requirementChecklists template.
    func trainingCandidateBinding(agencyID: UUID, programID: UUID, candidateID: UUID, checklistID: UUID) -> Binding<Checklist> {
        Binding<Checklist>(
            get: {
                guard let (ai, pi, cdi) = self.trainingCandidateIndex(agencyID: agencyID, programID: programID, candidateID: candidateID),
                      let li = self.trainingAgencies[ai].rosterPrograms[pi].candidates[cdi].checklists.firstIndex(where: { $0.id == checklistID })
                else { return Checklist(name: "") }
                return self.trainingAgencies[ai].rosterPrograms[pi].candidates[cdi].checklists[li]
            },
            set: { newValue in
                guard let (ai, pi, cdi) = self.trainingCandidateIndex(agencyID: agencyID, programID: programID, candidateID: candidateID),
                      let li = self.trainingAgencies[ai].rosterPrograms[pi].candidates[cdi].checklists.firstIndex(where: { $0.id == checklistID })
                else { return }
                self.trainingAgencies[ai].rosterPrograms[pi].candidates[cdi].checklists[li] = newValue
            }
        )
    }

    // MARK: - Training Roster Programs (e.g. PADI Divemaster)

    /// Adds a new candidate to a roster program, handing them a fresh-ID
    /// deep copy of the program's requirement checklists (every item
    /// unchecked, every field blank) so their progress is entirely their
    /// own from the start -- editing it never touches the shared template
    /// or any other candidate's copy. Returns the new candidate's id so the
    /// caller can navigate straight to their detail screen.
    @discardableResult
    func addTrainingCandidate(name: String, toProgramID programID: UUID, inAgencyID agencyID: UUID) -> UUID? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let (ai, pi) = trainingRosterProgramIndex(agencyID: agencyID, programID: programID)
        else { return nil }
        let freshChecklists = trainingAgencies[ai].rosterPrograms[pi].requirementChecklists.map(Self.freshCopy)
        let candidate = TrainingCandidate(name: trimmed, checklists: freshChecklists)
        trainingAgencies[ai].rosterPrograms[pi].candidates.append(candidate)
        return candidate.id
    }

    /// Toggles a candidate between the active roster and the archived
    /// (completed/closed-out) history section, stamping or clearing
    /// archivedDate to match -- this is how a candidate's progress gets
    /// "saved" for the record without needing a separate snapshot, since
    /// their checklists simply stop showing on the active roster while
    /// staying fully intact and still viewable.
    func setTrainingCandidateArchived(_ isArchived: Bool, agencyID: UUID, programID: UUID, candidateID: UUID) {
        guard let (ai, pi, cdi) = trainingCandidateIndex(agencyID: agencyID, programID: programID, candidateID: candidateID) else { return }
        trainingAgencies[ai].rosterPrograms[pi].candidates[cdi].isArchived = isArchived
        trainingAgencies[ai].rosterPrograms[pi].candidates[cdi].archivedDate = isArchived ? Date() : nil
    }

    func deleteTrainingCandidate(agencyID: UUID, programID: UUID, candidateID: UUID) {
        guard let (ai, pi) = trainingRosterProgramIndex(agencyID: agencyID, programID: programID) else { return }
        trainingAgencies[ai].rosterPrograms[pi].candidates.removeAll { $0.id == candidateID }
    }

    /// Deep-copies a checklist template with brand-new UUIDs throughout and
    /// every checkmark/typed value reset to blank. Used only when handing a
    /// new roster-program candidate their own independent copy of the
    /// shared requirement checklists -- see `addTrainingCandidate`.
    private static func freshCopy(_ checklist: Checklist) -> Checklist {
        Checklist(
            name: checklist.name,
            headerFields: checklist.headerFields.map(freshCopy),
            items: checklist.items.map(freshCopy)
        )
    }

    private static func freshCopy(_ item: ChecklistItem) -> ChecklistItem {
        ChecklistItem(
            label: item.label,
            text: item.text,
            note: item.note,
            isChecked: false,
            isNote: item.isNote,
            fields: item.fields.map(freshCopy),
            subItems: item.subItems.map(freshCopy)
        )
    }

    private static func freshCopy(_ field: ItemField) -> ItemField {
        ItemField(
            label: field.label,
            kind: field.kind,
            textValue: "",
            options: field.options,
            selectedOption: nil
        )
    }

    // MARK: - Mutations

    func addChecklist(name: String, toCategory categoryID: UUID) {
        guard let ci = categoryIndex(categoryID) else { return }
        categories[ci].checklists.append(Checklist(name: name))
    }

    func addChecklist(name: String, toSubcategory subcategoryID: UUID, inCategory categoryID: UUID) {
        guard let ci = categoryIndex(categoryID),
              let si = categories[ci].subcategories.firstIndex(where: { $0.id == subcategoryID })
        else { return }
        categories[ci].subcategories[si].checklists.append(Checklist(name: name))
    }

    func addSubcategory(name: String, symbolName: String, toCategory categoryID: UUID) {
        guard let ci = categoryIndex(categoryID) else { return }
        categories[ci].subcategories.append(DiveSubcategory(name: name, symbolName: symbolName))
    }

    func deleteChecklist(_ checklistID: UUID, fromCategory categoryID: UUID) {
        guard let ci = categoryIndex(categoryID) else { return }
        categories[ci].checklists.removeAll { $0.id == checklistID }
    }

    func deleteChecklist(_ checklistID: UUID, fromSubcategory subcategoryID: UUID, inCategory categoryID: UUID) {
        guard let ci = categoryIndex(categoryID),
              let si = categories[ci].subcategories.firstIndex(where: { $0.id == subcategoryID })
        else { return }
        categories[ci].subcategories[si].checklists.removeAll { $0.id == checklistID }
    }

    func deleteSubcategory(_ subcategoryID: UUID, fromCategory categoryID: UUID) {
        guard let ci = categoryIndex(categoryID) else { return }
        categories[ci].subcategories.removeAll { $0.id == subcategoryID }
    }

    // MARK: - History

    /// Freezes a copy of the current checklist state and adds it to history.
    /// The saved copy is independent of the live checklist — further edits
    /// to the live checklist do not affect what was saved.
    func saveSnapshot(_ checklist: Checklist, categoryName: String, subcategoryName: String?) {
        let snapshot = SavedChecklist(categoryName: categoryName, subcategoryName: subcategoryName, checklist: checklist)
        savedChecklists.insert(snapshot, at: 0)
    }

    func deleteSavedChecklist(_ id: UUID) {
        savedChecklists.removeAll { $0.id == id }
    }

    /// Binding to a single saved checklist, for editing/updating in
    /// SavedChecklistDetailView. Saved checklists aren't frozen — this lets
    /// the user keep checking off items or fixing values after the fact,
    /// the same way a live checklist or dive log entry stays editable.
    func savedChecklistBinding(for id: UUID) -> Binding<SavedChecklist> {
        Binding<SavedChecklist>(
            get: {
                self.savedChecklists.first { $0.id == id } ?? SavedChecklist(categoryName: "", checklist: Checklist(name: ""))
            },
            set: { newValue in
                guard let idx = self.savedChecklists.firstIndex(where: { $0.id == id }) else { return }
                self.savedChecklists[idx] = newValue
            }
        )
    }

    // MARK: - Equipment Locker

    func addEquipment(_ item: EquipmentItem) {
        equipmentLocker.append(item)
    }

    func deleteEquipment(_ id: UUID) {
        equipmentLocker.removeAll { $0.id == id }
        NotificationScheduler.cancelEquipmentReminder(itemID: id)
    }

    /// Binding to a single piece of gear, for editing in EquipmentDetailView.
    func equipmentBinding(for id: UUID) -> Binding<EquipmentItem> {
        Binding<EquipmentItem>(
            get: {
                self.equipmentLocker.first { $0.id == id } ?? EquipmentItem(name: "", category: .other)
            },
            set: { newValue in
                guard let idx = self.equipmentLocker.firstIndex(where: { $0.id == id }) else { return }
                self.equipmentLocker[idx] = newValue
            }
        )
    }

    // MARK: - Dive Log

    /// Creates a blank entry (dated now, using the units set in Settings)
    /// and returns its id so the caller can immediately navigate to it for
    /// editing.
    @discardableResult
    func addDiveLogEntry() -> UUID {
        let entry = DiveLogEntry(
            depthUnit: defaultDepthUnit,
            temperatureUnit: defaultTemperatureUnit,
            weightUnit: defaultWeightUnit
        )
        diveLogEntries.append(entry)
        return entry.id
    }

    func deleteDiveLogEntry(_ id: UUID) {
        if let entry = diveLogEntries.first(where: { $0.id == id }) {
            for filename in entry.photoFilenames ?? [] {
                PhotoStorage.delete(filename)
            }
        }
        diveLogEntries.removeAll { $0.id == id }
    }

    /// Admin Mode bulk delete -- reuses `deleteDiveLogEntry(_:)` per entry
    /// so photo cleanup stays in one place rather than being duplicated.
    func deleteDiveLogEntries(_ ids: Set<UUID>) {
        for id in ids {
            deleteDiveLogEntry(id)
        }
    }

    /// Admin Mode bulk edit -- applies every checked field on `edit` to
    /// each entry in `ids`, leaving unchecked fields untouched. See
    /// DiveLogBulkEdit.swift.
    func bulkUpdateDiveLogEntries(_ ids: Set<UUID>, with edit: DiveLogBulkEdit) {
        for index in diveLogEntries.indices where ids.contains(diveLogEntries[index].id) {
            if edit.applyLocation {
                diveLogEntries[index].locationID = edit.locationID
                diveLogEntries[index].diveSiteID = edit.diveSiteID
            }
            if edit.applySiteType { diveLogEntries[index].siteType = edit.siteType }
            if edit.applyEntryType { diveLogEntries[index].entryType = edit.entryType }
            if edit.applyDiveType { diveLogEntries[index].diveType = edit.diveType }
            if edit.applyWaterType { diveLogEntries[index].waterType = edit.waterType }
            if edit.applyWaterSurfaceCondition { diveLogEntries[index].waterSurfaceCondition = edit.waterSurfaceCondition }
            if edit.applySkyCondition { diveLogEntries[index].skyCondition = edit.skyCondition }
            if edit.applyWindSpeedRange { diveLogEntries[index].windSpeedRange = edit.windSpeedRange }
            if edit.applyWindDirection { diveLogEntries[index].windDirection = edit.windDirection }
        }
    }

    /// Adds a fully-built entry (e.g. one mapped from an imported dive
    /// computer download), as opposed to `addDiveLogEntry()` which creates
    /// a blank one for manual editing.
    func addDiveLogEntry(_ entry: DiveLogEntry) {
        diveLogEntries.append(entry)
    }

    /// Binding to a single dive log entry, for editing in DiveLogDetailView.
    func diveLogBinding(for id: UUID) -> Binding<DiveLogEntry> {
        Binding<DiveLogEntry>(
            get: {
                self.diveLogEntries.first { $0.id == id } ?? DiveLogEntry()
            },
            set: { newValue in
                guard let idx = self.diveLogEntries.firstIndex(where: { $0.id == id }) else { return }
                self.diveLogEntries[idx] = newValue
            }
        )
    }

    // MARK: - Saved Locations

    /// Adds a new saved Location (if the name isn't already saved, matched
    /// case-insensitively) and returns its id either way, so callers can
    /// both save and select in one step.
    @discardableResult
    func addLocation(name: String) -> UUID? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let existing = savedLocations.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing.id
        }
        let location = SavedLocation(name: trimmed)
        savedLocations.append(location)
        return location.id
    }

    /// Adds a new saved Location with coordinates (matching an existing
    /// same-named Location instead if one exists, backfilling its
    /// coordinates if it doesn't have any yet). Used by the reverse-geocoded
    /// import suggestion flow in the Bluetooth/Garmin import screens.
    @discardableResult
    func addLocation(name: String, latitude: Double, longitude: Double) -> UUID? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let idx = savedLocations.firstIndex(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            if savedLocations[idx].latitude == nil {
                savedLocations[idx].latitude = latitude
                savedLocations[idx].longitude = longitude
            }
            return savedLocations[idx].id
        }
        let location = SavedLocation(name: trimmed, latitude: latitude, longitude: longitude)
        savedLocations.append(location)
        return location.id
    }

    /// Deletes a Location and clears any dive log entries and Emergency
    /// Action Plan that referenced it, so nothing is left pointing at a
    /// Location that no longer exists.
    func deleteLocation(_ id: UUID) {
        savedLocations.removeAll { $0.id == id }
        for index in diveLogEntries.indices where diveLogEntries[index].locationID == id {
            diveLogEntries[index].locationID = nil
            diveLogEntries[index].diveSiteID = nil
        }
        for plan in emergencyActionPlans where plan.locationID == id {
            NotificationScheduler.cancelEAPReviewReminder(planID: plan.id)
        }
        emergencyActionPlans.removeAll { $0.locationID == id }
    }

    /// Binding to a single saved Location, for editing its name and dive
    /// sites in LocationDetailView.
    func locationBinding(for id: UUID) -> Binding<SavedLocation> {
        Binding<SavedLocation>(
            get: {
                self.savedLocations.first { $0.id == id } ?? SavedLocation(name: "")
            },
            set: { newValue in
                guard let idx = self.savedLocations.firstIndex(where: { $0.id == id }) else { return }
                self.savedLocations[idx] = newValue
            }
        )
    }

    /// Adds a new Dive Site (if the name isn't already saved under this
    /// Location) to the given Location and returns its id either way.
    @discardableResult
    func addDiveSite(name: String, toLocationID locationID: UUID) -> UUID? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = savedLocations.firstIndex(where: { $0.id == locationID }) else { return nil }
        if let existing = savedLocations[idx].diveSites.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing.id
        }
        let site = DiveSite(name: trimmed)
        savedLocations[idx].diveSites.append(site)
        return site.id
    }

    /// Deletes a Dive Site from a Location and clears any dive log entries
    /// that referenced it (the entry keeps its Location, just loses the
    /// specific site).
    func deleteDiveSite(_ siteID: UUID, fromLocationID locationID: UUID) {
        guard let idx = savedLocations.firstIndex(where: { $0.id == locationID }) else { return }
        savedLocations[idx].diveSites.removeAll { $0.id == siteID }
        for index in diveLogEntries.indices where diveLogEntries[index].diveSiteID == siteID {
            diveLogEntries[index].diveSiteID = nil
        }
    }

    func location(withID id: UUID?) -> SavedLocation? {
        guard let id else { return nil }
        return savedLocations.first { $0.id == id }
    }

    func diveSite(withID id: UUID?, inLocationID locationID: UUID?) -> DiveSite? {
        guard let id, let locationID else { return nil }
        return savedLocations.first { $0.id == locationID }?.diveSites.first { $0.id == id }
    }

    /// "Location Name" or "Location Name — Dive Site" for display, falling
    /// back to the entry's legacy free-text location for entries created
    /// before the structured Locations feature existed.
    func displayLocationName(for entry: DiveLogEntry) -> String {
        if let location = location(withID: entry.locationID) {
            if let site = diveSite(withID: entry.diveSiteID, inLocationID: entry.locationID) {
                return "\(location.name) — \(site.name)"
            }
            return location.name
        }
        return entry.location
    }

    // MARK: - Saved Buddies

    @discardableResult
    func addBuddy(name: String) -> DiveBuddy? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let existing = savedBuddies.first(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing
        }
        let buddy = DiveBuddy(name: trimmed)
        savedBuddies.append(buddy)
        return buddy
    }

    func deleteBuddy(_ id: UUID) {
        savedBuddies.removeAll { $0.id == id }
    }

    // MARK: - Emergency Action Plans

    func emergencyActionPlan(forLocationID locationID: UUID) -> EmergencyActionPlan? {
        emergencyActionPlans.first { $0.locationID == locationID }
    }

    /// Returns the existing plan's id for this Location, or creates a blank
    /// one (pre-filled with DAN's suggested "911" default) and returns its
    /// id -- same lazy-creation pattern as `addDiveLogEntry()`.
    @discardableResult
    func ensureEAP(forLocationID locationID: UUID) -> UUID {
        if let existing = emergencyActionPlan(forLocationID: locationID) {
            return existing.id
        }
        let plan = EmergencyActionPlan(locationID: locationID)
        emergencyActionPlans.append(plan)
        return plan.id
    }

    func deleteEAP(_ id: UUID) {
        emergencyActionPlans.removeAll { $0.id == id }
        NotificationScheduler.cancelEAPReviewReminder(planID: id)
    }

    /// Binding to a single Emergency Action Plan, for editing in EAPDetailView.
    func eapBinding(for id: UUID) -> Binding<EmergencyActionPlan> {
        Binding<EmergencyActionPlan>(
            get: {
                self.emergencyActionPlans.first { $0.id == id } ?? EmergencyActionPlan(locationID: UUID())
            },
            set: { newValue in
                guard let idx = self.emergencyActionPlans.firstIndex(where: { $0.id == id }) else { return }
                self.emergencyActionPlans[idx] = newValue
            }
        )
    }

    // MARK: - Certifications

    func addCertification(_ certification: Certification) {
        certifications.append(certification)
    }

    /// Creates a blank certification and returns its id so the caller can
    /// immediately navigate to it for editing -- same lazy-creation pattern
    /// as `addDiveLogEntry()`.
    @discardableResult
    func addBlankCertification() -> UUID {
        let certification = Certification(agency: "", courseName: "")
        certifications.append(certification)
        return certification.id
    }

    func deleteCertification(_ id: UUID) {
        if let certification = certifications.first(where: { $0.id == id }) {
            if let filename = certification.cardImageFilename {
                PhotoStorage.delete(filename)
            }
            if let filename = certification.cardDocumentFilename {
                DocumentStorage.delete(filename)
            }
        }
        certifications.removeAll { $0.id == id }
    }

    /// Binding to a single certification, for editing in CertificationDetailView.
    func certificationBinding(for id: UUID) -> Binding<Certification> {
        Binding<Certification>(
            get: {
                self.certifications.first { $0.id == id } ?? Certification(agency: "", courseName: "")
            },
            set: { newValue in
                guard let idx = self.certifications.firstIndex(where: { $0.id == id }) else { return }
                self.certifications[idx] = newValue
            }
        )
    }

    // MARK: - Saved Certifications

    /// Freezes a copy of the certification and adds it to history. If the
    /// certification has a card image and/or an uploaded PDF, the snapshot
    /// gets its own independent copy of each file (see PhotoStorage.duplicate
    /// / DocumentStorage.duplicate) so a later replace/remove on the live
    /// certification's photo or document doesn't affect what was saved.
    func saveCertificationSnapshot(_ certification: Certification) {
        var copy = certification
        if let filename = certification.cardImageFilename {
            copy.cardImageFilename = PhotoStorage.duplicate(filename)
        }
        if let filename = certification.cardDocumentFilename {
            copy.cardDocumentFilename = DocumentStorage.duplicate(filename)
        }
        let snapshot = SavedCertification(certification: copy)
        savedCertifications.insert(snapshot, at: 0)
    }

    func deleteSavedCertification(_ id: UUID) {
        if let saved = savedCertifications.first(where: { $0.id == id }) {
            if let filename = saved.certification.cardImageFilename {
                PhotoStorage.delete(filename)
            }
            if let filename = saved.certification.cardDocumentFilename {
                DocumentStorage.delete(filename)
            }
        }
        savedCertifications.removeAll { $0.id == id }
    }

    /// Binding to a single saved certification, for editing/updating in
    /// SavedCertificationDetailView.
    func savedCertificationBinding(for id: UUID) -> Binding<SavedCertification> {
        Binding<SavedCertification>(
            get: {
                self.savedCertifications.first { $0.id == id } ?? SavedCertification(certification: Certification(agency: "", courseName: ""))
            },
            set: { newValue in
                guard let idx = self.savedCertifications.firstIndex(where: { $0.id == id }) else { return }
                self.savedCertifications[idx] = newValue
            }
        )
    }

    // MARK: - Dive Computers

    /// Finds the saved DiveComputer matching `matchKey` (a stable
    /// per-device identifier -- BLE peripheral UUID for Bluetooth imports,
    /// FIT serial number for Garmin imports) or creates a new one named
    /// from `detectedModelName`. This is what lets imports from two
    /// different physical units of the same model (e.g. two Petrel 3s)
    /// show up separately in Statistics instead of collapsing into one
    /// bucket -- matching is keyed on hardware identity, not the display
    /// name, which can collide or come back blank/generic.
    @discardableResult
    func resolveDiveComputer(matchKey: String, detectedModelName: String) -> UUID {
        if let existing = diveComputers.first(where: { $0.matchKey == matchKey }) {
            return existing.id
        }
        // Disambiguate the default name if another saved computer already
        // has this same detected model name (e.g. a second "Petrel 3").
        let existingNames = Set(diveComputers.map { $0.name })
        var name = detectedModelName
        var suffix = 2
        while existingNames.contains(name) {
            name = "\(detectedModelName) (\(suffix))"
            suffix += 1
        }
        let computer = DiveComputer(name: name, detectedModelName: detectedModelName, matchKey: matchKey)
        diveComputers.append(computer)
        return computer.id
    }

    /// Adds a blank, manually-named dive computer (for noting which
    /// computer was used on a hand-logged dive, without ever importing from
    /// it) and returns its id.
    @discardableResult
    func addManualDiveComputer(name: String) -> UUID? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let computer = DiveComputer(name: trimmed, detectedModelName: trimmed, matchKey: "manual-\(UUID().uuidString)")
        diveComputers.append(computer)
        return computer.id
    }

    func deleteDiveComputer(_ id: UUID) {
        diveComputers.removeAll { $0.id == id }
        for index in diveLogEntries.indices where diveLogEntries[index].sourceDeviceID == id {
            diveLogEntries[index].sourceDeviceID = nil
        }
    }

    func diveComputer(withID id: UUID?) -> DiveComputer? {
        guard let id else { return nil }
        return diveComputers.first { $0.id == id }
    }

    func diveComputerBinding(for id: UUID) -> Binding<DiveComputer> {
        Binding<DiveComputer>(
            get: {
                self.diveComputers.first { $0.id == id } ?? DiveComputer(name: "", detectedModelName: "", matchKey: "")
            },
            set: { newValue in
                guard let idx = self.diveComputers.firstIndex(where: { $0.id == id }) else { return }
                self.diveComputers[idx] = newValue
            }
        )
    }

    /// The name to show for a dive log entry's source computer: the saved
    /// DiveComputer's (user-editable) name if it's been resolved to one,
    /// falling back to the raw `sourceDevice` string for entries imported
    /// before DiveComputer records existed, falling back to "Manually
    /// Logged" for hand-entered dives.
    func displayDeviceName(for entry: DiveLogEntry) -> String {
        if let computer = diveComputer(withID: entry.sourceDeviceID) {
            return computer.name
        }
        let legacy = entry.sourceDevice?.trimmingCharacters(in: .whitespaces) ?? ""
        return legacy.isEmpty ? "Manually Logged" : legacy
    }

    // MARK: - Diver Medical ID

    /// Binding to the single Diver Medical ID card, creating a blank one on
    /// first access -- same lazy-creation idea as `ensureEAP(forLocationID:)`.
    var medicalIDBinding: Binding<DiverMedicalID> {
        Binding<DiverMedicalID>(
            get: {
                self.diverMedicalID ?? DiverMedicalID()
            },
            set: { newValue in
                self.diverMedicalID = newValue
            }
        )
    }

    // MARK: - Saved Diver Medical IDs

    /// Freezes a copy of the Diver Medical ID card and adds it to history.
    /// If the card has a WRSTC form on file, the snapshot gets its own
    /// independent copy of that file (see DocumentStorage.duplicate) so a
    /// later replace/remove on the live card's form doesn't affect what
    /// was saved.
    func saveDiverMedicalIDSnapshot(_ medicalID: DiverMedicalID) {
        var copy = medicalID
        if let filename = medicalID.wrstcFormFilename {
            copy.wrstcFormFilename = DocumentStorage.duplicate(filename)
        }
        let snapshot = SavedDiverMedicalID(medicalID: copy)
        savedDiverMedicalIDs.insert(snapshot, at: 0)
    }

    func deleteSavedDiverMedicalID(_ id: UUID) {
        if let saved = savedDiverMedicalIDs.first(where: { $0.id == id }), let filename = saved.medicalID.wrstcFormFilename {
            DocumentStorage.delete(filename)
        }
        savedDiverMedicalIDs.removeAll { $0.id == id }
    }

    /// Binding to a single saved Diver Medical ID, for editing/updating in
    /// SavedDiverMedicalIDDetailView.
    func savedDiverMedicalIDBinding(for id: UUID) -> Binding<SavedDiverMedicalID> {
        Binding<SavedDiverMedicalID>(
            get: {
                self.savedDiverMedicalIDs.first { $0.id == id } ?? SavedDiverMedicalID(medicalID: DiverMedicalID())
            },
            set: { newValue in
                guard let idx = self.savedDiverMedicalIDs.firstIndex(where: { $0.id == id }) else { return }
                self.savedDiverMedicalIDs[idx] = newValue
            }
        )
    }
}
