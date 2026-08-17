import Foundation

/// Top-level grouping for the Training section (shown on the main menu when
/// AppStore.isTrainingSectionEnabled is on), one per certifying agency
/// (PADI, SSI, NAUI, etc.), each holding the certification levels that have
/// been built out for it.
struct TrainingAgency: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var symbolName: String
    var certifications: [TrainingCertification]

    /// Programs where requirements are tracked per-student rather than as
    /// a single personal checklist -- e.g. PADI Divemaster. Empty for
    /// agencies/certifications that don't need multi-candidate tracking.
    var rosterPrograms: [TrainingRosterProgram]

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "graduationcap.fill",
        certifications: [TrainingCertification] = [],
        rosterPrograms: [TrainingRosterProgram] = []
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.certifications = certifications
        self.rosterPrograms = rosterPrograms
    }
}
