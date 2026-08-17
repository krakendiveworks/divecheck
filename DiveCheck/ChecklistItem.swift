import Foundation

/// One line on a checklist. May carry recorded-value fields and/or nested
/// sub-steps, mirroring the numbered/lettered structure of the paper forms
/// (e.g. "3. Turn On Wrist Display" -> "A. Check O2 cell mV readings...").
struct ChecklistItem: Identifiable, Codable, Equatable {
    let id: UUID
    var label: String?      // printed step label, e.g. "1", "A", "P"
    var text: String
    var note: String?       // short instructional/reference text (acceptable ranges, etc.)
    var isChecked: Bool
    var isNote: Bool        // true = informational only (section headers, guidance), not checkable
    var fields: [ItemField]
    var subItems: [ChecklistItem]

    init(
        id: UUID = UUID(),
        label: String? = nil,
        text: String,
        note: String? = nil,
        isChecked: Bool = false,
        isNote: Bool = false,
        fields: [ItemField] = [],
        subItems: [ChecklistItem] = []
    ) {
        self.id = id
        self.label = label
        self.text = text
        self.note = note
        self.isChecked = isChecked
        self.isNote = isNote
        self.fields = fields
        self.subItems = subItems
    }

    /// Recursively counts checkable items and how many are checked, for progress bars.
    var progress: (checked: Int, total: Int) {
        var checked = 0
        var total = 0
        if !isNote {
            total += 1
            if isChecked { checked += 1 }
        }
        for sub in subItems {
            let p = sub.progress
            checked += p.checked
            total += p.total
        }
        return (checked, total)
    }
}
