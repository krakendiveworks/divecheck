import SwiftUI

struct CategoryDetailView: View {
    @ObservedObject var store: AppStore
    let categoryID: UUID

    @State private var isShowingAddChecklist = false
    @State private var isShowingAddUnit = false

    private var category: DiveCategory? {
        store.categories.first { $0.id == categoryID }
    }

    var body: some View {
        Group {
            if let category {
                List {
                    if !category.subcategories.isEmpty {
                        Section("Units") {
                            ForEach(category.subcategories) { sub in
                                NavigationLink(value: route(for: sub)) {
                                    SubcategoryRow(subcategory: sub)
                                }
                            }
                            .onDelete { offsets in
                                for index in offsets {
                                    store.deleteSubcategory(category.subcategories[index].id, fromCategory: categoryID)
                                }
                            }
                        }
                    }
                    if !category.checklists.isEmpty {
                        Section("Checklists") {
                            ForEach(category.checklists) { checklist in
                                NavigationLink(value: ChecklistRoute.checklist(categoryID: categoryID, subcategoryID: nil, checklistID: checklist.id)) {
                                    ChecklistRow(checklist: checklist)
                                }
                            }
                            .onDelete { offsets in
                                for index in offsets {
                                    store.deleteChecklist(category.checklists[index].id, fromCategory: categoryID)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(category.name)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                isShowingAddChecklist = true
                            } label: {
                                Label("Add Checklist", systemImage: "checklist")
                            }
                            Button {
                                isShowingAddUnit = true
                            } label: {
                                Label("Add Unit", systemImage: "wrench.and.screwdriver")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $isShowingAddChecklist) {
                    AddChecklistView { name in
                        store.addChecklist(name: name, toCategory: categoryID)
                    }
                }
                .sheet(isPresented: $isShowingAddUnit) {
                    AddSubcategoryView { name, symbol in
                        store.addSubcategory(name: name, symbolName: symbol, toCategory: categoryID)
                    }
                }
            } else {
                Text("Category not found")
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// A unit with exactly one checklist skips straight to that checklist;
    /// units with several checklists (like Hollis Prism 2) open their list.
    private func route(for subcategory: DiveSubcategory) -> ChecklistRoute {
        if subcategory.checklists.count == 1 {
            return .checklist(categoryID: categoryID, subcategoryID: subcategory.id, checklistID: subcategory.checklists[0].id)
        }
        return .subcategory(categoryID: categoryID, subcategoryID: subcategory.id)
    }
}

private struct SubcategoryRow: View {
    let subcategory: DiveSubcategory

    private var progressText: String {
        let checked = subcategory.checklists.reduce(0) { $0 + $1.progress.checked }
        let total = subcategory.checklists.reduce(0) { $0 + $1.progress.total }
        return total > 0 ? "\(checked)/\(total) complete" : "\(subcategory.checklists.count) checklist(s)"
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: subcategory.symbolName)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(subcategory.name).font(.body.weight(.medium))
                Text(progressText).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

private struct ChecklistRow: View {
    let checklist: Checklist

    private var progressText: String {
        let p = checklist.progress
        return p.total > 0 ? "\(p.checked)/\(p.total) complete" : "No items yet"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(checklist.name).font(.body.weight(.medium))
            Text(progressText).font(.caption).foregroundStyle(.secondary)
        }
    }
}
