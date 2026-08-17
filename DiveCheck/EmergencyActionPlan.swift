import Foundation

/// Which way a diver gets to this Location -- determines which set of
/// Communication Channels fields is relevant (VHF/call sign/marina for a
/// boat, cell signal/landline for shore access). A Location used for both
/// over time can just be switched and both sets of fields stay saved
/// either way -- switching only changes which fields are shown, not what's
/// stored.
enum DiveAccessType: String, Codable, CaseIterable, Identifiable {
    case land = "Land-Based"
    case boat = "Boat-Based"

    var id: String { rawValue }
}

/// An Emergency Action Plan (EAP) for a specific dive Location -- the
/// information a diver, buddy, or bystander needs on hand to respond to a
/// diving emergency at that spot, modeled on Divers Alert Network's (DAN)
/// published EAP guidance: how to activate EMS, where emergency equipment
/// is and how to use it, and who does what when something goes wrong.
/// See https://dan.org/safety-prevention/diver-safety/divers-blog/how-to-create-an-effective-emergency-action-plan-eap/
///
/// There's intentionally no "nearest recompression chamber" field: chambers
/// aren't always staffed or available for a given case, so the plan always
/// routes through EMS first, then DAN (see `danEmergencyHotline` below) --
/// DAN and the treating physician are the ones who decide where a diver
/// actually needs to go, not the plan itself.
struct EmergencyActionPlan: Identifiable, Codable, Equatable {
    let id: UUID
    /// The Location (SavedLocation) this plan is for. One plan per Location.
    var locationID: UUID

    // MARK: Activate EMS
    /// Local emergency services number -- "911" in the US/Canada, but this
    /// varies by country, so it's editable rather than hardcoded.
    var localEmergencyNumber: String
    var nearestHospitalName: String
    var nearestHospitalAddress: String
    var nearestHospitalPhone: String
    var nearestHospitalDirections: String

    // MARK: Alternate medical facility
    /// A second option -- an urgent care, clinic, or backup hospital --
    /// for when the nearest hospital above is unreachable, on diversion,
    /// or not the right fit for the situation. Same fields as Nearest
    /// Hospital, kept as a fully separate entry rather than a "backup"
    /// flag on one shared facility, since which one is actually closer or
    /// more appropriate can depend on the specific emergency.
    var alternateMedicalFacilityName: String
    var alternateMedicalFacilityAddress: String
    var alternateMedicalFacilityPhone: String
    var alternateMedicalFacilityDirections: String

    // MARK: Location information for EMS
    /// What a bystander calling EMS should actually read off to the
    /// dispatcher -- the address/GPS coordinates and any access details a
    /// street address alone wouldn't capture (cross streets, landmarks,
    /// gate codes, dock/slip numbers, parking).
    var locationInfoAddress: String
    var locationInfoAccessNotes: String

    // MARK: Emergency equipment on hand
    var emergencyOxygenAvailable: Bool
    var emergencyOxygenLocation: String
    var aedAvailable: Bool
    var aedLocation: String
    var firstAidKitAvailable: Bool
    var firstAidKitLocation: String

    // MARK: Response plan
    /// DAN's guidance is to assign these roles ahead of time, not in the
    /// moment: who calls EMS, who administers oxygen/first aid, and who
    /// manages bystanders and accounts for the other divers still in the
    /// water. Each gets a name/organization and a phone number rather than
    /// being one big free-text field.
    var emsCallerName: String
    var emsCallerPhone: String
    var firstAidProviderName: String
    var firstAidProviderPhone: String
    var accountabilityManagerName: String
    var accountabilityManagerPhone: String
    /// Anything else worth noting about roles that doesn't fit the three
    /// above -- was originally the single free-text "Assigned Roles" field
    /// before this became specific role/name/phone rows, so it's kept
    /// (just relabeled) rather than migrated, to avoid losing anyone's
    /// existing notes.
    var assignedRoles: String

