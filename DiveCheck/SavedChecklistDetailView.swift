import SwiftUI

/// Editable view of a saved checklist snapshot. Unlike a fresh live
/// checklist, this doesn't offer Add Step / Reset / Delete — it's meant for
/// touching up values and checkmarks on a record you've already saved, then
/// tapping Update to refresh its saved timestamp. It stays fully editable
/// indefinitely; nothing here locks the entry.
struct SavedChecklistDetailView: View {
    @ObservedObject var store: AppStore
    let savedID: UUID

    @State private var isShowingUpdatedConfirmation = false

    private var saved: Binding<SavedChecklist> {
        store.savedChecklistBinding(for: savedID)
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Saved")
                            .font(.headline)
                        Spacer()
                        let p = saved.wrappedValue.checklist.progress
                        Text("\(p.checked)/\(p.total)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Text(saved.wrappedValue.contextLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(saved.wrappedValue.savedAt.formatted(date: .long, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            if !saved.wrappedValue.checklist.headerFields.isEmpty {
                Section("Details") {
                    ForEach(saved.checklist.headerFields) { $field in
                        HeaderFieldRow(field: $field)
                    }
                }
            }

            Section("Steps") {
                ForEach(saved.checklist.items) { $item in
                    ChecklistItemRow(item: $item)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(saved.wrappedValue.checklist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    saved.wrappedValue.savedAt = Date()
                    isShowingUpdatedConfirmation = true
                } label: {
                    Label("Update", systemImage: "tray.and.arrow.down")
                }
            }
        }
        .alert("Saved Checklist Updated", isPresented: $isShowingUpdatedConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your changes have been saved. This entry stays editable — come back and tap Update again anytime.")
        }
    }
}

#Preview {
    NavigationStack {
        SavedChecklistDetailView(store: AppStore(), savedID: UUID())
    }
}
