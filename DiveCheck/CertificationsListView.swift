import SwiftUI

/// Lists all saved diver certifications, reachable via Plan. Tapping "+"
/// creates a blank certification and opens it immediately for editing, same
/// lazy-creation pattern used by Dive Log and Locations.
struct CertificationsListView: View {
    @ObservedObject var store: AppStore
    @Binding var path: [ChecklistRoute]

    private var sorted: [Certification] {
        store.certifications.sorted { lhs, rhs in
            (lhs.dateCertified ?? .distantPast) > (rhs.dateCertified ?? .distantPast)
        }
    }

    var body: some View {
        List {
            if store.certifications.isEmpty {
                Section {
                    Text("No certifications saved yet. Add your Open Water, specialty, or professional-level cards here.")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(sorted) { certification in
                        NavigationLink(value: ChecklistRoute.certificationDetail(certification.id)) {
                            row(for: certification)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            store.deleteCertification(sorted[index].id)
                        }
                    }
                }
            }
        }
        .navigationTitle("Certifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                let id = store.addBlankCertification()
                path.append(.certificationDetail(id))
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    private func row(for certification: Certification) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(certification.courseName.isEmpty ? "Untitled Certification" : certification.courseName)
                    .font(.body.weight(.medium))
                Spacer()
                if certification.isExpired {
                    StatusBadge(text: "Expired", symbolName: "exclamationmark.triangle.fill", color: .red)
                } else if certification.isExpiringSoon {
                    StatusBadge(text: "Expiring Soon", symbolName: "clock.fill", color: .orange)
                }
            }
            if !certification.agency.isEmpty {
                Text(certification.agency)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        CertificationsListView(store: AppStore(), path: .constant([]))
    }
}