    // MARK: Communication Channels
    /// Which set of fields below is currently shown -- doesn't affect what's
    /// stored, just which half of the form is visible (see DiveAccessType).
    var diveAccessType: DiveAccessType
    /// Land-based access fields.
    var landCommunicationNotes: String
    var landlineLocation: String
    /// Boat-based access fields.
    var vhfChannel: String
    var boatCallSign: String
    var marinaContact: String
    var boatCommunicationNotes: String
    /// Catch-all for anything communication-related that doesn't fit the
    /// land/boat split above, shown regardless of DiveAccessType. Was
    /// originally the single free-text "Communications" field, kept (just
    /// relabeled) for the same reason as `assignedRoles`.
    var communicationNotes: String

    // MARK: Local law enforcement
    /// Defaults to "911" like the main Local Emergency Services number --
    /// EMS dispatch usually routes police out too, but some situations
    /// (securing a scene, a missing diver search) call for reaching law
    /// enforcement directly or separately.
    var lawEnforcementPhone: String
    var lawEnforcementNotes: String

    // MARK: Local transportation
    /// A non-ambulance way to move people -- getting an uninjured buddy to
    /// the hospital to meet the injured diver, sending someone for
    /// supplies, etc. Two slots (e.g. a local taxi company and a
    /// rideshare's dispatch/support line) rather than an open-ended list.
    var primaryTransportName: String
    var primaryTransportPhone: String
    var secondaryTransportName: String
    var secondaryTransportPhone: String

    var additionalNotes: String

    /// DAN recommends reviewing/practicing the plan periodically, since
    /// facilities close, numbers change, and supplies expire.
    var lastReviewedAt: Date?

    /// DAN's 24/7 emergency medical hotline. Constant and always shown --
    /// per DAN's own guidance, call local EMS first, then DAN.
    static let danEmergencyHotline = "+1-919-684-9111"

    init(
        id: UUID = UUID(),
        locationID: UUID,
        localEmergencyNumber: String = "911",
        nearestHospitalName: String = "",
        nearestHospitalAddress: String = "",
        nearestHospitalPhone: String = "",
        nearestHospitalDirections: String = "",
        alternateMedicalFacilityName: String = "",
        alternateMedicalFacilityAddress: String = "",
        alternateMedicalFacilityPhone: String = "",
        alternateMedicalFacilityDirections: String = "",
        locationInfoAddress: String = "",
        locationInfoAccessNotes: String = "",
        emergencyOxygenAvailable: Bool = false,
        emergencyOxygenLocation: String = "",
        aedAvailable: Bool = false,
        aedLocation: String = "",
        firstAidKitAvailable: Bool = false,
        firstAidKitLocation: String = "",
        emsCallerName: String = "",
        emsCallerPhone: String = "",
        firstAidProviderName: String = "",
        firstAidProviderPhone: String = "",
        accountabilityManagerName: String = "",
        accountabilityManagerPhone: String = "",
        assignedRoles: String = "",
        diveAccessType: DiveAccessType = .land,
        landCommunicationNotes: String = "",
        landlineLocation: String = "",
        vhfChannel: String = "",
        boatCallSign: String = "",
        marinaContact: String = "",
        boatCommunicationNotes: String = "",
        communicationNotes: String = "",
        lawEnforcementPhone: String = "911",
        lawEnforcementNotes: String = "",
        primaryTransportName: String = "",
        primaryTransportPhone: String = "",
        secondaryTransportName: String = "",
        secondaryTransportPhone: String = "",
        additionalNotes: String = "",
        lastReviewedAt: Date? = nil
    ) {
        self.id = id
        self.locationID = locationID
        self.localEmergencyNumber = localEmergencyNumber
        self.nearestHospitalName = nearestHospitalName
        self.nearestHospitalAddress = nearestHospitalAddress
        self.nearestHospitalPhone = nearestHospitalPhone
        self.nearestHospitalDirections = nearestHospitalDirections
        self.alternateMedicalFacilityName = alternateMedicalFacilityName
        self.alternateMedicalFacilityAddress = alternateMedicalFacilityAddress
        self.alternateMedicalFacilityPhone = alternateMedicalFacilityPhone
        self.alternateMedicalFacilityDirections = alternateMedicalFacilityDirections
        self.locationInfoAddress = locationInfoAddress
        self.locationInfoAccessNotes = locationInfoAccessNotes
        self.emergencyOxygenAvailable = emergencyOxygenAvailable
        self.emergencyOxygenLocation = emergencyOxygenLocation
        self.aedAvailable = aedAvailable
        self.aedLocation = aedLocation
        self.firstAidKitAvailable = firstAidKitAvailable
        self.firstAidKitLocation = firstAidKitLocation
        self.emsCallerName = emsCallerName
        self.emsCallerPhone = emsCallerPhone
        self.firstAidProviderName = firstAidProviderName
        self.firstAidProviderPhone = firstAidProviderPhone
        self.accountabilityManagerName = accountabilityManagerName
        self.accountabilityManagerPhone = accountabilityManagerPhone
        self.assignedRoles = assignedRoles
        self.diveAccessType = diveAccessType
        self.landCommunicationNotes = landCommunicationNotes
        self.landlineLocation = landlineLocation
        self.vhfChannel = vhfChannel
        self.boatCallSign = boatCallSign
        self.marinaContact = marinaContact
        self.boatCommunicationNotes = boatCommunicationNotes
        self.communicationNotes = communicationNotes
        self.lawEnforcementPhone = lawEnforcementPhone
        self.lawEnforcementNotes = lawEnforcementNotes
        self.primaryTransportName = primaryTransportName
        self.primaryTransportPhone = primaryTransportPhone
        self.secondaryTransportName = secondaryTransportName
        self.secondaryTransportPhone = secondaryTransportPhone
        self.additionalNotes = additionalNotes
        self.lastReviewedAt = lastReviewedAt
    }

