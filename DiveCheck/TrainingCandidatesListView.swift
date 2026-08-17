import SwiftUI

/// Roster for one candidate-tracked training program (e.g. PADI Divemaster)
/// -- active candidates first, then an Archived section for candidates
/// who've finished or been closed out (see
/// AppStore.setTrainingCandidateArchived). Adding a candidate hands them
/// their own independent copy of the program's requirement checklists, so
/// their progress never affects another candidate's -- see
/// AppStore.addTrainingCandidate.
struct TrainingCandidatesListView: View {
    @ObservedObject var store: AppStore
    let agencyID: UUID
    let programID: UUID
    @Binding var path: [ChecklistRoute]

    @State private var isShowingAddCandidate = false

    private var program: TrainingRosterProgram? {
        store.trainingAgencies.first { $0.id == agencyID }?
            .rosterPrograms.first { $0.id == programID }
    }

    private var activeCandidates: [TrainingCandidate] {
        program?.candidates.filter { !$0.isArchived } ?? []
    }

    private var archivedCandidates: [TrainingCandidate] {
        program?.candidates.filter { $0.isArchived } ?? []
    }

    var body: some View {
        Group {
            if let program {
                List {
                    if activeCandidates.isEmpty && archivedCandidates.isEmpty {
                        Text("No candidates yet -- tap + to add one.")
                            .foregroundStyle(.secondary)
                    }
                    if !activeCandidates.isEmpty {
                        Section("Active") {
                            ForEach(activeCandidates) { candidate in
                                NavigationLink(
                                    value: ChecklistRoute.trainingCandidateDetail(
                                        agencyID: agencyID,
                                        programID: programID,
                                        candidateID: candidate.id
                                    )
                                ) {
                                    CandidateRow(candidate: candidate)
                                }
                            }
                            .onDelete { offsets in
                                for index in offsets {
                                    store.deleteTrainingCandidate(agencyID: agencyID, programID: programID, candidateID: activeCandidates[index].id)
                                }
                            }
                        }
                    }
                    if !archivedCandidates.isEmpty {
                        Section("Archived") {
                            ForEach(archivedCandidates) { candidate in
                                NavigationLink(
                                    value: ChecklistRoute.trainingCandidateDetail(
                                        agencyID: agencyID,
                                        programID: programID,
                                        candidateID: candidate.id
                                    )
                                ) {
                                    CandidateRow(candidate: candidate)
                                }
                            }
                            .onDelete { offsets in
                                for index in offsets {
                                    store.deleteTrainingCandidate(agencyID: agencyID, programID: programID, candidateID: archivedCandidates[index].id)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(program.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            isShowingAddCandidate = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $isShowingAddCandidate) {
                    AddTrainingCandidateView { name in
                        if let newCandidateID = store.addTrainingCandidate(name: name, toProgramID: programID, inAgencyID: agencyID) {
                            path.append(.trainingCandidateDetail(agencyID: agencyID, programID: programID, candidateID: newCandidateID))
                        }
                    }
                }
            } else {
                Text("Program not found")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct CandidateRow: View {
    let candidate: TrainingCandidate

    private var progressText: String {
        let p = candidate.progress
        return p.total > 0 ? "\(p.checked)/\(p.total) complete" : "No items yet"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(candidate.name).font(.body.weight(.medium))
            Text(progressText).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        TrainingCandidatesListView(store: AppStore(), agencyID: UUID(), programID: UUID(), path: .constant([]))
    }
}
