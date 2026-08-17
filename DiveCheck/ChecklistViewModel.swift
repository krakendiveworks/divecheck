import Foundation
import Combine

// Superseded by AppStore.swift (added in the multi-category update). No
// longer part of the build target — safe to delete manually.
#if false

/// Owns the checklist state: loading, persisting, checking off, and editing items.
final class ChecklistViewModel: ObservableObject {
    @Published private(set) var items: [GearItem] = [] {
        didSet { save() }
    }

    private let storageKey = "DiveCheck.items"

    init() {
        load()
    }

    // MARK: - Derived data

    var categories: [GearCategory] {
        GearCategory.allCases.filter { category in
            items.contains { $0.category == category }
        }
    }

    func items(in category: GearCategory) -> [GearItem] {
        items.filter { $0.category == category }
    }

    var checkedCount: Int { items.filter(\.isChecked).count }
    var totalCount: Int { items.count }
    var progress: Double {
        totalCount == 0 ? 0 : Double(checkedCount) / Double(totalCount)
    }
    var isComplete: Bool { totalCount > 0 && checkedCount == totalCount }

    // MARK: - Mutations

    func toggle(_ item: GearItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isChecked.toggle()
    }

    func addItem(name: String, category: GearCategory) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.append(GearItem(name: trimmed, category: category, isCustom: true))
    }

    func deleteItems(in category: GearCategory, at offsets: IndexSet) {
        let categoryItems = items(in: category)
        let idsToRemove = offsets.map { categoryItems[$0].id }
        items.removeAll { idsToRemove.contains($0.id) }
    }

    func resetAllChecks() {
        for index in items.indices {
            items[index].isChecked = false
        }
    }

    func restoreDefaults() {
        items = GearItem.defaultChecklist
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([GearItem].self, from: data),
            !decoded.isEmpty
        else {
            items = GearItem.defaultChecklist
            return
        }
        items = decoded
    }
}

#endif
