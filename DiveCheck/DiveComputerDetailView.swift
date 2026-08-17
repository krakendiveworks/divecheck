import SwiftUI

/// Rename a single saved dive computer. Existing dive log entries already
/// pointing at this computer (by id) pick up the new name immediately --
/// nothing else needs to change when you rename one.
struct DiveComputerDetailView: View {
    @ObservedObject var store: AppStore
    let computerID: UUID

    private var computer: Binding<DiveComputer> {
        store.diveComputerBinding(for: computerID)
    }

    private var divesUsingThisComputer: [DiveLogEntry] {
        store.diveLogEntries.filter { $0.sourceDeviceID == computerID }
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: computer.name)
            } header: {
                Text("Name")
            } footer: {
                Text("Give this computer a name you'll recognize, especially if you own more than one of the same model.")
            }

            if computer.wrappedValue.detectedModelName != computer.wrappedValue.name && !computer.wrappedValue.detectedModelName.isEmpty {
                Section("Detected As") {
                    Text(computer.wrappedValue.detectedModelName)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Dive Log") {
                if divesUsingThisComputer.isEmpty {
                    Text("No dives imported from this computer yet.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(divesUsingThisComputer.count) dive\(divesUsingThisComputer.count == 1 ? "" : "s") logged from this computer.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(computer.wrappedValue.name.isEmpty ? "Dive Computer" : computer.wrappedValue.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        DiveComputerDetailView(store: AppStore(), computerID: UUID())
    }
}
