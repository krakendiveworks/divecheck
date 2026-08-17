import SwiftUI

struct HistoryListView: View {
    @ObservedObject var store: AppStore

    private var sorted: [SavedChecklist] {
        store.savedChecklists.sorted { $0.savedAt > $1.savedAt }
    }

    var body: some View {
        Group {
            if sorted.isEmpty {
                Text("No saved checklists yet. Open a checklist and tap Save to keep a copy here — you can come back and update it anytime.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    ForEach(sorted) { saved in
                        NavigationLink(value: ChecklistRoute.savedChecklist(saved.id)) {
                            SavedRow(saved: saved)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            store.deleteSavedChecklist(sorted[index].id)
                        }
                    }
                }
            }
        }
        .navigationTitle("Saved Checklists")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SavedRow: View {
    let saved: SavedChecklist

    private var dateText: String {
        saved.savedAt.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(saved.checklist.name).font(.body.weight(.medium))
            Text(saved.contextLabel).font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 6) {
                let p = saved.checklist.progress
                Text(dateText)
                Text("·")
                Text("\(p.checked)/\(p.total) complete")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        HistoryListView(store: AppStore())
    }
}
