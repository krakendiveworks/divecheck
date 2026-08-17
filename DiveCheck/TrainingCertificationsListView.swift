import SwiftUI

/// Certification levels built out for one training agency (e.g. PADI's
/// "Open Water Diver -- Confined Water Dives").
struct TrainingCertificationsListView: View {
    @ObservedObject var store: AppStore
    let agencyID: UUID

    private var agency: TrainingAgency? {
        store.trainingAgencies.first { $0.id == agencyID }
    }

    var body: some View {
        Group {
            if let agency {
                List {
                    if !agency.certifications.isEmpty {
                        Section {
                            ForEach(agency.certifications) { certification in
                                NavigationLink(
                                    value: ChecklistRoute.trainingCertification(agencyID: agencyID, certificationID: certification.id)
                                ) {
                                    CertificationRow(certification: certification)
                                }
                            }
                        }
                    }
                    if !agency.rosterPrograms.isEmpty {
                        Section("Programs") {
                            ForEach(agency.rosterPrograms) { program in
                                NavigationLink(
                                    value: ChecklistRoute.trainingRosterProgram(agencyID: agencyID, programID: program.id)
                                ) {
                                    RosterProgramRow(program: program)
                                }
                            }
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

private struct CertificationRow: View {
    let certification: TrainingCertification

    private var progressText: String {
        let checked = certification.checklists.reduce(0) { $0 + $1.progress.checked }
        let total = certification.checklists.reduce(0) { $0 + $1.progress.total }
        return total > 0 ? "\(checked)/\(total) complete" : "\(certification.checklists.count) checklist(s)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(certification.name).font(.body.weight(.medium))
            Text(progressText).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
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
        TrainingCertificationsListView(store: AppStore(), agencyID: UUID())
    }
}
