import SwiftUI

/// Name-entry sheet for adding a new candidate to a roster program (e.g. a
/// PADI Divemaster course) -- mirrors AddChecklistView's Cancel/Add pattern.
struct AddTrainingCandidateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""

    let onAdd: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Candidate Name") {
                    TextField("e.g. Jordan Lee", text: $name)
                }
            }
            .navigationTitle("New Candidate")
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
    AddTrainingCandidateView { _ in }
}
