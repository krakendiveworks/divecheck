import SwiftUI

/// Multi-select sheet for choosing which owned gear (from the Equipment
/// Locker) was used on a logged dive.
struct EquipmentPickerView: View {
    @ObservedObject var store: AppStore
    @Binding var selectedIDs: [UUID]
    @Environment(\.dismiss) private var dismiss

    private var categoriesPresent: [EquipmentCategory] {
        EquipmentCategory.allCases.filter { cat in store.equipmentLocker.contains { $0.category == cat } }
    }

    var body: some View {
        NavigationStack {
            List {
                if store.equipmentLocker.isEmpty {
                    Text("No gear in your Equipment Locker yet. Add some from the home screen first.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(categoriesPresent) { category in
                        Section(category.rawValue) {
                            ForEach(store.equipmentLocker.filter { $0.category == category }) { equipment in
                                Button {
                                    toggle(equipment.id)
                                } label: {
                                    HStack {
                                        Text(equipment.name)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if selectedIDs.contains(equipment.id) {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Gear Used")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func toggle(_ id: UUID) {
        if let idx = selectedIDs.firstIndex(of: id) {
            selectedIDs.remove(at: idx)
        } else {
            selectedIDs.append(id)
        }
    }
}

#Preview {
    EquipmentPickerView(store: AppStore(), selectedIDs: .constant([]))
}