    // Custom Codable so plans saved before this round of changes still
    // decode instead of failing to load -- every field is decoded
    // leniently with a fallback. This has been true since the very first
    // version of this model (see the removed nearestHyperbaricChamber*
    // fields, gone before any of the fields below existed) and stays true
    // here: every new field added in this pass is decoded with
    // `decodeIfPresent(...) ?? default` so older saved plans (missing
    // these keys entirely) decode cleanly with sensible defaults instead
    // of failing.
    private enum CodingKeys: String, CodingKey {
        case id, locationID, localEmergencyNumber
        case nearestHospitalName, nearestHospitalAddress, nearestHospitalPhone, nearestHospitalDirections
        case alternateMedicalFacilityName, alternateMedicalFacilityAddress, alternateMedicalFacilityPhone, alternateMedicalFacilityDirections
        case locationInfoAddress, locationInfoAccessNotes
        case emergencyOxygenAvailable, emergencyOxygenLocation
        case aedAvailable, aedLocation
        case firstAidKitAvailable, firstAidKitLocation
        case emsCallerName, emsCallerPhone
        case firstAidProviderName, firstAidProviderPhone
        case accountabilityManagerName, accountabilityManagerPhone
        case assignedRoles
        case diveAccessType
        case landCommunicationNotes, landlineLocation
        case vhfChannel, boatCallSign, marinaContact, boatCommunicationNotes
        case communicationNotes
        case lawEnforcementPhone, lawEnforcementNotes
        case primaryTransportName, primaryTransportPhone, secondaryTransportName, secondaryTransportPhone
        case additionalNotes, lastReviewedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        locationID = try container.decode(UUID.self, forKey: .locationID)
        localEmergencyNumber = try container.decodeIfPresent(String.self, forKey: .localEmergencyNumber) ?? "911"
        nearestHospitalName = try container.decodeIfPresent(String.self, forKey: .nearestHospitalName) ?? ""
        nearestHospitalAddress = try container.decodeIfPresent(String.self, forKey: .nearestHospitalAddress) ?? ""
        nearestHospitalPhone = try container.decodeIfPresent(String.self, forKey: .nearestHospitalPhone) ?? ""
        nearestHospitalDirections = try container.decodeIfPresent(String.self, forKey: .nearestHospitalDirections) ?? ""
        alternateMedicalFacilityName = try container.decodeIfPresent(String.self, forKey: .alternateMedicalFacilityName) ?? ""
        alternateMedicalFacilityAddress = try container.decodeIfPresent(String.self, forKey: .alternateMedicalFacilityAddress) ?? ""
        alternateMedicalFacilityPhone = try container.decodeIfPresent(String.self, forKey: .alternateMedicalFacilityPhone) ?? ""
        alternateMedicalFacilityDirections = try container.decodeIfPresent(String.self, forKey: .alternateMedicalFacilityDirections) ?? ""
        locationInfoAddress = try container.decodeIfPresent(String.self, forKey: .locationInfoAddress) ?? ""
        locationInfoAccessNotes = try container.decodeIfPresent(String.self, forKey: .locationInfoAccessNotes) ?? ""
        emergencyOxygenAvailable = try container.decodeIfPresent(Bool.self, forKey: .emergencyOxygenAvailable) ?? false
        emergencyOxygenLocation = try container.decodeIfPresent(String.self, forKey: .emergencyOxygenLocation) ?? ""
        aedAvailable = try container.decodeIfPresent(Bool.self, forKey: .aedAvailable) ?? false
        aedLocation = try container.decodeIfPresent(String.self, forKey: .aedLocation) ?? ""
        firstAidKitAvailable = try container.decodeIfPresent(Bool.self, forKey: .firstAidKitAvailable) ?? false
        firstAidKitLocation = try container.decodeIfPresent(String.self, forKey: .firstAidKitLocation) ?? ""
        emsCallerName = try container.decodeIfPresent(String.self, forKey: .emsCallerName) ?? ""
        emsCallerPhone = try container.decodeIfPresent(String.self, forKey: .emsCallerPhone) ?? ""
        firstAidProviderName = try container.decodeIfPresent(String.self, forKey: .firstAidProviderName) ?? ""
        firstAidProviderPhone = try container.decodeIfPresent(String.self, forKey: .firstAidProviderPhone) ?? ""
        accountabilityManagerName = try container.decodeIfPresent(String.self, forKey: .accountabilityManagerName) ?? ""
        accountabilityManagerPhone = try container.decodeIfPresent(String.self, forKey: .accountabilityManagerPhone) ?? ""
        assignedRoles = try container.decodeIfPresent(String.self, forKey: .assignedRoles) ?? ""
        diveAccessType = try container.decodeIfPresent(DiveAccessType.self, forKey: .diveAccessType) ?? .land
        landCommunicationNotes = try container.decodeIfPresent(String.self, forKey: .landCommunicationNotes) ?? ""
        landlineLocation = try container.decodeIfPresent(String.self, forKey: .landlineLocation) ?? ""
        vhfChannel = try container.decodeIfPresent(String.self, forKey: .vhfChannel) ?? ""
        boatCallSign = try container.decodeIfPresent(String.self, forKey: .boatCallSign) ?? ""
        marinaContact = try container.decodeIfPresent(String.self, forKey: .marinaContact) ?? ""
        boatCommunicationNotes = try container.decodeIfPresent(String.self, forKey: .boatCommunicationNotes) ?? ""
        communicationNotes = try container.decodeIfPresent(String.self, forKey: .communicationNotes) ?? ""
        lawEnforcementPhone = try container.decodeIfPresent(String.self, forKey: .lawEnforcementPhone) ?? "911"
        lawEnforcementNotes = try container.decodeIfPresent(String.self, forKey: .lawEnforcementNotes) ?? ""
        primaryTransportName = try container.decodeIfPresent(String.self, forKey: .primaryTransportName) ?? ""
        primaryTransportPhone = try container.decodeIfPresent(String.self, forKey: .primaryTransportPhone) ?? ""
        secondaryTransportName = try container.decodeIfPresent(String.self, forKey: .secondaryTransportName) ?? ""
        secondaryTransportPhone = try container.decodeIfPresent(String.self, forKey: .secondaryTransportPhone) ?? ""
        additionalNotes = try container.decodeIfPresent(String.self, forKey: .additionalNotes) ?? ""
        lastReviewedAt = try container.decodeIfPresent(Date.self, forKey: .lastReviewedAt)
    }
}
