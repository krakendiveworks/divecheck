import Foundation

/// A saved copy of a completed (or in-progress) checklist, captured at the
/// moment the user chose to save it to history. Not frozen — it stays fully
/// editable afterward, and `savedAt` is refreshed each time the user taps
/// Update so the history list reflects the most recent change.
struct SavedChecklist: Identifiable, Codable, Equatable {
    let id: UUID
    var savedAt: Date
    var categoryName: String
    var subcategoryName: String?
    var checklist: Checklist

    init(
        id: UUID = UUID(),
        savedAt: Date = Date(),
        categoryName: String,
        subcategoryName: String? = nil,
        checklist: Checklist
    ) {
        self.id = id
        self.savedAt = savedAt
        self.categoryName = categoryName
        self.subcategoryName = subcategoryName
        self.checklist = checklist
    }

    var contextLabel: String {
        if let subcategoryName {
            return "\(categoryName) · \(subcategoryName)"
        }
        return categoryName
    }
}
