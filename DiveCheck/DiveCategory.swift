import Foundation

/// A top-level grouping shown under the Dive Checklists tool entry (Open
/// Circuit, Closed Circuit, Technical Diving, Travel). A category can hold
/// equipment "unit" subcategories (like Hollis Prism 2) and/or checklists
/// directly.
struct DiveCategory: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var symbolName: String
    var subcategories: [DiveSubcategory]
    var checklists: [Checklist]

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String,
        subcategories: [DiveSubcategory] = [],
        checklists: [Checklist] = []
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.subcategories = subcategories
        self.checklists = checklists
    }
}
