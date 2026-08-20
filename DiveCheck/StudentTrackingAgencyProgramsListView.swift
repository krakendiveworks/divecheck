import SwiftUI

/// One agency's candidate-tracked programs (e.g. PADI's Divemaster
/// Program) -- reached via Training > Student Tracking > agency. Tapping a
/// program leads to its roster (TrainingCandidatesListView), unchanged
/// from when this lived on the agency's own class-slates page (see
/// TrainingCertificationsListView).
struct StudentTrackingAgencyProgramsListView: View {
    @ObservedObject var store: AppStore
    let agencyID: UUID

    private var agency: TrainingAgency? {
        store.trainingAgencies.first { $0.id == agencyID }
    }

    var body: some View {
        Group {
            if let agency {
                List {
                    ForEach(agency.rosterPrograms) { program in
                        NavigationLink(
                            value: ChecklistRoute.trainingRosterProgram(agencyID: agencyID, programID: program.id)
                        ) {
                            RosterProgramRow(program: program)
                        }
                    }
                }
                .navigationTitle(agency.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("Agency not found")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// A candidate-tracked program (e.g. PADI Divemaster), where progress is
/// recorded per-student rather than as a single personal checklist -- see
/// TrainingRosterProgram.
private struct RosterProgramRow: View {
    let program: TrainingRosterProgram

    private var subtitleText: String {
        let activeCount = program.candidates.filter { !$0.isArchived }.count
        switch activeCount {
        case 0: return "No active candidates"
        case 1: return "1 active candidate"
        default: return "\(activeCount) active candidates"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(program.name).font(.body.weight(.medium))
            Text(subtitleText).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        StudentTrackingAgencyProgramsListView(store: AppStore(), agencyID: UUID())
    }
}
