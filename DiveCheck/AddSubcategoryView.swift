import SwiftUI

struct AddSubcategoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var symbolName: String = "gearshape.fill"

    let onAdd: (String, String) -> Void

    private let symbolOptions = [
        "gearshape.fill", "lungs.fill", "gauge.with.dots.needle.bottom.50percent",
        "wrench.and.screwdriver.fill", "flame.fill", "drop.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Unit Name") {
                    TextField("e.g. JJ-CCR", text: $name)
                }
                Section("Icon") {
                    Picker("Icon", selection: $symbolName) {
                        ForEach(symbolOptions, id: \.self) { symbol in
                            Label(symbol, systemImage: symbol).tag(symbol)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
            }
            .navigationTitle("New Unit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(name, symbolName)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddSubcategoryView { _, _ in }
}
