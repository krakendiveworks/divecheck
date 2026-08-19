import SwiftUI
import UIKit

/// Editable view of a saved certification snapshot -- mirrors
/// SavedChecklistDetailView.swift. The card photo and certification PDF (if
/// any) are view/export-only here -- no replace/remove -- since a saved
/// snapshot's files are meant to stay exactly as they were saved. Every
/// text/date field stays editable, and tapping Update refreshes the saved
/// timestamp.
struct SavedCertificationDetailView: View {
    @ObservedObject var store: AppStore
    let savedID: UUID
    @State private var cardImage: UIImage?
    @State private var isShowingFullScreenImage = false
    @State private var isShowingUpdatedConfirmation = false
    @State private var shareItems: [Any]?
    @State private var isShowingDocumentPreview = false

    private var saved: Binding<SavedCertification> {
        store.savedCertificationBinding(for: savedID)
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved")
                        .font(.headline)
                    Text(saved.wrappedValue.savedAt.formatted(date: .long, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }

            if cardImage != nil {
                Section("Card Image") {
                    cardImageSection
                }
            }

            if let filename = saved.wrappedValue.certification.cardDocumentFilename {
                Section("Certification Document (PDF)") {
                    cardDocumentSection(filename: filename)
                }
            }

            Section("Certification") {
                LabeledTextField(label: "Course", text: saved.certification.courseName)
                LabeledTextField(label: "Agency", text: saved.certification.agency)
                LabeledTextField(label: "Cert Number", text: saved.certification.certificationNumber)
                LabeledTextField(label: "Instructor / Facility", text: saved.certification.instructorOrFacility)
            }

            Section("Dates") {
                DatePicker(
                    "Date Certified",
                    selection: Binding(
                        get: { saved.wrappedValue.certification.dateCertified ?? Date() },
                        set: { saved.wrappedValue.certification.dateCertified = $0 }
                    ),
                    displayedComponents: .date
                )
                Toggle("Has an expiration date", isOn: Binding(
                    get: { saved.wrappedValue.certification.expirationDate != nil },
                    set: { hasExpiration in
                        saved.wrappedValue.certification.expirationDate = hasExpiration ? (saved.wrappedValue.certification.expirationDate ?? Date()) : nil
                    }
                ))
                if saved.wrappedValue.certification.expirationDate != nil {
                    DatePicker(
                        "Expires",
                        selection: Binding(
                            get: { saved.wrappedValue.certification.expirationDate ?? Date() },
                            set: { saved.wrappedValue.certification.expirationDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                }
            }

            Section("Notes") {
                TextField("Anything else worth having on hand", text: saved.certification.notes, axis: .vertical)
                    .lineLimit(1...6)
            }
        }
        .navigationTitle(saved.wrappedValue.certification.courseName.isEmpty ? "Certification" : saved.wrappedValue.certification.courseName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                saved.wrappedValue.savedAt = Date()
                isShowingUpdatedConfirmation = true
            } label: {
                Label("Update", systemImage: "tray.and.arrow.down")
            }
        }
        .onAppear {
            if cardImage == nil, let filename = saved.wrappedValue.certification.cardImageFilename {
                cardImage = PhotoStorage.load(filename)
            }
        }
        .fullScreenCover(isPresented: $isShowingFullScreenImage) {
            if let cardImage {
                FullScreenImageViewer(image: cardImage)
            }
        }
        .background(ShareSheetPresenter(items: $shareItems))
        .sheet(isPresented: $isShowingDocumentPreview) {
            if let filename = saved.wrappedValue.certification.cardDocumentFilename {
                NavigationStack {
                    DocumentPreview(url: DocumentStorage.url(for: filename))
                        .navigationTitle("Certification Document")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    isShowingDocumentPreview = false
                                }
                            }
                        }
                }
            }
        }
        .alert("Saved Certification Updated", isPresented: $isShowingUpdatedConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your changes have been saved. This entry stays editable — come back and tap Update again anytime.")
        }
    }

    @ViewBuilder
    private var cardImageSection: some View {
        if let cardImage {
            Image(uiImage: cardImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 220)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
                .onTapGesture {
                    isShowingFullScreenImage = true
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
    }

    @ViewBuilder
    private func cardDocumentSection(filename: String) -> some View {
        HStack {
            Image(systemName: "doc.richtext.fill")
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("Certification PDF on File")
                    .font(.body.weight(.medium))
                if let uploadedAt = saved.wrappedValue.certification.cardDocumentUploadedAt {
                    Text("Uploaded \(uploadedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isShowingDocumentPreview = true
        }

        Button {
            isShowingDocumentPreview = true
        } label: {
            Label("View", systemImage: "eye")
        }
        Button {
            shareItems = [DocumentStorage.url(for: filename)]
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
        }
    }
}

#Preview {
    NavigationStack {
        SavedCertificationDetailView(store: AppStore(), savedID: UUID())
    }
}
