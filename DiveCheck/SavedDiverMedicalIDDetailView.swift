import SwiftUI
import UIKit

/// Editable view of a saved Diver Medical ID snapshot -- mirrors
/// SavedChecklistDetailView.swift. The WRSTC form and DAN insurance card
/// (if any) are view/export only here -- no replace/remove -- since a
/// saved snapshot's files are meant to stay exactly as they were saved.
/// Every other field stays editable, and tapping Update refreshes the
/// saved timestamp.
struct SavedDiverMedicalIDDetailView: View {
    @ObservedObject var store: AppStore
    let savedID: UUID
    @State private var shareItems: [Any]?
    @State private var isShowingPreview = false
    @State private var isShowingDanCardPreview = false
    @State private var isShowingUpdatedConfirmation = false
    @State private var danCardImage: UIImage?

    private var saved: Binding<SavedDiverMedicalID> {
        store.savedDiverMedicalIDBinding(for: savedID)
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

            if let filename = saved.wrappedValue.medicalID.wrstcFormFilename {
                Section("WRSTC Medical Form") {
                    HStack {
                        Image(systemName: "doc.richtext.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("WRSTC Form on File")
                                .font(.body.weight(.medium))
                            if let uploadedAt = saved.wrappedValue.medicalID.wrstcFormUploadedAt {
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
                }
            }

            Section("Identity") {
                LabeledTextField(label: "Full Name", text: saved.medicalID.fullName)
                DatePicker(
                    "Date of Birth",
                    selection: Binding(
                        get: { saved.wrappedValue.medicalID.dateOfBirth ?? Date() },
                        set: { saved.wrappedValue.medicalID.dateOfBirth = $0 }
                    ),
                    displayedComponents: .date
                )
                LabeledTextField(label: "Blood Type", text: saved.medicalID.bloodType)
            }

            Section("Medical") {
                LabeledMultilineField(label: "Allergies", text: saved.medicalID.allergies)
                LabeledMultilineField(label: "Medications", text: saved.medicalID.medications)
                LabeledMultilineField(label: "Medical Conditions", text: saved.medicalID.medicalConditions)
            }

            Section("Emergency Contact") {
                LabeledTextField(label: "Name", text: saved.medicalID.emergencyContactName)
                LabeledTextField(label: "Relationship", text: saved.medicalID.emergencyContactRelationship)
                LabeledTextField(label: "Phone", text: saved.medicalID.emergencyContactPhone)
            }

            Section("Physician") {
                LabeledTextField(label: "Name", text: saved.medicalID.physicianName)
                LabeledTextField(label: "Phone", text: saved.medicalID.physicianPhone)
            }

            Section("DAN Membership") {
                LabeledTextField(label: "Membership #", text: saved.medicalID.danMembershipNumber)

                if let danCardImage {
                    Image(uiImage: danCardImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                if let filename = saved.wrappedValue.medicalID.danCardDocumentFilename {
                    HStack {
                        Image(systemName: "doc.richtext.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("DAN Card PDF on File")
                                .font(.body.weight(.medium))
                            if let uploadedAt = saved.wrappedValue.medicalID.danCardDocumentUploadedAt {
                                Text("Uploaded \(uploadedAt.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isShowingDanCardPreview = true
                    }

                    Button {
                        isShowingDanCardPreview = true
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

            Section("Additional Notes") {
                TextField("Anything else worth having on hand", text: saved.medicalID.additionalNotes, axis: .vertical)
                    .lineLimit(1...6)
            }
        }
        .navigationTitle(saved.wrappedValue.medicalID.fullName.isEmpty ? "Diver Medical ID" : saved.wrappedValue.medicalID.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button {
                saved.wrappedValue.savedAt = Date()
                isShowingUpdatedConfirmation = true
            } label: {
                Label("Update", systemImage: "tray.and.arrow.down")
            }
        }
        .background(ShareSheetPresenter(items: $shareItems))
        .sheet(isPresented: $isShowingPreview) {
            if let filename = saved.wrappedValue.medicalID.wrstcFormFilename {
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
        .sheet(isPresented: $isShowingDanCardPreview) {
            if let filename = saved.wrappedValue.medicalID.danCardDocumentFilename {
                NavigationStack {
                    DocumentPreview(url: DocumentStorage.url(for: filename))
                        .navigationTitle("DAN Insurance Card")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    isShowingDanCardPreview = false
                                }
                            }
                        }
                }
            }
        }
        .onAppear {
            if danCardImage == nil, let filename = saved.wrappedValue.medicalID.danCardImageFilename {
                danCardImage = PhotoStorage.load(filename)
            }
        }
        .alert("Saved Copy Updated", isPresented: $isShowingUpdatedConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your changes have been saved. This entry stays editable — come back and tap Update again anytime.")
        }
    }
}

#Preview {
    NavigationStack {
        SavedDiverMedicalIDDetailView(store: AppStore(), savedID: UUID())
    }
}
