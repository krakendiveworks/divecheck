import SwiftUI

/// Checklists within one training certification level -- for PADI Open
/// Water Diver Confined Water, that's Dive 1 through Dive 5 in order,
/// followed by the Waterskills Assessment and Dive Flexible Skills
/// checklists (skills that can be completed across any of the dives).
struct TrainingCertificationDetailView: View {
    @ObservedObject var store: AppStore
    let agencyID: UUID
    let certificationID: UUID

    private var certification: TrainingCertification? {
        store.trainingAgencies.first { $0.id == agencyID }?
            .certifications.first { $0.id == certificationID }
    }

    var body: some View {
        Group {
            if let certification {
                List {
                    Section("Checklists") {
                        ForEach(certification.checklists) { checklist in
                            NavigationLink(
                                value: ChecklistRoute.trainingChecklist(
                                    agencyID: agencyID,
                                    certificationID: certificationID,
                                    checklistID: checklist.id
                                )
                            ) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(checklist.name).font(.body.weight(.medium))
                                    // These checklists are reference-only lists
                                    // (no checkable items -- see
                                    // TrainingSeedData's item() helpers), so
                                    // there's no progress to report here.
                                    let p = checklist.progress
                                    if p.total > 0 {
                                        Text("\(p.checked)/\(p.total) complete")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle(certification.name)
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("Certification not found")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        TrainingCertificationDetailView(store: AppStore(), agencyID: UUID(), certificationID: UUID())
    }
}
