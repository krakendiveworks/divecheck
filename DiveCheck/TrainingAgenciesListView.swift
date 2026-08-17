import SwiftUI

/// Top level of the Training section (main menu, shown when
/// AppStore.isTrainingSectionEnabled is on): one row per certifying agency
/// that has content built out (PADI, etc. -- see TrainingSeedData).
struct TrainingAgenciesListView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        List {
            ForEach(store.trainingAgencies) { agency in
                NavigationLink(value: ChecklistRoute.trainingAgency(agency.id)) {
                    AgencyRow(agency: agency)
                }
            }
        }
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AgencyRow: View {
    let agency: TrainingAgency

    private var subtitle: String {
        let count = agency.certifications.count
        return count == 1 ? "1 certification" : "\(count) certifications"
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
        TrainingAgenciesListView(store: AppStore())
    }
}
