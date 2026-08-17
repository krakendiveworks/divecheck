import SwiftUI

/// Two-step picker for a dive log entry's Location and, within it, an
/// optional Dive Site: pick (or add) a Location first, then pick (or add) a
/// Dive Site under it, or use the Location on its own with no specific
/// site. Lets the diver add new Locations/Dive Sites inline without leaving
/// the dive log flow -- full management (rename, delete, browse) lives in
/// the standalone Locations screen off the home screen.
struct LocationPickerView: View {
    @ObservedObject var store: AppStore
    @Binding var locationID: UUID?
    @Binding var diveSiteID: UUID?
    @Environment(\.dismiss) private var dismiss

    /// nil while choosing a Location; set once a Location is chosen, which
    /// switches this same sheet into "choose a Dive Site" mode.
    @State private var stepLocationID: UUID?
    @State private var newName = ""

    private var stepLocation: SavedLocation? {
        store.location(withID: stepLocationID)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let stepLocation {
                    diveSiteStep(for: stepLocation)
                } else {
                    locationStep
                }
            }
            .navigationTitle(stepLocation?.name ?? "Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if stepLocation != nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Back") {
                            stepLocationID = nil
                            newName = ""
                        }
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
        .onAppear {
            // Jump straight to the dive-site step if this entry already has
            // a Location picked, so re-opening the picker doesn't force
            // re-choosing the Location every time.
            if let locationID, store.location(withID: locationID) != nil {
                stepLocationID = locationID
            }
        }
    }

    // MARK: - Step 1: Location

    @ViewBuilder
    private var locationStep: some View {
        List {
            Section("Add New") {
                HStack {
                    TextField("New location name", text: $newName)
                    Button("Add") {
                        guard let id = store.addLocation(name: newName) else { return }
                        newName = ""
                        stepLocationID = id
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            if !store.savedLocations.isEmpty {
                Section("Saved Locations") {
                    ForEach(store.savedLocations.sorted { $0.name < $1.name }) { location in
                        Button {
                            stepLocationID = location.id
                        } label: {
                            HStack {
                                Text(location.name).foregroundStyle(.primary)
                                Spacer()
                                if locationID == location.id {
                                    Image(systemName: "checkmark").foregroundStyle(.blue)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        let sorted = store.savedLocations.sorted { $0.name < $1.name }
                        for index in offsets {
                            store.deleteLocation(sorted[index].id)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Step 2: Dive Site within the chosen Location

    @ViewBuilder
    private func diveSiteStep(for location: SavedLocation) -> some View {
        List {
            Section {
                Button {
                    locationID = location.id
                    diveSiteID = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("Use \"\(location.name)\" with no specific site")
                        Spacer()
                        if locationID == location.id && diveSiteID == nil {
                            Image(systemName: "checkmark").foregroundStyle(.blue)
                        }
                    }
                }
            }
            Section("Add New Dive Site") {
                HStack {
                    TextField("New dive site name", text: $newName)
                    Button("Add & Use") {
                        guard let siteID = store.addDiveSite(name: newName, toLocationID: location.id) else { return }
                        locationID = location.id
                        diveSiteID = siteID
                        newName = ""
                        dismiss()
                    }
                    .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            if !location.diveSites.isEmpty {
                Section("Dive Sites") {
                    ForEach(location.diveSites.sorted { $0.name < $1.name }) { site in
                        Button {
                            locationID = location.id
                            diveSiteID = site.id
                            dismiss()
                        } label: {
                            HStack {
                                Text(site.name).foregroundStyle(.primary)
                                Spacer()
                                if diveSiteID == site.id {
                                    Image(systemName: "checkmark").foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                    .onDelete { offsets in
                        let sorted = location.diveSites.sorted { $0.name < $1.name }
                        for index in offsets {
                            store.deleteDiveSite(sorted[index].id, fromLocationID: location.id)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    LocationPickerView(store: AppStore(), locationID: .constant(nil), diveSiteID: .constant(nil))
}
