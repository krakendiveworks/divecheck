import SwiftUI

/// Class slates (certification levels) built out for one training agency
/// (e.g. PADI's "Open Water Diver -- Confined Water Dives"). Candidate-
/// tracked programs (e.g. PADI Divemaster) used to have a "Programs"
/// section here too -- they now live under Training > Student Tracking
/// instead, see StudentTrackingListView.
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

#Preview {
    NavigationStack {
        TrainingCertificationsListView(store: AppStore(), agencyID: UUID())
    }
}
