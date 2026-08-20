import SwiftUI

/// "Plan" section of the home screen: everything about preparing for a
/// dive ahead of time -- pre-dive checklists, where you're diving, and what
/// to do in an emergency there.
struct PlanMenuView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        List {
            NavigationLink(value: ChecklistRoute.diveChecklists) {
                ToolRow(
                    title: "Checklists",
                    subtitle: "\(store.checklistCategories.count) categories",
                    symbolName: "checklist"
                )
            }
            NavigationLink(value: ChecklistRoute.locations) {
                ToolRow(
                    title: "Locations",
                    subtitle: "\(store.savedLocations.count) saved",
                    symbolName: "map.fill"
                )
            }
            NavigationLink(value: ChecklistRoute.emergencyActionPlans) {
                ToolRow(
                    title: "Emergency Action Plans",
                    subtitle: "\(store.emergencyActionPlans.count) plan(s) on file",
                    symbolName: "cross.case.fill"
                )
            }
        }
        .navigationTitle("Plan")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PlanMenuView(store: AppStore())
    }
}
