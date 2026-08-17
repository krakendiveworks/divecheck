import SwiftUI

/// Top-level Emergency Action Plans screen: one plan per saved Location.
/// Tapping a Location creates a blank plan for it if one doesn't exist yet,
/// then opens it for editing.
struct EmergencyActionPlansListView: View {
    @ObservedObject var store: AppStore
    @Binding var path: [ChecklistRoute]

    private var sortedLocations: [SavedLocation] {
        store.savedLocations.sorted { $0.name < $1.name }
    }

    var body: some View {
        Group {
            if store.savedLocations.isEmpty {
                Text("No locations saved yet. Add a Location first (from the home screen), then come back here to build its Emergency Action Plan.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    Section {
                        Label("Divers Alert Network (DAN) Emergency Hotline: \(EmergencyActionPlan.danEmergencyHotline)", systemImage: "phone.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Section("Locations") {
                        ForEach(sortedLocations) { location in
                            Button {
                                let eapID = store.ensureEAP(forLocationID: location.id)
                                path.append(.eapDetail(eapID))
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(location.name)
                                            .font(.body.weight(.medium))
                                            .foregroundStyle(.primary)
                                        Text(store.emergencyActionPlan(forLocationID: location.id) != nil ? "Plan on file" : "No plan yet")
                                            .font(.caption)
                                            .foregroundStyle(store.emergencyActionPlan(forLocationID: location.id) != nil ? .green : .secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Emergency Action Plans")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EmergencyActionPlansListView(store: AppStore(), path: .constant([]))
    }
}
