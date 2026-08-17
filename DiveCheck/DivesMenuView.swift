import SwiftUI

/// "Dives" section of the home screen: your logged dives and (eventually)
/// stats rolled up across them.
struct DivesMenuView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        List {
            NavigationLink(value: ChecklistRoute.diveLog) {
                ToolRow(
                    title: "Dive Logs",
                    subtitle: "\(store.diveLogEntries.count) dive(s) logged",
                    symbolName: "book.closed.fill"
                )
            }
            NavigationLink(value: ChecklistRoute.statistics) {
                ToolRow(
                    title: "Statistics",
                    subtitle: "\(store.diveLogEntries.count) dive(s) analyzed",
                    symbolName: "chart.bar.fill"
                )
            }
            NavigationLink(value: ChecklistRoute.diveComputers) {
                ToolRow(
                    title: "Dive Computers",
                    subtitle: "\(store.diveComputers.count) saved",
                    symbolName: "applewatch.radiowaves.left.and.right"
                )
            }
        }
        .navigationTitle("Dives")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DivesMenuView(store: AppStore())
    }
}
