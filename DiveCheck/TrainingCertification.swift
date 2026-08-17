import Foundation

/// A single certification level within a training agency (e.g. "Open Water
/// Diver -- Confined Water Dives"), made up of one Checklist per dive/skill
/// grouping. Reuses the existing Checklist/ChecklistItem model exactly like
/// the main Dive Checklists tree does, so ChecklistDetailView can render and
/// edit these without any new UI.
struct TrainingCertification: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var checklists: [Checklist]

    init(
        id: UUID = UUID(),
        name: String,
        checklists: [Checklist] = []
    ) {
        self.id = id
        self.name = name
        self.checklists = checklists
    }
}
