import SwiftUI

/// Top-level Locations management screen, reachable from the home screen.
/// Add, rename, and delete Locations here; tap into one to manage its Dive
/// Sites and its Emergency Action Plan.
struct LocationsListView: View {
    @ObservedObject var store: AppStore
    @Binding var path: [ChecklistRoute]
    @State private var newLocationName = ""

    private var sortedLocations: [SavedLocation] {
        store.savedLocations.sorted { $0.name < $1.name }
    }

    var body: some View {
        List {
            Section("Add New") {
                HStack {
                    TextField("New location name", text: $newLocationName)
                    Button("Add") {
                        guard let id = store.addLocation(name: newLocationName) else { return }
                        newLocationName = ""
                        path.append(.locationDetail(id))
                    }
                    .disabled(newLocationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            if store.savedLocations.isEmpty {
                Section {
                    Text("No locations saved yet. Add one above, or save one the first time you pick a Location while logging a dive.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Locations") {
                    ForEach(sortedLocations) { location in
                        NavigationLink(value: ChecklistRoute.locationDetail(location.id)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(location.name).font(.body.weight(.medium))
                                if !location.diveSites.isEmpty {
                                    Text("\(location.diveSites.count) dive site\(location.diveSites.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            store.deleteLocation(sortedLocations[index].id)
                        }
                    }
                }
            }
        }
        .navigationTitle("Locations")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                path.append(.diveSiteMap)
            } label: {
                Image(systemName: "map")
            }
        }
    }
}

#Preview {
    NavigationStack {
        LocationsListView(store: AppStore(), path: .constant([]))
    }
}
