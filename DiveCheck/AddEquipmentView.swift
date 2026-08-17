import SwiftUI

struct AddEquipmentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var category: EquipmentCategory = .other
    @State private var brand: String = ""
    @State private var model: String = ""
    @State private var serialNumber: String = ""
    @State private var hasPurchaseDate = false
    @State private var purchaseDate = Date()
    @State private var hasNextServiceDue = false
    @State private var nextServiceDue = Date()
    @State private var notes: String = ""

    let onAdd: (EquipmentItem) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("e.g. Hollis Prism 2 #1", text: $name)
                    Picker("Category", selection: $category) {
                        ForEach(EquipmentCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.symbolName).tag(cat)
                        }
                    }
                }
                Section("Details") {
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $model)
                    TextField("Serial Number", text: $serialNumber)
                }
                Section("Purchase") {
                    Toggle("Set Purchase Date", isOn: $hasPurchaseDate)
                    if hasPurchaseDate {
                        DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                    }
                }
                Section("Service") {
                    Toggle("Set Next Service Due", isOn: $hasNextServiceDue)
                    if hasNextServiceDue {
                        DatePicker("Next Service Due", selection: $nextServiceDue, displayedComponents: .date)
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .navigationTitle("Add Gear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let newItem = EquipmentItem(
                            name: name,
                            category: category,
                            brand: brand,
                            model: model,
                            serialNumber: serialNumber,
                            purchaseDate: hasPurchaseDate ? purchaseDate : nil,
                            nextServiceDue: hasNextServiceDue ? nextServiceDue : nil,
                            notes: notes
                        )
                        onAdd(newItem)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddEquipmentView { _ in }
}
