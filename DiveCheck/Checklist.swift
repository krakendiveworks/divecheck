import Foundation

/// A named checklist (e.g. "Assembly", "Operational", "Post-Dive", or a
/// category's starter list) with optional header fields (Name/Date/etc.)
/// and a sequence of items.
struct Checklist: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var headerFields: [ItemField]
    var items: [ChecklistItem]

    /// Optional passing/performance requirement shown under the Total
    /// Score summary in ChecklistDetailView (e.g. "Performance
    /// Requirement: ... scoring at least 82 points total..." on the PADI
    /// Divemaster Skill Evaluation Slate) -- nil for every checklist that
    /// doesn't need one, which is most of them. This is plain reference
    /// text, not evaluated by the app; it just keeps the pass/fail
    /// criteria visible next to the live-computed total instead of buried
    /// in a specific item's note.
    var scoringNote: String?

    init(
        id: UUID = UUID(),
        name: String,
        headerFields: [ItemField] = [],
        items: [ChecklistItem] = [],
        scoringNote: String? = nil
    ) {
        self.id = id
        self.name = name
        self.headerFields = headerFields
        self.items = items
        self.scoringNote = scoringNote
    }

    var progress: (checked: Int, total: Int) {
        var checked = 0
        var total = 0
        for item in items {
            let p = item.progress
            checked += p.checked
            total += p.total
        }
        return (checked, total)
    }

    /// Live sum of every "Score" choice field's current numeric selection
    /// across this checklist's items (recursing into subItems too, for any
    /// future scored checklist that nests them) -- used by the PADI
    /// Divemaster Waterskills Exercises and Skill Evaluation Slate
    /// checklists, where every skill is scored 1-5 and the instructor
    /// needs a running total without adding it up by hand. Non-numeric
    /// selections (Waterskills Exercises' "Incomplete" option) and blank
    /// selections are simply skipped rather than counted as zero.
    ///
    /// Returns nil (rather than 0) when this checklist has no "Score"
    /// fields at all, so ChecklistDetailView only shows a total for
    /// checklists that actually use scoring -- this is generic on the
    /// "Score" field label rather than hardcoded to specific checklist
    /// names, so it applies automatically to both checklists above (and
    /// any future one that reuses the same labeling convention) with no
    /// per-checklist wiring needed.
    var totalScore: Int? {
        let scoreFields = items.flatMap(\.allScoreFields)
        guard !scoreFields.isEmpty else { return nil }
        return scoreFields.compactMap { $0.selectedOption.flatMap(Int.init) }.reduce(0, +)
    }
}

private extension ChecklistItem {
    /// This item's own field(s) labeled "Score" plus every subItem's,
    /// recursively -- see `Checklist.totalScore`.
    var allScoreFields: [ItemField] {
        fields.filter { $0.label == "Score" } + subItems.flatMap(\.allScoreFields)
    }
}
