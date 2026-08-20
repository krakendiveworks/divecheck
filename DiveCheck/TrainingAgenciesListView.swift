import SwiftUI

/// Top level of the Training section (main menu, shown when
/// AppStore.isTrainingSectionEnabled is on): one row per certifying agency
/// that has content built out (PADI, etc. -- see TrainingSeedData), plus
/// the "Scuba Class Packing" checklist as a fixed first entry -- it's an
/// instructor/dive-shop packing list rather than a per-agency skill
/// checklist, so it doesn't belong nested under a specific agency, but it
/// fits Training's "meant for instructors and divemasters" audience far
/// better than the personal per-dive checklists under Plan > Checklists
/// (see AppStore.scubaClassPackingCategory).
struct TrainingAgenciesListView: View {
    @ObservedObject var store: AppStore

    var body: some View {
        List {
            if let category = store.scubaClassPackingCategory, let checklist = category.checklists.first {
                NavigationLink(value: ChecklistRoute.checklist(categoryID: category.id, subcategoryID: nil, checklistID: checklist.id)) {
                    ToolRow(
                        title: category.name,
                        subtitle: "\(checklist.progress.checked)/\(checklist.progress.total) complete",
                        symbolName: category.symbolName
                    )
                }
            }
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
