import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import UIKit

/// Edits the diver's own personal medical ID card -- allergies, medications,
/// conditions, and who to contact -- for when the diver themselves is the
/// one who's hurt. There's only one of these (see AppStore.medicalIDBinding),
/// unlike Emergency Action Plans which are one per Location.
struct DiverMedicalIDView: View {
    @ObservedObject var store: AppStore
    @State private var shareItems: [Any]?
    @State private var isShowingFileImporter = false
    @State private var isShowingPreview = false
    @State private var isShowingSavedConfirmation = false

    // DAN insurance card -- photo (PhotoStorage) and PDF (DocumentStorage)
    // are independent slots, same as Certification's cardImage/
    // cardDocument split. See danCardImageSection/danCardDocumentSection.
    @State private var danCardImage: UIImage?
    @State private var danCardPhotoPickerItem: PhotosPickerItem?
    @State private var isShowingDanCardCamera = false
    @State private var isShowingDanCardFullScreenImage = false
    @State private var isShowingDanCardDocumentImporter = false
    @State private var isShowingDanCardDocumentPreview = false

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
                danCardImageSection
                danCardDocumentSection
            } header: {
                Text("DAN Membership")
            } footer: {
                Text("DAN Emergency Hotline: \(EmergencyActionPlan.danEmergencyHotline) -- shown on every Emergency Action Plan. Optionally attach a photo or PDF of your DAN insurance card so it's on hand alongside your membership number.")
            }

            Section("Additional Notes") {
                TextField("Anything else worth having on hand", text: card.additionalNotes, axis: .vertical)
                    .lineLimit(1...6)
            }

            Section {
                NavigationLink(value: ChecklistRoute.savedDiverMedicalIDs) {
                    ToolRow(
                        title: "Saved Medical IDs",
                        subtitle: "\(store.savedDiverMedicalIDs.count) saved",
                        symbolName: "tray.full.fill"
                    )
                }
            }
        }
        .navigationTitle("Diver Medical ID")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        store.saveDiverMedicalIDSnapshot(card.wrappedValue)
                        isShowingSavedConfirmation = true
                    } label: {
                        Label("Save to History", systemImage: "tray.and.arrow.down")
                    }
                    Button {
                        if let url = DiverMedicalIDPDFRenderer.renderPDF(card: card.wrappedValue) {
                            shareItems = [url]
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .alert("Saved to History", isPresented: $isShowingSavedConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("A copy of this Diver Medical ID as it stands right now was saved. View it anytime from Saved Medical IDs above — it stays fully editable there too.")
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
        .fileImporter(isPresented: $isShowingDanCardDocumentImporter, allowedContentTypes: [.pdf]) { result in
            handleDanCardDocumentImportResult(result)
        }
        .sheet(isPresented: $isShowingDanCardDocumentPreview) {
            if let filename = card.wrappedValue.danCardDocumentFilename {
                // Same explicit-Done-button wrapping as the WRSTC preview
                // above, for the same reason.
                NavigationStack {
                    DocumentPreview(url: DocumentStorage.url(for: filename))
                        .navigationTitle("DAN Insurance Card")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    isShowingDanCardDocumentPreview = false
                                }
                            }
                        }
                }
            }
        }
        .onAppear {
            if danCardImage == nil, let filename = card.wrappedValue.danCardImageFilename {
                danCardImage = PhotoStorage.load(filename)
            }
        }
        // onChange(of:perform:) was deprecated in iOS 17 in favor of a
        // two-parameter (or zero-parameter) closure, but the replacement
        // isn't available pre-iOS 16 -- PhotoPickerChangeModifier (defined
        // in CertificationDetailView.swift, reused here) isolates that
        // branch in one place.
        .modifier(PhotoPickerChangeModifier(item: $danCardPhotoPickerItem, onChange: loadPickedDanCardPhoto))
        .fullScreenCover(isPresented: $isShowingDanCardCamera) {
            CameraCapture { data in
                saveDanCardPhotoData(data)
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $isShowingDanCardFullScreenImage) {
            if let danCardImage {
                FullScreenImageViewer(image: danCardImage)
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

    // MARK: - DAN Insurance Card (photo)

    @ViewBuilder
    private var danCardImageSection: some View {
        if let danCardImage {
            Image(uiImage: danCardImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 180)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
                .onTapGesture {
                    isShowingDanCardFullScreenImage = true
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(.black.opacity(0.45), in: Circle())
                        .padding(6)
                        .allowsHitTesting(false)
                }
        }

        HStack {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    isShowingDanCardCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            PhotosPicker(selection: $danCardPhotoPickerItem, matching: .images) {
                Label(danCardImage == nil ? "Choose Photo" : "Replace Photo", systemImage: "photo.badge.plus")
            }
            .buttonStyle(.borderless)
            if danCardImage != nil {
                Spacer()
                Button(role: .destructive) {
                    removeDanCardPhoto()
                } label: {
                    Label("Remove Photo", systemImage: "trash")
                }
                .buttonStyle(.borderless)
            }
        }
    }

    /// Writes freshly-picked photo data to disk via PhotoStorage, deletes
    /// whatever image previously occupied this slot (if any), and points
    /// the card at the new filename -- mirrors CertificationDetailView's
    /// savePhotoData.
    private func saveDanCardPhotoData(_ data: Data) {
        guard let filename = PhotoStorage.save(data) else { return }
        if let oldFilename = card.wrappedValue.danCardImageFilename {
            PhotoStorage.delete(oldFilename)
        }
        card.wrappedValue.danCardImageFilename = filename
        danCardImage = PhotoStorage.load(filename)
    }

    private func loadPickedDanCardPhoto() {
        guard let item = danCardPhotoPickerItem else { return }
        danCardPhotoPickerItem = nil
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                saveDanCardPhotoData(data)
            }
        }
    }

    private func removeDanCardPhoto() {
        if let filename = card.wrappedValue.danCardImageFilename {
            PhotoStorage.delete(filename)
        }
        card.wrappedValue.danCardImageFilename = nil
        danCardImage = nil
    }

    // MARK: - DAN Insurance Card (PDF)

    @ViewBuilder
    private var danCardDocumentSection: some View {
        if let filename = card.wrappedValue.danCardDocumentFilename {
            HStack {
                Image(systemName: "doc.richtext.fill")
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("DAN Card PDF on File")
                        .font(.body.weight(.medium))
                    if let uploadedAt = card.wrappedValue.danCardDocumentUploadedAt {
                        Text("Uploaded \(uploadedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isShowingDanCardDocumentPreview = true
            }

            Button {
                isShowingDanCardDocumentPreview = true
            } label: {
                Label("View", systemImage: "eye")
            }
            Button {
                shareItems = [DocumentStorage.url(for: filename)]
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            Button {
                isShowingDanCardDocumentImporter = true
            } label: {
                Label("Replace PDF", systemImage: "arrow.triangle.2.circlepath")
            }
            Button(role: .destructive) {
                removeDanCardDocument()
            } label: {
                Label("Remove PDF", systemImage: "trash")
            }
        } else {
            Button {
                isShowingDanCardDocumentImporter = true
            } label: {
                Label("Upload PDF", systemImage: "doc.badge.plus")
            }
        }
    }

    /// Saves a newly-picked PDF to disk via DocumentStorage, deletes
    /// whatever document previously occupied this slot (if any), and points
    /// the card at the new filename -- mirrors handleFileImportResult
    /// above (the WRSTC form's equivalent).
    private func handleDanCardDocumentImportResult(_ result: Result<URL, Error>) {
        guard case .success(let sourceURL) = result, let filename = DocumentStorage.save(from: sourceURL) else { return }
        if let oldFilename = card.wrappedValue.danCardDocumentFilename {
            DocumentStorage.delete(oldFilename)
        }
        card.wrappedValue.danCardDocumentFilename = filename
        card.wrappedValue.danCardDocumentUploadedAt = Date()
    }

    private func removeDanCardDocument() {
        if let filename = card.wrappedValue.danCardDocumentFilename {
            DocumentStorage.delete(filename)
        }
        card.wrappedValue.danCardDocumentFilename = nil
        card.wrappedValue.danCardDocumentUploadedAt = nil
    }
}

#Preview {
    NavigationStack {
        DiverMedicalIDView(store: AppStore())
    }
}
