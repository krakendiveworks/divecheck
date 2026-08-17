import SwiftUI

/// The "Dive Checklists" Tools entry: groups all the dive-type checklist
/// categories (Open Circuit, Closed Circuit, Technical Diving, Travel) in
/// one place, one tap in from the home screen.
struct DiveChecklistsListView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        List {
            Section {
                ForEach(store.categories) { category in
                    NavigationLink(value: route(for: category)) {
                        CategoryRow(category: category)
                    }
                }
            }
            Section {
                NavigationLink(value: ChecklistRoute.history) {
                    ToolRow(
                        title: "Saved Checklists",
                        subtitle: "\(store.savedChecklists.count) saved",
                        symbolName: "tray.full.fill"
                    )
                }
            }
        }
        .navigationTitle("Checklists")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// A category with no equipment units and exactly one checklist skips
    /// straight to that checklist; everything else opens the category page.
    private func route(for category: DiveCategory) -> ChecklistRoute {
        if category.subcategories.isEmpty, category.checklists.count == 1 {
            return .checklist(categoryID: category.id, subcategoryID: nil, checklistID: category.checklists[0].id)
        }
        return .category(category.id)
    }
}

private struct CategoryRow: View {
    let category: DiveCategory

    private var progressText: String {
        let all = category.checklists + category.subcategories.flatMap(\.checklists)
        let checked = all.reduce(0) { $0 + $1.progress.checked }
        let total = all.reduce(0) { $0 + $1.progress.total }
        guard total > 0 else { return "No items yet" }
        return "\(checked)/\(total) complete"
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: category.symbolName)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name).font(.headline)
                Text(progressText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        DiveChecklistsListView(store: AppStore())
    }
}
