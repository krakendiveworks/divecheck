import SwiftUI

/// Multi-select sheet for choosing which saved dive buddies were on a
/// logged dive. Also lets the diver add a brand-new buddy inline, which
/// saves it to the list and selects it immediately.
struct BuddyPickerView: View {
    @ObservedObject var store: AppStore
    @Binding var selectedIDs: [UUID]
    @Environment(\.dismiss) private var dismiss
    @State private var newBuddyName = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Add New") {
                    HStack {
                        TextField("New buddy name", text: $newBuddyName)
                        Button("Add") {
                            guard let buddy = store.addBuddy(name: newBuddyName) else { return }
                            if !selectedIDs.contains(buddy.id) {
                                selectedIDs.append(buddy.id)
                            }
                            newBuddyName = ""
                        }
                        .disabled(newBuddyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                if !store.savedBuddies.isEmpty {
                    Section("Saved Buddies") {
                        ForEach(store.savedBuddies.sorted { $0.name < $1.name }) { buddy in
                            Button {
                                toggle(buddy.id)
                            } label: {
                                HStack {
                                    Text(buddy.name).foregroundStyle(.primary)
                                    Spacer()
                                    if selectedIDs.contains(buddy.id) {
                                        Image(systemName: "checkmark").foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                        .onDelete { offsets in
                            let sorted = store.savedBuddies.sorted { $0.name < $1.name }
                            for index in offsets {
                                store.deleteBuddy(sorted[index].id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Dive Buddies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func toggle(_ id: UUID) {
        if let idx = selectedIDs.firstIndex(of: id) {
            selectedIDs.remove(at: idx)
        } else {
            selectedIDs.append(id)
        }
    }
}

#Preview {
    BuddyPickerView(store: AppStore(), selectedIDs: .constant([]))
}
