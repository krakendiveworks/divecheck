import Foundation

/// A saved diver certification card (Open Water, Advanced Open Water,
/// Nitrox, Rescue Diver, Divemaster, etc.). `agency` stays a plain String
/// for storage (so existing saved certifications, and anything typed into
/// the "Other" option, round-trip without a custom decoder) -- the editor
/// UI presents it as a picker over `Certification.knownAgencies` with an
/// "Other" fallback rather than hardcoding the field's type, since course
/// catalogs per agency aren't something this app should try to model.
struct Certification: Identifiable, Codable, Equatable {
    /// Major scuba certifying agencies offered in the Agency picker.
    /// Anything else the diver types under "Other" is stored as-is in
    /// `agency`.
    static let knownAgencies = [
        "ANDI", "BSAC", "CMAS", "GUE", "IANTD", "NASE", "NAUI",
        "PADI", "PSAI", "RAID", "SDI", "SNSI", "SSI", "TDI"
    ]

    let id: UUID
    var agency: String
    var courseName: String
    var certificationNumber: String
    var dateCertified: Date?
    var instructorOrFacility: String
    /// Most recreational certs don't expire, but some specialties,
    /// professional levels, and things like Nitrox refreshers do -- left
    /// optional/blank for certs that never expire.
    var expirationDate: Date?
    var notes: String
    /// Filename of a saved photo of the physical cert card, stored on disk
    /// via PhotoStorage (see PhotoStorage.swift) rather than embedded in
    /// this struct -- keeps the image out of the JSON blob AppStore
    /// persists to UserDefaults/iCloud Key-Value storage. Optional so
    /// existing saved certifications (no photo) decode without a custom
    /// decoder.
    var cardImageFilename: String?

    /// Filename of an uploaded PDF copy of the certification (a scanned
    /// card, e-card, or completion certificate), stored on disk via
    /// DocumentStorage (see DocumentStorage.swift) -- same file-on-disk-by-
    /// filename pattern as `cardImageFilename` above, just for a document
    /// instead of a photo. Independent of `cardImageFilename`: a
    /// certification can have a photo, a PDF, both, or neither.
    var cardDocumentFilename: String?
    var cardDocumentUploadedAt: Date?

    init(
        id: UUID = UUID(),
        agency: String,
        courseName: String,
        certificationNumber: String = "",
        dateCertified: Date? = nil,
        instructorOrFacility: String = "",
        expirationDate: Date? = nil,
        notes: String = "",
        cardImageFilename: String? = nil,
        cardDocumentFilename: String? = nil,
        cardDocumentUploadedAt: Date? = nil
    ) {
        self.id = id
        self.agency = agency
        self.courseName = courseName
        self.certificationNumber = certificationNumber
        self.dateCertified = dateCertified
        self.instructorOrFacility = instructorOrFacility
        self.expirationDate = expirationDate
        self.notes = notes
        self.cardImageFilename = cardImageFilename
        self.cardDocumentFilename = cardDocumentFilename
        self.cardDocumentUploadedAt = cardDocumentUploadedAt
    }

    /// True once `expirationDate` has passed. Certs with no expiration date
    /// are never expired.
    var isExpired: Bool {
        guard let expirationDate else { return false }
        return expirationDate < Date()
    }

    /// True when `expirationDate` falls within the next 60 days -- mirrors
    /// the "due soon" window used for Equipment Locker service dates.
    var isExpiringSoon: Bool {
        guard let expirationDate, !isExpired else { return false }
        let sixtyDaysFromNow = Calendar.current.date(byAdding: .day, value: 60, to: Date()) ?? Date()
        return expirationDate <= sixtyDaysFromNow
    }
}
