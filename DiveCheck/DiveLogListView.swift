import SwiftUI

struct DiveLogListView: View {
    @ObservedObject var store: AppStore
    @Binding var path: [ChecklistRoute]

    // Admin Mode only (store.isAdminModeEnabled) -- multi-select, bulk
    // delete, and bulk edit. Hand-rolled rather than SwiftUI's
    // List(selection:)/EditMode so row taps unambiguously mean "select"
    // while selecting is active, same manual-checkbox pattern already used
    // for the Bluetooth import screen's dive list.
    @State private var isSelecting = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var isShowingDeleteConfirm = false
    @State private var isShowingBulkEditSheet = false

    private var sorted: [DiveLogEntry] {
        store.diveLogEntries.sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if sorted.isEmpty {
                Text("No dives logged yet. Tap + to log your first dive.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    ForEach(sorted) { entry in
                        row(for: entry)
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            store.deleteDiveLogEntry(sorted[index].id)
                        }
                    }
                }
            }
        }
        .navigationTitle("Dive Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if store.isAdminModeEnabled && !sorted.isEmpty {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isSelecting ? "Done" : "Select") {
                        isSelecting.toggle()
                        if !isSelecting { selectedIDs.removeAll() }
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        let newID = store.addDiveLogEntry()
                        path.append(.diveLogDetail(newID))
                    } label: {
                        Label("Log Dive Manually", systemImage: "plus")
                    }
                    Button {
                        path.append(.bluetoothDiveImport)
                    } label: {
                        Label("Import via Bluetooth (Shearwater, Aqualung, Oceanic, and more)", systemImage: "dot.radiowaves.left.and.right")
                    }
                    Button {
                        path.append(.garminFitImport)
                    } label: {
                        Label("Import from Garmin (.fit file)", systemImage: "doc.badge.plus")
                    }
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isSelecting {
                selectionActionBar
            }
        }
        .sheet(isPresented: $isShowingBulkEditSheet) {
            BulkEditDiveLogView(store: store, entryIDs: selectedIDs) {
                selectedIDs.removeAll()
                isSelecting = false
            }
        }
        .alert("Delete \(selectedIDs.count) Dive\(selectedIDs.count == 1 ? "" : "s")?", isPresented: $isShowingDeleteConfirm) {
            Button("Delete", role: .destructive) {
                store.deleteDiveLogEntries(selectedIDs)
                selectedIDs.removeAll()
                isSelecting = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    @ViewBuilder
    private func row(for entry: DiveLogEntry) -> some View {
        if isSelecting {
            Button {
                toggle(entry.id)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: selectedIDs.contains(entry.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(.blue)
                    DiveLogRow(entry: entry, locationName: store.displayLocationName(for: entry), deviceName: store.displayDeviceName(for: entry))
                }
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: ChecklistRoute.diveLogDetail(entry.id)) {
                DiveLogRow(entry: entry, locationName: store.displayLocationName(for: entry), deviceName: store.displayDeviceName(for: entry))
            }
        }
    }

    private var selectionActionBar: some View {
        HStack {
            Button(selectedIDs.count == sorted.count ? "Deselect All" : "Select All") {
                if selectedIDs.count == sorted.count {
                    selectedIDs.removeAll()
                } else {
                    selectedIDs = Set(sorted.map(\.id))
                }
            }
            .font(.footnote)

            Spacer()

            Text(selectedIDs.isEmpty ? "Select dives" : "\(selectedIDs.count) selected")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                isShowingBulkEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .disabled(selectedIDs.isEmpty)

            Button(role: .destructive) {
                isShowingDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .disabled(selectedIDs.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func toggle(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
}

private struct DiveLogRow: View {
    let entry: DiveLogEntry
    let locationName: String
    let deviceName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(locationName.isEmpty ? "Untitled Dive" : locationName)
                    .font(.body.weight(.medium))
                Spacer()
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Text(entry.diveType.rawValue)
                if !entry.maxDepth.isEmpty {
                    Text("· \(entry.maxDepth) \(entry.depthUnit.rawValue)")
                }
                if !entry.durationMinutes.isEmpty {
                    Text("· \(entry.durationMinutes) min")
                }
                if let rating = entry.rating {
                    Text("· " + String(repeating: "★", count: rating))
                }
                if entry.savedAt == nil {
                    Text("· Draft")
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            if deviceName != "Manually Logged" {
                Text(deviceName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        DiveLogListView(store: AppStore(), path: .constant([]))
    }
}
