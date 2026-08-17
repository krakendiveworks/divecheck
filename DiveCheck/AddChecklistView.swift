import SwiftUI

struct AddChecklistView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""

    let onAdd: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Checklist Name") {
                    TextField("e.g. Boat Dive Prep", text: $name)
                }
            }
            .navigationTitle("New Checklist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(name)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddChecklistView { _ in }
}
