import SwiftUI

struct ChecklistDetailView: View {
    @Binding var checklist: Checklist
    var onSaveSnapshot: ((Checklist) -> Void)? = nil

    @State private var isShowingAddItem = false
    @State private var isShowingResetConfirm = false
    @State private var isShowingSavedConfirmation = false

    var body: some View {
        List {
            if checklist.progress.total > 0 {
                Section {
                    ProgressHeader(checklist: checklist)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            if let totalScore = checklist.totalScore {
                Section {
                    TotalScoreRow(total: totalScore)
                    if let scoringNote = checklist.scoringNote, !scoringNote.isEmpty {
                        Text(scoringNote)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !checklist.headerFields.isEmpty {
                Section("Details") {
                    ForEach($checklist.headerFields) { $field in
                        HeaderFieldRow(field: $field)
                    }
                }
            }

            Section("Steps") {
                ForEach($checklist.items) { $item in
                    ChecklistItemRow(item: $item)
                }
                .onDelete { offsets in
                    checklist.items.remove(atOffsets: offsets)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(checklist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(role: .destructive) {
                    isShowingResetConfirm = true
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    if let onSaveSnapshot {
                        Button {
                            onSaveSnapshot(checklist)
                            isShowingSavedConfirmation = true
                        } label: {
                            Label("Save to History", systemImage: "tray.and.arrow.down")
                        }
                    }
                    Button {
                        isShowingAddItem = true
                    } label: {
                        Label("Add Step", systemImage: "plus")
                    }
                }
            }
        }
        .alert("Saved to History", isPresented: $isShowingSavedConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("A copy of this checklist as it stands right now was saved. View it anytime from Saved Checklists on the home screen — it stays fully editable there too.")
        }
        .sheet(isPresented: $isShowingAddItem) {
            AddChecklistItemView { label, text in
                checklist.items.append(ChecklistItem(label: label.isEmpty ? nil : label, text: text))
            }
        }
        .confirmationDialog(
            "Reset all checkmarks in this checklist?",
            isPresented: $isShowingResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset Checklist", role: .destructive) {
                var items = checklist.items
                resetAll(&items)
                checklist.items = items
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func resetAll(_ items: inout [ChecklistItem]) {
        for i in items.indices {
            items[i].isChecked = false
            resetAll(&items[i].subItems)
        }
    }
}

private struct ProgressHeader: View {
    let checklist: Checklist
    private var p: (checked: Int, total: Int) { checklist.progress }
    private var isComplete: Bool { p.total > 0 && p.checked == p.total }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(isComplete ? "Complete" : "In Progress")
                    .font(.headline)
                Spacer()
                Text("\(p.checked)/\(p.total)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: p.total == 0 ? 0 : Double(p.checked) / Double(p.total))
                .tint(isComplete ? .green : .blue)
        }
        .padding()
    }
}

/// Live running total of every "Score" field in the checklist -- see
/// Checklist.totalScore. Shown automatically for any checklist that has
/// Score fields (currently the PADI Divemaster Waterskills Exercises and
/// Skill Evaluation Slate checklists), with no per-checklist wiring.
private struct TotalScoreRow: View {
    let total: Int

    var body: some View {
        HStack {
            Text("Total Score").font(.headline)
            Spacer()
            Text("\(total)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        ChecklistDetailView(checklist: .constant(Checklist(name: "Preview", items: [ChecklistItem(label: "1", text: "Example step")])))
    }
}
