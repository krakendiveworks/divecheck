import SwiftUI

/// Lists every saved dive computer -- the ones auto-created the first time
/// a Bluetooth/Garmin import is resolved to a physical unit (see
/// AppStore.resolveDiveComputer), plus any added manually. Tap one to
/// rename it, e.g. to tell two units of the same model apart.
struct DiveComputersListView: View {
    @ObservedObject var store: AppStore
    @Binding var path: [ChecklistRoute]
    @State private var newComputerName = ""

    private var sorted: [DiveComputer] {
        store.diveComputers.sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            Section("Add New") {
                HStack {
                    TextField("Name (e.g. \"Petrel 3 - Backup\")", text: $newComputerName)
                    Button("Add") {
                        guard let id = store.addManualDiveComputer(name: newComputerName) else { return }
                        newComputerName = ""
                        path.append(.diveComputerDetail(id))
                    }
                    .disabled(newComputerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            if store.diveComputers.isEmpty {
                Section {
                    Text("No dive computers saved yet. One's created automatically the first time you import from a Bluetooth or Garmin dive computer, or add one manually above to note which computer you used on a hand-logged dive.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Saved Dive Computers") {
                    ForEach(sorted) { computer in
                        NavigationLink(value: ChecklistRoute.diveComputerDetail(computer.id)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(computer.name).font(.body.weight(.medium))
                                if computer.detectedModelName != computer.name {
                                    Text("Detected as \"\(computer.detectedModelName)\"")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            store.deleteDiveComputer(sorted[index].id)
                        }
                    }
                }
            }
        }
        .navigationTitle("Dive Computers")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DiveComputersListView(store: AppStore(), path: .constant([]))
    }
}
