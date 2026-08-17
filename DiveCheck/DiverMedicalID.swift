import Foundation

/// A personal medical ID card for the diver themselves -- separate from the
/// per-Location Emergency Action Plans (EmergencyActionPlan.swift), which
/// are about a dive site. This is what a buddy, boat crew, or EMS would
/// need if *you* are the one who's hurt: who you are, what to know
/// medically, and who to call. There's only ever one of these per app
/// install (see `AppStore.diverMedicalID`), unlike EAPs which are one per
/// Location.
struct DiverMedicalID: Identifiable, Codable, Equatable {
    let id: UUID
    var fullName: String
    var dateOfBirth: Date?
    var bloodType: String
    var allergies: String
    var medications: String
    var medicalConditions: String

    var emergencyContactName: String
    var emergencyContactPhone: String
    var emergencyContactRelationship: String

    var physicianName: String
    var physicianPhone: String

    /// DAN (or equivalent dive-accident insurance) membership number, if
    /// the diver has one -- handy to have on hand alongside the DAN
    /// Emergency Hotline already shown on every EAP.
    var danMembershipNumber: String

    var additionalNotes: String

    /// Filename of an uploaded PDF copy of a signed WRSTC (World
    /// Recreational Scuba Training Council) medical statement/questionnaire
    /// -- stored on disk via DocumentStorage (see DocumentStorage.swift)
    /// rather than embedded in this struct, same file-on-disk-by-filename
    /// pattern as Certification card images and Dive Log photos. This is
    /// the actual signed form a diver already has, separate from the
    /// typed-in medical info above (which gets rendered fresh to its own
    /// PDF via DiverMedicalIDPDFRenderer, not read from this file).
    var wrstcFormFilename: String?
    var wrstcFormUploadedAt: Date?

    init(
        id: UUID = UUID(),
        fullName: String = "",
        dateOfBirth: Date? = nil,
        bloodType: String = "",
        allergies: String = "",
        medications: String = "",
        medicalConditions: String = "",
        emergencyContactName: String = "",
        emergencyContactPhone: String = "",
        emergencyContactRelationship: String = "",
        physicianName: String = "",
        physicianPhone: String = "",
        danMembershipNumber: String = "",
        additionalNotes: String = "",
        wrstcFormFilename: String? = nil,
        wrstcFormUploadedAt: Date? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.dateOfBirth = dateOfBirth
        self.bloodType = bloodType
        self.allergies = allergies
        self.medications = medications
        self.medicalConditions = medicalConditions
        self.emergencyContactName = emergencyContactName
        self.emergencyContactPhone = emergencyContactPhone
        self.emergencyContactRelationship = emergencyContactRelationship
        self.physicianName = physicianName
        self.physicianPhone = physicianPhone
        self.danMembershipNumber = danMembershipNumber
        self.additionalNotes = additionalNotes
        self.wrstcFormFilename = wrstcFormFilename
        self.wrstcFormUploadedAt = wrstcFormUploadedAt
    }
}
