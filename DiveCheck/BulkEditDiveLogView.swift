import SwiftUI

/// Stamps a set of field values onto every selected Dive Log entry at once.
/// Each field has its own "Apply ___" toggle -- only checked fields
/// actually change anything, so picking a Site Type here doesn't silently
/// blank out Entry Type (or anything else) on every selected dive.
/// Reachable only from Admin Mode's multi-select in DiveLogListView.
struct BulkEditDiveLogView: View {
    @ObservedObject var store: AppStore
    let entryIDs: Set<UUID>
    let onApplied: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var edit = DiveLogBulkEdit()
    @State private var isShowingLocationPicker = false

    private var locationDisplayName: String {
        guard let locationID = edit.locationID else { return "Select" }
        let locationName = store.location(withID: locationID)?.name ?? ""
        if let site = store.diveSite(withID: edit.diveSiteID, inLocationID: locationID) {
            return "\(locationName) — \(site.name)"
        }
        return locationName.isEmpty ? "Select" : locationName
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Updating \(entryIDs.count) dive\(entryIDs.count == 1 ? "" : "s"). Only checked fields below are applied -- everything else is left exactly as it is on each dive.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Location") {
                    Toggle("Apply Location", isOn: $edit.applyLocation)
                    if edit.applyLocation {
                        Button {
                            isShowingLocationPicker = true
                        } label: {
                            HStack {
                                Text("Location")
                                Spacer()
                                Text(locationDisplayName)
                                    .foregroundStyle(edit.locationID == nil ? .blue : .secondary)
                            }
                        }
                    }
                }

                Section("Dive Type") {
                    Toggle("Apply Dive Type", isOn: $edit.applyDiveType)
                    if edit.applyDiveType {
                        Picker("Dive Type", selection: $edit.diveType) {
                            ForEach(DiveLogType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }

                Section("Site Type") {
                    Toggle("Apply Site Type", isOn: $edit.applySiteType)
                    if edit.applySiteType {
                        Picker("Site Type", selection: $edit.siteType) {
                            ForEach(SiteType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }

                Section("Entry Type") {
                    Toggle("Apply Entry Type", isOn: $edit.applyEntryType)
                    if edit.applyEntryType {
                        Picker("Entry Type", selection: $edit.entryType) {
                            ForEach(DiveEntryType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }

                Section("Conditions") {
                    Toggle("Apply Water Type", isOn: $edit.applyWaterType)
                    if edit.applyWaterType {
                        Picker("Water Type", selection: $edit.waterType) {
                            ForEach(WaterType.allCases) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                    Toggle("Apply Water Surface", isOn: $edit.applyWaterSurfaceCondition)
                    if edit.applyWaterSurfaceCondition {
                        Picker("Water Surface", selection: $edit.waterSurfaceCondition) {
                            ForEach(WaterSurfaceCondition.allCases) { cond in
                                Text(cond.rawValue).tag(cond)
                            }
                        }
                    }
                    Toggle("Apply Sky Condition", isOn: $edit.applySkyCondition)
                    if edit.applySkyCondition {
                        Picker("Sky", selection: $edit.skyCondition) {
                            ForEach(SkyCondition.allCases) { cond in
                                Text(cond.rawValue).tag(cond)
                            }
                        }
                    }
                    Toggle("Apply Wind Speed", isOn: $edit.applyWindSpeedRange)
                    if edit.applyWindSpeedRange {
                        Picker("Wind Speed", selection: $edit.windSpeedRange) {
                            ForEach(WindSpeedRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                    }
                    Toggle("Apply Wind Direction", isOn: $edit.applyWindDirection)
                    if edit.applyWindDirection {
                        Picker("Wind Direction", selection: $edit.windDirection) {
                            ForEach(WindDirection.allCases) { direction in
                                Text(direction.rawValue).tag(direction)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bulk Edit Dives")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        store.bulkUpdateDiveLogEntries(entryIDs, with: edit)
                        onApplied()
                        dismiss()
                    }
                    .disabled(!edit.hasAnyField)
                }
            }
            .sheet(isPresented: $isShowingLocationPicker) {
                LocationPickerView(store: store, locationID: $edit.locationID, diveSiteID: $edit.diveSiteID)
            }
        }
    }
}

#Preview {
    BulkEditDiveLogView(store: AppStore(), entryIDs: [], onApplied: {})
}
