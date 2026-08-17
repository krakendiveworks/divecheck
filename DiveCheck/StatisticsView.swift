import SwiftUI

/// Aggregate stats rolled up across every logged dive. Everything here is
/// computed live from `store.diveLogEntries` -- nothing is stored
/// separately, so it's always in sync with the Dive Log.
struct StatisticsView: View {
    @ObservedObject var store: AppStore

    private var entries: [DiveLogEntry] {
        store.diveLogEntries
    }

    /// Entries with a duration that actually parses to a positive number of
    /// minutes -- drafts and manually-typed junk are excluded rather than
    /// silently counted as zero.
    private var timedEntries: [DiveLogEntry] {
        entries.filter { minutes(for: $0) > 0 }
    }

    private func minutes(for entry: DiveLogEntry) -> Double {
        Double(entry.durationMinutes.trimmingCharacters(in: .whitespaces)) ?? 0
    }

    private var totalMinutes: Double {
        timedEntries.reduce(0) { $0 + minutes(for: $1) }
    }

    private var longestDive: DiveLogEntry? {
        timedEntries.max { minutes(for: $0) < minutes(for: $1) }
    }

    private var shortestDive: DiveLogEntry? {
        timedEntries.min { minutes(for: $0) < minutes(for: $1) }
    }

    private struct GroupStat: Identifiable {
        let id = UUID()
        let name: String
        let count: Int
        let minutes: Double
    }

    /// Grouped by the saved DiveComputer an entry resolved to at import
    /// time (`AppStore.displayDeviceName(for:)`), not the raw device-name
    /// string -- that's what actually keeps two physical units of the same
    /// model (e.g. two Petrel 3s) from collapsing into a single row. Falls
    /// back to the legacy `sourceDevice` string for entries imported before
    /// DiveComputer records existed, then to "Manually Logged".
    private var byDevice: [GroupStat] {
        let grouped = Dictionary(grouping: timedEntries) { entry in
            store.displayDeviceName(for: entry)
        }
        return grouped.map { name, group in
            GroupStat(name: name, count: group.count, minutes: group.reduce(0) { $0 + minutes(for: $1) })
        }.sorted { $0.minutes > $1.minutes }
    }

    /// Grouped by Location (falls back to "Unassigned" for entries with no
    /// Location picked, matching AppStore.displayLocationName's fallback).
    private var byLocation: [GroupStat] {
        let grouped = Dictionary(grouping: entries) { entry -> String in
            let name = store.displayLocationName(for: entry)
            return name.isEmpty ? "Unassigned" : name
        }
        return grouped.map { name, group in
            GroupStat(name: name, count: group.count, minutes: group.reduce(0) { $0 + minutes(for: $1) })
        }.sorted { $0.count > $1.count }
    }

    private struct TypeStat: Identifiable {
        let id: DiveLogType
        var count: Int
    }

    private var byType: [TypeStat] {
        DiveLogType.allCases.map { type in
            TypeStat(id: type, count: entries.filter { $0.diveType == type }.count)
        }
    }

    var body: some View {
        Group {
            if entries.isEmpty {
                Text("No dives logged yet. Statistics will show up here once you've logged a few dives.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                List {
                    Section("Overview") {
                        StatRow(label: "Total Dives", value: "\(entries.count)")
                        StatRow(label: "Total Dive Time", value: formatMinutes(totalMinutes))
                        if let longestDive {
                            StatRow(
                                label: "Longest Dive",
                                value: "\(Int(minutes(for: longestDive))) min",
                                detail: detailLine(for: longestDive)
                            )
                        }
                        if let shortestDive {
                            StatRow(
                                label: "Shortest Dive",
                                value: "\(Int(minutes(for: shortestDive))) min",
                                detail: detailLine(for: shortestDive)
                            )
                        }
                    }

                    Section("By Dive Type") {
                        ForEach(byType) { stat in
                            StatRow(label: stat.id.rawValue, value: "\(stat.count)")
                        }
                    }

                    Section("By Location") {
                        ForEach(byLocation) { stat in
                            StatRow(label: stat.name, value: "\(stat.count) dive\(stat.count == 1 ? "" : "s")")
                        }
                    }

                    Section {
                        ForEach(byDevice) { stat in
                            StatRow(
                                label: stat.name,
                                value: formatMinutes(stat.minutes),
                                detail: "\(stat.count) dive\(stat.count == 1 ? "" : "s")"
                            )
                        }
                    } header: {
                        Text("By Dive Computer")
                    } footer: {
                        Text("Only dives imported from a Bluetooth/Garmin download are attributed to a specific computer; hand-logged dives are grouped under \"Manually Logged\". Rename a computer (Dives → Dive Computers) to tell two units of the same model apart.")
                    }
                }
            }
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func detailLine(for entry: DiveLogEntry) -> String {
        let name = store.displayLocationName(for: entry)
        let date = entry.date.formatted(date: .abbreviated, time: .omitted)
        return name.isEmpty ? date : "\(name) · \(date)"
    }

    private func formatMinutes(_ minutes: Double) -> String {
        let total = Int(minutes.rounded())
        let hours = total / 60
        let remainder = total % 60
        if hours == 0 { return "\(remainder) min" }
        return "\(hours)h \(remainder)m"
    }
}

/// A label/value row with an optional secondary detail line underneath,
/// used throughout this screen's stat sections.
private struct StatRow: View {
    let label: String
    let value: String
    var detail: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        StatisticsView(store: AppStore())
    }
}
