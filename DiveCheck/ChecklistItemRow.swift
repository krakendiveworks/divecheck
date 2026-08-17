import SwiftUI

/// Recursively renders a checklist item: its checkbox/label/text, any
/// recorded-value fields, an optional instructional note, and nested
/// sub-steps indented beneath it. Handles arbitrary nesting depth so a
/// step like "9. Calibrate..." can contain "Wrist Display" / "HUD"
/// sub-groups, each with their own lettered steps.
struct ChecklistItemRow: View {
    @Binding var item: ChecklistItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                guard !item.isNote else { return }
                item.isChecked.toggle()
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    if item.isNote {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    } else {
                        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isChecked ? .green : .secondary)
                            .font(.title3)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(labelledText)
                            .font(item.isNote ? .caption : .body)
                            .italic(item.isNote)
                            .strikethrough(item.isChecked && !item.isNote)
                            .foregroundStyle(item.isChecked && !item.isNote ? .secondary : .primary)
                        if let note = item.note, !note.isEmpty {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(item.isNote)

            if !item.fields.isEmpty {
                VStack(spacing: 4) {
                    ForEach($item.fields) { $field in
                        InlineFieldRow(field: $field)
                    }
                }
                .padding(.leading, 30)
            }

            if !item.subItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach($item.subItems) { $sub in
                        ChecklistItemRow(item: $sub)
                    }
                }
                .padding(.leading, 24)
            }
        }
        .padding(.vertical, item.isNote ? 2 : 4)
    }

    private var labelledText: String {
        if let label = item.label, !label.isEmpty {
            return "\(label). \(item.text)"
        }
        return item.text
    }
}

private struct InlineFieldRow: View {
    @Binding var field: ItemField

    var body: some View {
        switch field.kind {
        case .text:
            HStack {
                Text(field.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("—", text: $field.textValue)
                    .font(.caption)
                    .textFieldStyle(.roundedBorder)
            }
        case .choice:
            HStack {
                Text(field.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker(field.label, selection: Binding(
                    get: { field.selectedOption ?? "" },
                    set: { field.selectedOption = $0.isEmpty ? nil : $0 }
                )) {
                    Text("—").tag("")
                    ForEach(field.options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
        }
    }
}

#Preview {
    List {
        ChecklistItemRow(item: .constant(
            ChecklistItem(
                label: "1",
                text: "Example",
                fields: [.text("V"), .choice("Status", options: ["Good", "Replaced"])],
                subItems: [ChecklistItem(label: "A", text: "Sub step")]
            )
        ))
    }
}
