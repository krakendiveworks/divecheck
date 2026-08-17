import SwiftUI

/// Cross-equipment view of when each piece of gear is next due for service,
/// grouped by urgency. Reuses EquipmentItem.nextServiceDue/serviceStatus --
/// this screen doesn't add any new data, it's a different way of looking at
/// what's already tracked per-item in the Equipment Locker.
struct MaintenanceScheduleView: View {
    @ObservedObject var store: AppStore

    private var overdue: [EquipmentItem] {
        store.equipmentLocker
            .filter { $0.serviceStatus == .overdue }
            .sorted { ($0.nextServiceDue ?? .distantFuture) < ($1.nextServiceDue ?? .distantFuture) }
    }

    private var dueSoon: [EquipmentItem] {
        store.equipmentLocker
            .filter { $0.serviceStatus == .dueSoon }
            .sorted { ($0.nextServiceDue ?? .distantFuture) < ($1.nextServiceDue ?? .distantFuture) }
    }

    private var scheduled: [EquipmentItem] {
        store.equipmentLocker
            .filter { $0.serviceStatus == .ok && $0.nextServiceDue != nil }
            .sorted { $0.nextServiceDue! < $1.nextServiceDue! }
    }

    private var noDateSet: [EquipmentItem] {
        store.equipmentLocker
            .filter { $0.nextServiceDue == nil }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        Group {
            if store.equipmentLocker.isEmpty {
                Text("No gear in your Equipment Locker yet. Add some first, then set a Next Service Due date to track it here.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    if !overdue.isEmpty {
                        Section("Overdue") {
                            ForEach(overdue) { item in row(for: item) }
                        }
                    }
                    if !dueSoon.isEmpty {
                        Section("Due Soon") {
                            ForEach(dueSoon) { item in row(for: item) }
                        }
                    }
                    if !scheduled.isEmpty {
                        Section("Scheduled") {
                            ForEach(scheduled) { item in row(for: item) }
                        }
                    }
                    if !noDateSet.isEmpty {
                        Section {
                            ForEach(noDateSet) { item in row(for: item) }
                        } header: {
                            Text("No Service Date Set")
                        } footer: {
                            Text("Open an item and set a Next Service Due date to have it show up above.")
                        }
                    }
                }
            }
        }
        .navigationTitle("Maintenance Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func row(for item: EquipmentItem) -> some View {
        NavigationLink(value: ChecklistRoute.equipmentDetail(item.id)) {
            HStack(spacing: 14) {
                Image(systemName: item.category.symbolName)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).font(.body.weight(.medium))
                    if let due = item.nextServiceDue {
                        Text("Due \(due.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                ServiceStatusBadge(status: item.serviceStatus)
            }
            .padding(.vertical, 2)
        }
    }
}

#Preview {
    NavigationStack {
        MaintenanceScheduleView(store: AppStore())
    }
}
