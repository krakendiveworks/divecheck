import SwiftUI

/// A Form row that keeps a fixed label visible next to the value, so a bare
/// number or short answer still shows what it represents after it's typed
/// (a plain TextField's placeholder disappears once there's a value).
struct LabeledTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField(placeholder, text: $text)
                .multilineTextAlignment(.trailing)
                .keyboardType(keyboardType)
                .foregroundStyle(.secondary)
        }
    }
}

/// Same idea as LabeledTextField but for longer free text: the label sits
/// above as a caption instead of squeezed onto one line.
struct LabeledMultilineField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(1...6)
        }
    }
}

/// An editable row for a checklist's header field (Name/Date/choice, etc.).
/// Shared by the live ChecklistDetailView and the editable
/// SavedChecklistDetailView so both can edit header fields the same way.
struct HeaderFieldRow: View {
    @Binding var field: ItemField

    var body: some View {
        switch field.kind {
        case .text:
            HStack {
                Text(field.label)
                Spacer()
                TextField("Value", text: $field.textValue)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }
        case .choice:
            Picker(field.label, selection: Binding(
                get: { field.selectedOption ?? "" },
                set: { field.selectedOption = $0.isEmpty ? nil : $0 }
            )) {
                Text("—").tag("")
                ForEach(field.options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
        }
    }
}

/// A labeled scrolling number wheel for one input value. `values` are
/// always Int under the hood (SwiftUI wheel pickers need stable, exact
/// tags — floating point stride can drift), with an optional `format`
/// closure to display them as something else, e.g. tenths as decimals
/// ("14" -> "1.4") for a PPO2 wheel. Shared by the SAC/RMV, MOD, and PPO2
/// calculators.
struct NumberWheel: View {
    let label: String
    @Binding var selection: Int
    let values: [Int]
    var format: (Int) -> String = { "\($0)" }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Picker(label, selection: $selection) {
                ForEach(values, id: \.self) { value in
                    Text(format(value)).tag(value)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 100)
        }
    }
}

/// A headline-weight result row (label + computed value), used across all
/// the gas-planning calculators.
struct ResultRow: View {
    let label: String
    let value: Double
    let unit: String
    var decimalPlaces: Int = 2

    var body: some View {
        HStack {
            Text(label).font(.headline)
            Spacer()
            Text(String(format: "%.\(decimalPlaces)f %@", value, unit))
                .font(.headline)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 2)
    }
}

/// A small colored capsule status indicator -- generic building block used
/// by ServiceStatusBadge below and directly by CertificationsListView for
/// expiration status.
struct StatusBadge: View {
    let text: String
    let symbolName: String
    let color: Color

    var body: some View {
        Label(text, systemImage: symbolName)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color, in: Capsule())
    }
}

/// A small colored capsule flagging an EquipmentItem's service status.
/// Shows nothing for `.ok` -- the badge is only meant to draw the eye to
/// gear that needs attention. Shared by EquipmentLockerListView and
/// MaintenanceScheduleView.
struct ServiceStatusBadge: View {
    let status: EquipmentItem.ServiceStatus

    var body: some View {
        switch status {
        case .overdue:
            StatusBadge(text: "Overdue", symbolName: "exclamationmark.triangle.fill", color: .red)
        case .dueSoon:
            StatusBadge(text: "Due Soon", symbolName: "clock.fill", color: .orange)
        case .ok:
            EmptyView()
        }
    }
}

/// A Tools/Calculators list row: icon, title, and a secondary subtitle
/// line. Shared by ContentView and CalculatorsListView.
struct ToolRow: View {
    let title: String
    let subtitle: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbolName)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
