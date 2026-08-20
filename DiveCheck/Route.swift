import Foundation

/// Navigation destinations used by the single NavigationStack in ContentView.
enum ChecklistRoute: Hashable {
    case diveChecklists
    case category(UUID)
    case subcategory(categoryID: UUID, subcategoryID: UUID)
    case checklist(categoryID: UUID, subcategoryID: UUID?, checklistID: UUID)
    case history
    case savedChecklist(UUID)
    case equipmentLocker
    case equipmentDetail(UUID)
    case diveLog
    case diveLogDetail(UUID)
    case bluetoothDiveImport
    case garminFitImport
    case calculators
    case sacCalculator
    case modCalculator
    case ppo2Calculator
    case bestMixCalculator
    case eadCalculator
    case endCalculator
    case gasTimeCalculator
    case minimumGasCalculator
    case cnsOxygenCalculator
    case weightCheckCalculator
    case tankFillCalculator
    case locations
    case locationDetail(UUID)
    case emergencyActionPlans
    case eapDetail(UUID)
    case plan
    case dives
    case equipment
    case wallet
    case settings
    case statistics
    case maintenanceSchedule
    case serviceHistory
    case certifications
    case certificationDetail(UUID)
    case savedCertifications
    case savedCertificationDetail(UUID)
    case diverMedicalID
    case savedDiverMedicalIDs
    case savedDiverMedicalIDDetail(UUID)
    case diveSiteMap
    case diveComputers
    case diveComputerDetail(UUID)
    case training
    case trainingAgency(UUID)
    case trainingCertification(agencyID: UUID, certificationID: UUID)
    case trainingChecklist(agencyID: UUID, certificationID: UUID, checklistID: UUID)
    case studentTracking
    case studentTrackingAgency(UUID)
    case trainingRosterProgram(agencyID: UUID, programID: UUID)
    case trainingCandidateDetail(agencyID: UUID, programID: UUID, candidateID: UUID)
    case trainingCandidateChecklist(agencyID: UUID, programID: UUID, candidateID: UUID, checklistID: UUID)
}
