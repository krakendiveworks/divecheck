import SwiftUI

/// Edit a single Location's name, manage its Dive Sites, and jump to its
/// Emergency Action Plan.
struct LocationDetailView: View {
    @ObservedObject var store: AppStore
    let locationID: UUID
    @Binding var path: [ChecklistRoute]
    @State private var newSiteName = ""
    @StateObject private var locationProvider = CurrentLocationProvider()
    @State private var isLocating = false

    private var location: Binding<SavedLocation> {
        store.locationBinding(for: locationID)
    }

    private var hasEAP: Bool {
        store.emergencyActionPlan(forLocationID: locationID) != nil
    }

    var body: some View {
        Form {
            Section("Location") {
                TextField("Location Name", text: location.name)
            }

            Section {
                if let lat = location.wrappedValue.latitude, let lon = location.wrappedValue.longitude {
                    Text(String(format: "%.4f, %.4f", lat, lon))
                        .foregroundStyle(.secondary)
                    Button(role: .destructive) {
                        location.wrappedValue.latitude = nil
                        location.wrappedValue.longitude = nil
                    } label: {
                        Text("Remove from Map")
                    }
                } else {
                    Text("No coordinates set -- add one to show this Location on the Dive Site Map.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Button {
                    Task {
                        isLocating = true
                        if let coordinate = await locationProvider.requestCurrentLocation() {
                            location.wrappedValue.latitude = coordinate.latitude
                            location.wrappedValue.longitude = coordinate.longitude
                        }
                        isLocating = false
                    }
                } label: {
                    if isLocating {
                        HStack {
                            ProgressView()
                            Text("Locating…")
                        }
                    } else {
                        Label("Use My Current Location", systemImage: "location.fill")
                    }
                }
                .disabled(isLocating)
            } header: {
                Text("Map Coordinates")
            } footer: {
                Text("Set while you're physically at the site, or leave blank -- an imported dive with GPS data can also fill this in automatically.")
            }

            Section {
                Button {
                    let eapID = store.ensureEAP(forLocationID: locationID)
                    path.append(.eapDetail(eapID))
                } label: {
                    HStack {
                        Label("Emergency Action Plan", systemImage: "cross.case.fill")
                        Spacer()
                        Text(hasEAP ? "View" : "Create")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Add Dive Site") {
                HStack {
                    TextField("New dive site name", text: $newSiteName)
                    Button("Add") {
                        store.addDiveSite(name: newSiteName, toLocationID: locationID)
                        newSiteName = ""
                    }
                    .disabled(newSiteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            if location.wrappedValue.diveSites.isEmpty {
                Section {
                    Text("No dive sites added yet for this location.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Dive Sites") {
                    ForEach(sortedSites) { site in
                        Text(site.name)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            store.deleteDiveSite(sortedSites[index].id, fromLocationID: locationID)
                        }
                    }
                }
            }
        }
        .navigationTitle(location.wrappedValue.name.isEmpty ? "Location" : location.wrappedValue.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var sortedSites: [DiveSite] {
        location.wrappedValue.diveSites.sorted { $0.name < $1.name }
    }
}

#Preview {
    NavigationStack {
        LocationDetailView(store: AppStore(), locationID: UUID(), path: .constant([]))
    }
}
