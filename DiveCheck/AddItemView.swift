import SwiftUI

// Superseded by AddChecklistItemView.swift, AddChecklistView.swift, and
// AddSubcategoryView.swift (added in the multi-category update). No longer
// part of the build target — safe to delete manually.
#if false

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var category: GearCategory = .coreGear

    let onAdd: (String, GearCategory) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("e.g. Spare mask strap", text: $name)
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(GearCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.symbolName)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("Add Gear Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(name, category)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddItemView { _, _ in }
}

#endif
