import SwiftUI
import UniformTypeIdentifiers

/// Edits the diver's own personal medical ID card -- allergies, medications,
/// conditions, and who to contact -- for when the diver themselves is the
/// one who's hurt. There's only one of these (see AppStore.medicalIDBinding),
/// unlike Emergency Action Plans which are one per Location.
struct DiverMedicalIDView: View {
    @ObservedObject var store: AppStore
    @State private var shareItems: [Any]?
    @State private var isShowingFileImporter = false
    @State private var isShowingPreview = false

    private var card: Binding<DiverMedicalID> {
        store.medicalIDBinding
    }

    var body: some View {
        Form {
            Section {
                wrstcFormSection
            } header: {
                Text("WRSTC Medical Form")
            } footer: {
                Text("Upload a PDF copy of a signed WRSTC (World Recreational Scuba Training Council) medical statement or questionnaire -- the actual paper form, separate from the typed-in medical info below.")
            }

            Section("Identity") {
                LabeledTextField(label: "Full Name", text: card.fullName)
                DatePicker(
                    "Date of Birth",
                    selection: Binding(
                        get: { card.wrappedValue.dateOfBirth ?? Date() },
                        set: { card.wrappedValue.dateOfBirth = $0 }
                    ),
                    displayedComponents: .date
                )
                LabeledTextField(label: "Blood Type", text: card.bloodType, placeholder: "O+, A-, etc.")
            }

            Section("Medical") {
                LabeledMultilineField(label: "Allergies", text: card.allergies, placeholder: "Medications, food, latex, etc.")
                LabeledMultilineField(label: "Medications", text: card.medications)
                LabeledMultilineField(label: "Medical Conditions", text: card.medicalConditions, placeholder: "Asthma, diabetes, cardiac history, etc.")
            }

            Section("Emergency Contact") {
                LabeledTextField(label: "Name", text: card.emergencyContactName)
                LabeledTextField(label: "Relationship", text: card.emergencyContactRelationship)
                HStack {
                    Text("Phone")
                    Spacer()
                    TextField("Phone", text: Binding(
                        get: { card.wrappedValue.emergencyContactPhone },
                        set: { card.wrappedValue.emergencyContactPhone = PhoneFormatting.format($0) }
                    ))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.phonePad)
                    .foregroundStyle(.secondary)
                    if let url = PhoneFormatting.telURL(card.wrappedValue.emergencyContactPhone) {
                        Link(destination: url) {
                            Image(systemName: "phone.fill")
                        }
                    }
                }
            }

            Section("Physician") {
                LabeledTextField(label: "Name", text: card.physicianName)
                HStack {
                    Text("Phone")
                    Spacer()
                    TextField("Phone", text: Binding(
                        get: { card.wrappedValue.physicianPhone },
                        set: { card.wrappedValue.physicianPhone = PhoneFormatting.format($0) }
                    ))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.phonePad)
                    .foregroundStyle(.secondary)
                    if let url = PhoneFormatting.telURL(card.wrappedValue.physicianPhone) {
                        Link(destination: url) {
                            Image(systemName: "phone.fill")
                        }
                    }
                }
            }

            Section {
                LabeledTextField(label: "Membership #", text: card.danMembershipNumber)
            } header: {
                Text("DAN Membership")
            } footer: {
                Text("DAN Emergency Hotline: \(EmergencyActionPlan.danEmergencyHotline) -- shown on every Emergency Action Plan.")
            }

            Section("Additional Notes") {
                TextField("Anything else worth having on hand", text: card.additionalNotes, axis: .vertical)
                    .lineLimit(1...6)
            }
        }
        .navigationTitle("Diver Medical ID")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                if let url = DiverMedicalIDPDFRenderer.renderPDF(card: card.wrappedValue) {
                    shareItems = [url]
                }
            } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .background(ShareSheetPresenter(items: $shareItems))
        .fileImporter(isPresented: $isShowingFileImporter, allowedContentTypes: [.pdf]) { result in
            handleFileImportResult(result)
        }
        .sheet(isPresented: $isShowingPreview) {
            if let filename = card.wrappedValue.wrstcFormFilename {
                // QLPreviewController normally gets its own "Done" button
                // for free when UIKit presents it directly, but it's being
                // embedded as a SwiftUI .sheet's content here instead (same
                // situation as the EAP/Diver Medical ID PDF ShareSheet
                // fix), so it doesn't get that automatically -- wrapping it
                // in our own NavigationStack with an explicit Done button
                // guarantees a reliable way back out regardless of whether
                // swipe-to-dismiss gets captured by the PDF's own scrolling.
                NavigationStack {
                    DocumentPreview(url: DocumentStorage.url(for: filename))
                        .navigationTitle("WRSTC Medical Form")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    isShowingPreview = false
                                }
                            }
                        }
                }
            }
        }
    }

    @ViewBuilder
    private var wrstcFormSection: some View {
        if let filename = card.wrappedValue.wrstcFormFilename {
            HStack {
                Image(systemName: "doc.richtext.fill")
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("WRSTC Form on File")
                        .font(.body.weight(.medium))
                    if let uploadedAt = card.wrappedValue.wrstcFormUploadedAt {
                        Text("Uploaded \(uploadedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isShowingPreview = true
            }

            Button {
                isShowingPreview = true
            } label: {
                Label("View", systemImage: "eye")
            }
            Button {
                shareItems = [DocumentStorage.url(for: filename)]
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            Button {
                isShowingFileImporter = true
            } label: {
                Label("Replace", systemImage: "arrow.triangle.2.circlepath")
            }
            Button(role: .destructive) {
                removeWRSTCForm()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        } else {
            Button {
                isShowingFileImporter = true
            } label: {
                Label("Upload PDF", systemImage: "doc.badge.plus")
            }
        }
    }

    /// Saves a newly-picked PDF to disk via DocumentStorage, deletes
    /// whatever form previously occupied this slot (if any), and points
    /// the card at the new filename.
    private func handleFileImportResult(_ result: Result<URL, Error>) {
        guard case .success(let sourceURL) = result, let filename = DocumentStorage.save(from: sourceURL) else { return }
        if let oldFilename = card.wrappedValue.wrstcFormFilename {
            DocumentStorage.delete(oldFilename)
        }
        card.wrappedValue.wrstcFormFilename = filename
        card.wrappedValue.wrstcFormUploadedAt = Date()
    }

    private func removeWRSTCForm() {
        if let filename = card.wrappedValue.wrstcFormFilename {
            DocumentStorage.delete(filename)
        }
        card.wrappedValue.wrstcFormFilename = nil
        card.wrappedValue.wrstcFormUploadedAt = nil
    }
}

#Preview {
    NavigationStack {
        DiverMedicalIDView(store: AppStore())
    }
}
