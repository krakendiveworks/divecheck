import Foundation

/// An equipment "unit" within a category — e.g. a specific rebreather model
/// like the Hollis Prism 2 — that groups several related checklists.
struct DiveSubcategory: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var symbolName: String
    var checklists: [Checklist]

    init(
        id: UUID = UUID(),
        name: String,
        symbolName: String = "gearshape.fill",
        checklists: [Checklist] = []
    ) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.checklists = checklists
    }
}
