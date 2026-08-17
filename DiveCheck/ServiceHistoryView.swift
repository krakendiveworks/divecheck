import SwiftUI

/// A combined log across every piece of owned gear: when it was purchased
/// and every service event recorded against it. Read-only here -- reuses
/// EquipmentItem.purchaseDate/serviceHistory, the same data entered on each
/// item's own detail screen; tap through to actually add or edit a record.
struct ServiceHistoryView: View {
    @ObservedObject var store: AppStore

    private var sortedItems: [EquipmentItem] {
        store.equipmentLocker.sorted { $0.name < $1.name }
    }

    var body: some View {
        Group {
            if store.equipmentLocker.isEmpty {
                Text("No gear in your Equipment Locker yet. Add some first to start a service history.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    ForEach(sortedItems) { item in
                        Section {
                            NavigationLink(value: ChecklistRoute.equipmentDetail(item.id)) {
                                HStack(spacing: 10) {
                                    Image(systemName: item.category.symbolName)
                                        .foregroundStyle(.blue)
                                    Text(item.name).font(.headline)
                                }
                            }
                            HStack {
                                Text("Purchased")
                                Spacer()
                                Text(item.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set")
                                    .foregroundStyle(.secondary)
                            }
                            if item.serviceHistory.isEmpty {
                                Text("No service records yet.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(item.serviceHistory.sorted(by: { $0.date > $1.date })) { record in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.subheadline.weight(.medium))
                                        if !record.serviceDescription.isEmpty {
                                            Text(record.serviceDescription)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        if !record.servicedBy.isEmpty {
                                            Text("By \(record.servicedBy)")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Service History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ServiceHistoryView(store: AppStore())
    }
}
