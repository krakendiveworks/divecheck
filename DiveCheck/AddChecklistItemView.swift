import SwiftUI

struct AddChecklistItemView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var label: String = ""
    @State private var text: String = ""

    let onAdd: (String, String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Step Label (optional)") {
                    TextField("e.g. 21", text: $label)
                }
                Section("Step Description") {
                    TextField("e.g. Check backup light battery", text: $text, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .navigationTitle("Add Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(label, text)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddChecklistItemView { _, _ in }
}
