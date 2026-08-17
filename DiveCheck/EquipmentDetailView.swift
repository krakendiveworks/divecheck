import SwiftUI

struct EquipmentDetailView: View {
    @Binding var equipment: EquipmentItem
    @State private var isShowingAddService = false

    var body: some View {
        Form {
            Section("Item") {
                TextField("Name", text: $equipment.name)
                Picker("Category", selection: $equipment.category) {
                    ForEach(EquipmentCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.symbolName).tag(cat)
                    }
                }
            }
            Section("Details") {
                TextField("Brand", text: $equipment.brand)
                TextField("Model", text: $equipment.model)
                TextField("Serial Number", text: $equipment.serialNumber)
            }
            Section("Purchase") {
                Toggle("Has Purchase Date", isOn: Binding(
                    get: { equipment.purchaseDate != nil },
                    set: { equipment.purchaseDate = $0 ? (equipment.purchaseDate ?? Date()) : nil }
                ))
                if equipment.purchaseDate != nil {
                    DatePicker(
                        "Purchase Date",
                        selection: Binding(
                            get: { equipment.purchaseDate ?? Date() },
                            set: { equipment.purchaseDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                }
            }
            Section("Next Service") {
                Toggle("Has Next Service Due", isOn: Binding(
                    get: { equipment.nextServiceDue != nil },
                    set: { equipment.nextServiceDue = $0 ? (equipment.nextServiceDue ?? Date()) : nil }
                ))
                if equipment.nextServiceDue != nil {
                    DatePicker(
                        "Next Service Due",
                        selection: Binding(
                            get: { equipment.nextServiceDue ?? Date() },
                            set: { equipment.nextServiceDue = $0 }
                        ),
                        displayedComponents: .date
                    )
                    statusLine
                }
            }
            Section("Service History") {
                if equipment.serviceHistory.isEmpty {
                    Text("No service records yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(equipment.serviceHistory.sorted { $0.date > $1.date }) { record in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline.weight(.medium))
                            if !record.serviceDescription.isEmpty {
                                Text(record.serviceDescription).font(.caption).foregroundStyle(.secondary)
                            }
                            if !record.servicedBy.isEmpty {
                                Text("By \(record.servicedBy)").font(.caption2).foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        let sorted = equipment.serviceHistory.sorted { $0.date > $1.date }
                        let idsToRemove = offsets.map { sorted[$0].id }
                        equipment.serviceHistory.removeAll { idsToRemove.contains($0.id) }
                    }
                }
                Button {
                    isShowingAddService = true
                } label: {
                    Label("Add Service Record", systemImage: "plus")
                }
            }
            Section("Notes") {
                TextField("Notes", text: $equipment.notes, axis: .vertical)
                    .lineLimit(1...4)
            }
        }
        .navigationTitle(equipment.name.isEmpty ? "Gear" : equipment.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingAddService) {
            AddServiceRecordView { record in
                equipment.serviceHistory.append(record)
            }
        }
    }

    @ViewBuilder
    private var statusLine: some View {
        switch equipment.serviceStatus {
        case .overdue:
            Label("Service overdue", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
        case .dueSoon:
            Label("Service due soon", systemImage: "clock.fill").foregroundStyle(.orange)
        case .ok:
            EmptyView()
        }
    }
}

#Preview {
    NavigationStack {
        EquipmentDetailView(equipment: .constant(EquipmentItem(name: "Apeks XTX50", category: .regulator)))
    }
}
