import Foundation

/// One student being tracked through a candidate-tracked training program
/// (e.g. a PADI Divemaster candidate). Holds a personal copy of that
/// program's requirement checklists, independent of every other
/// candidate's copy, so each person's checkmarks and recorded scores are
/// their own -- see TrainingRosterProgram.
struct TrainingCandidate: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var startDate: Date
    var checklists: [Checklist]

    /// True once the candidate has finished (or the record is otherwise
    /// closed out). Archived candidates move out of the active roster into
    /// a separate history section rather than being deleted, so completed
    /// requirements stay on record for tracking purposes.
    var isArchived: Bool
    var archivedDate: Date?

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date = Date(),
        checklists: [Checklist] = [],
        isArchived: Bool = false,
        archivedDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.checklists = checklists
        self.isArchived = isArchived
        self.archivedDate = archivedDate
    }

    var progress: (checked: Int, total: Int) {
        var checked = 0
        var total = 0
        for checklist in checklists {
            let p = checklist.progress
            checked += p.checked
            total += p.total
        }
        return (checked, total)
    }
}
