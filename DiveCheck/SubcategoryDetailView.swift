import SwiftUI

struct SubcategoryDetailView: View {
    @ObservedObject var store: AppStore
    let categoryID: UUID
    let subcategoryID: UUID

    @State private var isShowingAddChecklist = false

    private var subcategory: DiveSubcategory? {
        store.categories.first { $0.id == categoryID }?
            .subcategories.first { $0.id == subcategoryID }
    }

    var body: some View {
        Group {
            if let subcategory {
                List {
                    Section("Checklists") {
                        ForEach(subcategory.checklists) { checklist in
                            NavigationLink(value: ChecklistRoute.checklist(categoryID: categoryID, subcategoryID: subcategoryID, checklistID: checklist.id)) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(checklist.name).font(.body.weight(.medium))
                                    let p = checklist.progress
                                    Text(p.total > 0 ? "\(p.checked)/\(p.total) complete" : "No items yet")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                store.deleteChecklist(subcategory.checklists[index].id, fromSubcategory: subcategoryID, inCategory: categoryID)
                            }
                        }
                    }
                }
                .navigationTitle(subcategory.name)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            isShowingAddChecklist = true
                        } label: {
                            Label("Add Checklist", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $isShowingAddChecklist) {
                    AddChecklistView { name in
                        store.addChecklist(name: name, toSubcategory: subcategoryID, inCategory: categoryID)
                    }
                }
            } else {
                Text("Unit not found")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
