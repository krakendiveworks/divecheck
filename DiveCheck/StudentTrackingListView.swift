import SwiftUI

/// Training > Student Tracking: candidate-tracked programs (e.g. PADI's
/// Divemaster Program) used to be listed on each agency's own class-slates
/// page; they're broken out into this dedicated menu instead, since running
/// a roster of students through shared requirements is a different job
/// than working a personal certification checklist. One row per agency
/// that actually has a program built out -- tapping an agency opens its
/// list of programs (see StudentTrackingAgencyProgramsListView), which then
/// leads to the same roster screen (TrainingCandidatesListView) this always
/// used.
struct StudentTrackingListView: View {
    @ObservedObject var store: AppStore

    private var agenciesWithPrograms: [TrainingAgency] {
        store.trainingAgencies.filter { !$0.rosterPrograms.isEmpty }
    }

    var body: some View {
        List {
            if agenciesWithPrograms.isEmpty {
                Text("No student tracking programs yet.")
                    .foregroundStyle(.secondary)
            }
            ForEach(agenciesWithPrograms) { agency in
                NavigationLink(value: ChecklistRoute.studentTrackingAgency(agency.id)) {
                    AgencyProgramsRow(agency: agency)
                }
            }
        }
        .navigationTitle("Student Tracking")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AgencyProgramsRow: View {
    let agency: TrainingAgency

    private var subtitle: String {
        let count = agency.rosterPrograms.count
        return count == 1 ? "1 program" : "\(count) programs"
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: agency.symbolName)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(agency.name).font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        StudentTrackingListView(store: AppStore())
    }
}
