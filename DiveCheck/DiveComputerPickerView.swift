import SwiftUI

/// Single-select sheet for assigning (or reassigning) a Dive Log entry's
/// source computer -- used both to fix up entries imported before
/// DiveComputer records existed, and to note which computer was used on a
/// hand-logged dive. Also lets the diver add a brand-new computer inline.
struct DiveComputerPickerView: View {
    @ObservedObject var store: AppStore
    @Binding var sourceDeviceID: UUID?
    @Environment(\.dismiss) private var dismiss
    @State private var newComputerName = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        sourceDeviceID = nil
                        dismiss()
                    } label: {
                        HStack {
                            Text("None (Manually Logged)")
                                .foregroundStyle(.primary)
                            Spacer()
                            if sourceDeviceID == nil {
                                Image(systemName: "checkmark").foregroundStyle(.blue)
                            }
                        }
                    }
                }
                Section("Add New") {
                    HStack {
                        TextField("New computer name", text: $newComputerName)
                        Button("Add") {
                            guard let id = store.addManualDiveComputer(name: newComputerName) else { return }
                            sourceDeviceID = id
                            newComputerName = ""
                            dismiss()
                        }
                        .disabled(newComputerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                if !store.diveComputers.isEmpty {
                    Section("Saved Dive Computers") {
                        ForEach(store.diveComputers.sorted { $0.name < $1.name }) { computer in
                            Button {
                                sourceDeviceID = computer.id
                                dismiss()
                            } label: {
                                HStack {
                                    Text(computer.name).foregroundStyle(.primary)
                                    Spacer()
                                    if sourceDeviceID == computer.id {
                                        Image(systemName: "checkmark").foregroundStyle(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Source Computer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    DiveComputerPickerView(store: AppStore(), sourceDeviceID: .constant(nil))
}
