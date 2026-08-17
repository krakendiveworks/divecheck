import SwiftUI

struct EquipmentLockerListView: View {
    @ObservedObject var store: AppStore
    @State private var isShowingAddEquipment = false

    private var categoriesPresent: [EquipmentCategory] {
        EquipmentCategory.allCases.filter { cat in store.equipmentLocker.contains { $0.category == cat } }
    }

    var body: some View {
        Group {
            if store.equipmentLocker.isEmpty {
                Text("No gear yet. Tap + to add the equipment you own, along with purchase and service dates.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    ForEach(categoriesPresent) { category in
                        Section(category.rawValue) {
                            ForEach(store.equipmentLocker.filter { $0.category == category }) { equipment in
                                NavigationLink(value: ChecklistRoute.equipmentDetail(equipment.id)) {
                                    EquipmentRow(equipment: equipment)
                                }
                            }
                            .onDelete { offsets in
                                let items = store.equipmentLocker.filter { $0.category == category }
                                for index in offsets {
                                    store.deleteEquipment(items[index].id)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Equipment Locker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShowingAddEquipment = true
                } label: {
                    Label("Add Gear", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingAddEquipment) {
            AddEquipmentView { newItem in
                store.addEquipment(newItem)
            }
        }
    }
}

private struct EquipmentRow: View {
    let equipment: EquipmentItem

    private var subtitle: String {
        [equipment.brand, equipment.model].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: equipment.category.symbolName)
                .foregroundStyle(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(equipment.name).font(.body.weight(.medium))
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            ServiceStatusBadge(status: equipment.serviceStatus)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        EquipmentLockerListView(store: AppStore())
    }
}
