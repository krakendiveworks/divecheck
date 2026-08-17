import SwiftUI

/// "Equipment" section of the home screen: the gear locker plus (eventually)
/// maintenance scheduling and a cross-equipment service history view.
struct EquipmentMenuView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        List {
            NavigationLink(value: ChecklistRoute.equipmentLocker) {
                ToolRow(
                    title: "Equipment Locker",
                    subtitle: "\(store.equipmentLocker.count) item(s)",
                    symbolName: "shippingbox.fill"
                )
            }
            NavigationLink(value: ChecklistRoute.maintenanceSchedule) {
                ToolRow(
                    title: "Maintenance Schedule",
                    subtitle: "Next service due, across all gear",
                    symbolName: "wrench.and.screwdriver.fill"
                )
            }
            NavigationLink(value: ChecklistRoute.serviceHistory) {
                ToolRow(
                    title: "Service History",
                    subtitle: "Purchase dates and service records",
                    symbolName: "clock.arrow.circlepath"
                )
            }
        }
        .navigationTitle("Equipment")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EquipmentMenuView(store: AppStore())
    }
}
