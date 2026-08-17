import SwiftUI

/// One candidate's progress through a roster program's requirement
/// checklists (e.g. a Divemaster candidate's Waterskills Exercises, Diver
/// Rescue & Dive Skills Workshop, Practical Skills, Divemaster-Conducted
/// Program Workshops and Practical Assessments) -- each checklist here is
/// this candidate's own independent copy, so checking items off never
/// affects another candidate or the shared program template. Archiving
/// (rather than deleting) is how a candidate's progress gets kept on
/// record once they're done -- see AppStore.setTrainingCandidateArchived.
struct TrainingCandidateDetailView: View {
    @ObservedObject var store: AppStore
    let agencyID: UUID
    let programID: UUID
    let candidateID: UUID

    private var candidate: TrainingCandidate? {
        store.trainingAgencies.first { $0.id == agencyID }?
            .rosterPrograms.first { $0.id == programID }?
            .candidates.first { $0.id == candidateID }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        Group {
            if let candidate {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(candidate.name).font(.title3.weight(.semibold))
                            Text("Started \(Self.dateFormatter.string(from: candidate.startDate))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if candidate.isArchived, let archivedDate = candidate.archivedDate {
                                Text("Archived \(Self.dateFormatter.string(from: archivedDate))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            let p = candidate.progress
                            Text(p.total > 0 ? "\(p.checked)/\(p.total) complete" : "No items yet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    Section("Requirement Checklists") {
                        ForEach(candidate.checklists) { checklist in
                            NavigationLink(
                                value: ChecklistRoute.trainingCandidateChecklist(
                                    agencyID: agencyID,
                                    programID: programID,
                                    candidateID: candidateID,
                                    checklistID: checklist.id
                                )
                            ) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(checklist.name).font(.body.weight(.medium))
                                    let p = checklist.progress
                                    Text(p.total > 0 ? "\(p.checked)/\(p.total) complete" : "No items yet")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .navigationTitle(candidate.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            store.setTrainingCandidateArchived(!candidate.isArchived, agencyID: agencyID, programID: programID, candidateID: candidateID)
                        } label: {
                            Label(
                                candidate.isArchived ? "Unarchive" : "Archive",
                                systemImage: candidate.isArchived ? "tray.and.arrow.up.fill" : "archivebox.fill"
                            )
                        }
                    }
                }
            } else {
                Text("Candidate not found")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TrainingCandidateDetailView(store: AppStore(), agencyID: UUID(), programID: UUID(), candidateID: UUID())
    }
}
