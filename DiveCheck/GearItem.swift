import Foundation

// Superseded by DiveCategory.swift, DiveSubcategory.swift, Checklist.swift,
// ChecklistItem.swift, and ItemField.swift (added in the multi-category
// update). No longer part of the build target — safe to delete manually.
#if false

/// A single item on the pre-dive gear checklist.
struct GearItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: GearCategory
    var isChecked: Bool
    var isCustom: Bool

    init(id: UUID = UUID(), name: String, category: GearCategory, isChecked: Bool = false, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.isChecked = isChecked
        self.isCustom = isCustom
    }
}

/// Groupings shown as sections in the checklist.
enum GearCategory: String, Codable, CaseIterable, Identifiable {
    case coreGear = "Core Gear"
    case exposureProtection = "Exposure Protection"
    case safety = "Safety"
    case documentation = "Documentation"
    case extras = "Extras"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .coreGear: return "figure.pool.swim"
        case .exposureProtection: return "thermometer.snowflake"
        case .safety: return "cross.case.fill"
        case .documentation: return "doc.text.fill"
        case .extras: return "bag.fill"
        }
    }
}

extension GearItem {
    /// A sensible default pre-dive gear checklist to seed a fresh install.
    static var defaultChecklist: [GearItem] {
        let coreGear = [
            "Mask", "Fins", "Snorkel", "BCD", "Regulator (primary + octopus)",
            "Dive computer", "Tank (filled & valve checked)", "Weights & weight belt/pockets"
        ]
        let exposure = [
            "Wetsuit / drysuit", "Hood", "Gloves", "Booties"
        ]
        let safety = [
            "SMB / safety sausage", "Dive knife or cutting tool", "Whistle/signaling device",
            "Dive light", "Backup mask"
        ]
        let docs = [
            "Certification card", "Dive insurance", "Logbook", "ID / travel documents"
        ]
        let extras = [
            "Camera & housing", "Sunscreen (reef-safe)", "Water & snacks", "Towel & change of clothes"
        ]

        var items: [GearItem] = []
        items += coreGear.map { GearItem(name: $0, category: .coreGear) }
        items += exposure.map { GearItem(name: $0, category: .exposureProtection) }
        items += safety.map { GearItem(name: $0, category: .safety) }
        items += docs.map { GearItem(name: $0, category: .documentation) }
        items += extras.map { GearItem(name: $0, category: .extras) }
        return items
    }
}

#endif
