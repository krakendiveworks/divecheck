import Foundation

/// A training program whose requirements are tracked per-student rather
/// than as a single personal checklist -- e.g. a PADI Divemaster course,
/// where an instructor runs multiple candidates through the same set of
/// requirements at once and needs each candidate's progress kept separate
/// and saved individually.
///
/// `requirementChecklists` is the blank template handed to every new
/// candidate (all items unchecked, all fields empty); each candidate then
/// gets their own independent copy of it in `TrainingCandidate.checklists`,
/// so editing one candidate's progress never touches another's.
struct TrainingRosterProgram: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var requirementChecklists: [Checklist]
    var candidates: [TrainingCandidate]

    init(
        id: UUID = UUID(),
        name: String,
        requirementChecklists: [Checklist] = [],
        candidates: [TrainingCandidate] = []
    ) {
        self.id = id
        self.name = name
        self.requirementChecklists = requirementChecklists
        self.candidates = candidates
    }
}
