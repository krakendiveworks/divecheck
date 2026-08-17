import SwiftUI
import PhotosUI
import UIKit

/// Edits a single diver certification.
struct CertificationDetailView: View {
    @ObservedObject var store: AppStore
    let certificationID: UUID
    @State private var cardImage: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isShowingCamera = false
    @State private var isShowingFullScreenImage = false
    /// True when the Agency picker is on "Other" -- either the diver chose
    /// it explicitly, or the saved `agency` string doesn't match any of
    /// `Certification.knownAgencies` (e.g. an existing certification typed
    /// in before this picker existed). Recomputed from `agency` in
    /// `onAppear` rather than persisted itself.
    @State private var isOtherAgency = false
    private static let otherAgencyTag = "Other"

    private var certification: Binding<Certification> {
        store.certificationBinding(for: certificationID)
    }

    /// Drives the Agency picker. Reads/writes `isOtherAgency` alongside
    /// `certification.agency` so picking "Other" reveals the freeform field
    /// immediately even though `agency` itself starts out empty.
    private var agencySelection: Binding<String> {
        Binding(
            get: {
                isOtherAgency ? Self.otherAgencyTag : certification.wrappedValue.agency
            },
            set: { newValue in
                if newValue == Self.otherAgencyTag {
                    if !isOtherAgency {
                        certification.wrappedValue.agency = ""
                    }
                    isOtherAgency = true
                } else {
                    isOtherAgency = false
                    certification.wrappedValue.agency = newValue
                }
            }
        )
    }

    var body: some View {
        Form {
            Section("Card Image") {
                cardImageSection
            }

            Section("Certification") {
                LabeledTextField(label: "Course", text: certification.courseName, placeholder: "Open Water Diver")
                Picker("Agency", selection: agencySelection) {
                    Text("Select Agency").tag("")
                    ForEach(Certification.knownAgencies, id: \.self) { agency in
                        Text(agency).tag(agency)
                    }
                    Text("Other").tag(Self.otherAgencyTag)
                }
                if isOtherAgency {
                    LabeledTextField(label: "Agency Name", text: certification.agency, placeholder: "Enter agency name")
                }
                LabeledTextField(label: "Cert Number", text: certification.certificationNumber)
                LabeledTextField(label: "Instructor / Facility", text: certification.instructorOrFacility)
            }

            Section("Dates") {
                DatePicker(
                    "Date Certified",
                    selection: Binding(
                        get: { certification.wrappedValue.dateCertified ?? Date() },
                        set: { certification.wrappedValue.dateCertified = $0 }
                    ),
                    displayedComponents: .date
                )
                Toggle("Has an expiration date", isOn: Binding(
                    get: { certification.wrappedValue.expirationDate != nil },
                    set: { hasExpiration in
                        certification.wrappedValue.expirationDate = hasExpiration ? (certification.wrappedValue.expirationDate ?? Date()) : nil
                    }
                ))
                if certification.wrappedValue.expirationDate != nil {
                    DatePicker(
                        "Expires",
                        selection: Binding(
                            get: { certification.wrappedValue.expirationDate ?? Date() },
                            set: { certification.wrappedValue.expirationDate = $0 }
                        ),
                        displayedComponents: .date
                    )
                    if certification.wrappedValue.isExpired {
                        Label("This certification has expired.", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.footnote)
                    } else if certification.wrappedValue.isExpiringSoon {
                        Label("Expiring within 60 days.", systemImage: "clock.fill")
                            .foregroundStyle(.orange)
                            .font(.footnote)
                    }
                }
            }

            Section("Notes") {
                TextField("Anything else worth having on hand", text: certification.notes, axis: .vertical)
                    .lineLimit(1...6)
            }
        }
        .navigationTitle(certification.wrappedValue.courseName.isEmpty ? "Certification" : certification.wrappedValue.courseName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if cardImage == nil, let filename = certification.wrappedValue.cardImageFilename {
                cardImage = PhotoStorage.load(filename)
            }
            let currentAgency = certification.wrappedValue.agency
            isOtherAgency = !currentAgency.isEmpty && !Certification.knownAgencies.contains(currentAgency)
        }
        // onChange(of:perform:) was deprecated in iOS 17 in favor of a
        // two-parameter (or zero-parameter) closure, but the replacement
        // isn't available pre-iOS 17 -- branching here keeps iOS 16
        // support while avoiding the deprecation warning on newer OS
        // versions. Same pattern used for Dive Log Photos.
        .modifier(PhotoPickerChangeModifier(item: $photoPickerItem, onChange: loadPickedPhoto))
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraCapture { data in
                savePhotoData(data)
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $isShowingFullScreenImage) {
            if let cardImage {
                FullScreenImageViewer(image: cardImage)
            }
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
        } else {
            HStack {
                Spacer()
                Text("No photo of the card yet")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                Spacer()
            }
            .padding(.vertical, 8)
        }

        HStack {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    isShowingCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                Label(cardImage == nil ? "Choose Photo" : "Replace Photo", systemImage: "photo.badge.plus")
            }
            .buttonStyle(.borderless)
            if cardImage != nil {
                Spacer()
                Button(role: .destructive) {
                    removePhoto()
                } label: {
                    Label("Remove", systemImage: "trash")
                }
                .buttonStyle(.borderless)
            }
        }
    }

    /// Writes freshly-picked photo data to disk via PhotoStorage, deletes
    /// whatever image previously occupied this slot (if any), and points
    /// the certification at the new filename.
    private func savePhotoData(_ data: Data) {
        guard let filename = PhotoStorage.save(data) else { return }
        if let oldFilename = certification.wrappedValue.cardImageFilename {
            PhotoStorage.delete(oldFilename)
        }
        certification.wrappedValue.cardImageFilename = filename
        cardImage = PhotoStorage.load(filename)
    }

    private func loadPickedPhoto() {
        guard let item = photoPickerItem else { return }
        photoPickerItem = nil
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                savePhotoData(data)
            }
        }
    }

    private func removePhoto() {
        if let filename = certification.wrappedValue.cardImageFilename {
            PhotoStorage.delete(filename)
        }
        certification.wrappedValue.cardImageFilename = nil
        cardImage = nil
    }
}

/// Isolates the iOS-17-vs-16 onChange(of:) signature split into a single
/// reusable ViewModifier, since PhotosPicker selection handling needs this
/// same branch in more than one screen (see also DiveLogDetailView.swift).
private struct PhotoPickerChangeModifier: ViewModifier {
    @Binding var item: PhotosPickerItem?
    let onChange: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.onChange(of: item) { _, _ in onChange() }
        } else {
            content.onChange(of: item) { _ in onChange() }
        }
    }
}

#Preview {
    NavigationStack {
        CertificationDetailView(store: AppStore(), certificationID: UUID())
    }
}
