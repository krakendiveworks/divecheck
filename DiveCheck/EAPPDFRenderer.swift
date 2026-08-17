import Foundation
import UIKit

/// Renders an EmergencyActionPlan to a simple, printable PDF -- meant to be
/// posted on a boat, handed to a divemaster, or kept in a dry bag, not just
/// viewed on-screen. Plain UIKit text drawing via UIGraphicsPDFRenderer
/// since the layout is simple -- no need for an HTML/PDFKit round-trip.
enum EAPPDFRenderer {
    /// Writes the rendered PDF to a temp file and returns its URL, or nil if
    /// rendering/writing fails.
    static func renderPDF(plan: EmergencyActionPlan, locationName: String) -> URL? {
        let pageWidth: CGFloat = 612 // US Letter at 72 dpi
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 48
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        let displayName = locationName.isEmpty ? "Location" : locationName

        let data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin

            func draw(_ text: String, font: UIFont, color: UIColor = .black, spacingAfter: CGFloat = 6) {
                guard !text.isEmpty else { return }
                let attributed = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
                let bounding = attributed.boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin,
                    context: nil
                )
                if y + bounding.height > pageHeight - margin {
                    context.beginPage()
                    y = margin
                }
                attributed.draw(with: CGRect(x: margin, y: y, width: contentWidth, height: bounding.height), options: .usesLineFragmentOrigin, context: nil)
                y += bounding.height + spacingAfter
            }

            func drawRule() {
                y += 4
                let path = UIBezierPath()
                path.move(to: CGPoint(x: margin, y: y))
                path.addLine(to: CGPoint(x: pageWidth - margin, y: y))
                UIColor.lightGray.setStroke()
                path.lineWidth = 0.5
                path.stroke()
                y += 10
            }

            let titleFont = UIFont.boldSystemFont(ofSize: 20)
            let subtitleFont = UIFont.systemFont(ofSize: 14)
            let headerFont = UIFont.boldSystemFont(ofSize: 13)
            let bodyFont = UIFont.systemFont(ofSize: 11)

            draw("Emergency Action Plan", font: titleFont, spacingAfter: 2)
            draw(displayName, font: subtitleFont, color: .darkGray, spacingAfter: 10)
            drawRule()

            func availability(_ isAvailable: Bool) -> String {
                isAvailable ? "Available" : "Not confirmed available"
            }

            draw("LOCAL EMERGENCY SERVICES", font: headerFont)
            draw("Call first: \(plan.localEmergencyNumber)", font: bodyFont)
            draw("Then call DAN for a consultation with the treating physician.", font: bodyFont, spacingAfter: 10)

            draw("DAN EMERGENCY HOTLINE", font: headerFont)
            draw(EmergencyActionPlan.danEmergencyHotline, font: bodyFont, spacingAfter: 10)

            draw("NEAREST HOSPITAL", font: headerFont)
            draw(plan.nearestHospitalName, font: bodyFont)
            draw(plan.nearestHospitalAddress, font: bodyFont)
            if !plan.nearestHospitalPhone.isEmpty { draw("Phone: \(plan.nearestHospitalPhone)", font: bodyFont) }
            y += 4

            if !plan.alternateMedicalFacilityName.isEmpty || !plan.alternateMedicalFacilityAddress.isEmpty || !plan.alternateMedicalFacilityPhone.isEmpty {
                draw("ALTERNATE MEDICAL FACILITY", font: headerFont)
                draw(plan.alternateMedicalFacilityName, font: bodyFont)
                draw(plan.alternateMedicalFacilityAddress, font: bodyFont)
                if !plan.alternateMedicalFacilityPhone.isEmpty { draw("Phone: \(plan.alternateMedicalFacilityPhone)", font: bodyFont) }
                y += 4
            }

            if !plan.locationInfoAddress.isEmpty || !plan.locationInfoAccessNotes.isEmpty {
                draw("DIVE SITE LOCATION INFORMATION (read to EMS)", font: headerFont)
                if !plan.locationInfoAddress.isEmpty { draw(plan.locationInfoAddress, font: bodyFont) }
                if !plan.locationInfoAccessNotes.isEmpty { draw(plan.locationInfoAccessNotes, font: bodyFont) }
                y += 4
            }

            draw("ON-SITE EMERGENCY EQUIPMENT", font: headerFont)
            draw("Emergency Oxygen: \(availability(plan.emergencyOxygenAvailable))\(plan.emergencyOxygenLocation.isEmpty ? "" : " -- \(plan.emergencyOxygenLocation)")", font: bodyFont)
            draw("AED: \(availability(plan.aedAvailable))\(plan.aedLocation.isEmpty ? "" : " -- \(plan.aedLocation)")", font: bodyFont)
            draw("First Aid Kit: \(availability(plan.firstAidKitAvailable))\(plan.firstAidKitLocation.isEmpty ? "" : " -- \(plan.firstAidKitLocation)")", font: bodyFont, spacingAfter: 10)

            let hasRoleInfo = !plan.emsCallerName.isEmpty || !plan.emsCallerPhone.isEmpty
                || !plan.firstAidProviderName.isEmpty || !plan.firstAidProviderPhone.isEmpty
                || !plan.accountabilityManagerName.isEmpty || !plan.accountabilityManagerPhone.isEmpty
                || !plan.assignedRoles.isEmpty
            if hasRoleInfo {
                draw("RESPONSE PLAN", font: headerFont)
                if !plan.emsCallerName.isEmpty || !plan.emsCallerPhone.isEmpty {
                    draw("Calls EMS: \(plan.emsCallerName)\(plan.emsCallerPhone.isEmpty ? "" : " -- \(plan.emsCallerPhone)")", font: bodyFont)
                }
                if !plan.firstAidProviderName.isEmpty || !plan.firstAidProviderPhone.isEmpty {
                    draw("Administers O2 / First Aid: \(plan.firstAidProviderName)\(plan.firstAidProviderPhone.isEmpty ? "" : " -- \(plan.firstAidProviderPhone)")", font: bodyFont)
                }
                if !plan.accountabilityManagerName.isEmpty || !plan.accountabilityManagerPhone.isEmpty {
                    draw("Manages Bystanders/Accountability: \(plan.accountabilityManagerName)\(plan.accountabilityManagerPhone.isEmpty ? "" : " -- \(plan.accountabilityManagerPhone)")", font: bodyFont)
                }
                if !plan.assignedRoles.isEmpty { draw("Additional Roles/Notes: \(plan.assignedRoles)", font: bodyFont) }
                y += 4
            }

            let hasCommunicationInfo = !plan.landCommunicationNotes.isEmpty || !plan.landlineLocation.isEmpty
                || !plan.vhfChannel.isEmpty || !plan.boatCallSign.isEmpty || !plan.marinaContact.isEmpty
                || !plan.boatCommunicationNotes.isEmpty || !plan.communicationNotes.isEmpty
            if hasCommunicationInfo {
                draw("COMMUNICATION CHANNELS (\(plan.diveAccessType.rawValue))", font: headerFont)
                if plan.diveAccessType == .land {
                    if !plan.landCommunicationNotes.isEmpty { draw("Cell Signal Notes: \(plan.landCommunicationNotes)", font: bodyFont) }
                    if !plan.landlineLocation.isEmpty { draw("Nearest Landline / Payphone: \(plan.landlineLocation)", font: bodyFont) }
                } else {
                    if !plan.vhfChannel.isEmpty { draw("VHF Channel: \(plan.vhfChannel)", font: bodyFont) }
                    if !plan.boatCallSign.isEmpty { draw("Boat Call Sign: \(plan.boatCallSign)", font: bodyFont) }
                    if !plan.marinaContact.isEmpty { draw("Marina / Harbor Master: \(plan.marinaContact)", font: bodyFont) }
                    if !plan.boatCommunicationNotes.isEmpty { draw("Additional Boat Notes: \(plan.boatCommunicationNotes)", font: bodyFont) }
                }
                if !plan.communicationNotes.isEmpty { draw(plan.communicationNotes, font: bodyFont) }
                y += 4
            }

            draw("LOCAL LAW ENFORCEMENT", font: headerFont)
            draw("Phone: \(plan.lawEnforcementPhone)", font: bodyFont)
            if !plan.lawEnforcementNotes.isEmpty { draw(plan.lawEnforcementNotes, font: bodyFont) }
            y += 4

            if !plan.primaryTransportName.isEmpty || !plan.primaryTransportPhone.isEmpty
                || !plan.secondaryTransportName.isEmpty || !plan.secondaryTransportPhone.isEmpty {
                draw("LOCAL TRANSPORTATION", font: headerFont)
                if !plan.primaryTransportName.isEmpty || !plan.primaryTransportPhone.isEmpty {
                    draw("Primary: \(plan.primaryTransportName)\(plan.primaryTransportPhone.isEmpty ? "" : " -- \(plan.primaryTransportPhone)")", font: bodyFont)
                }
                if !plan.secondaryTransportName.isEmpty || !plan.secondaryTransportPhone.isEmpty {
                    draw("Secondary: \(plan.secondaryTransportName)\(plan.secondaryTransportPhone.isEmpty ? "" : " -- \(plan.secondaryTransportPhone)")", font: bodyFont)
                }
                y += 4
            }

            if !plan.additionalNotes.isEmpty {
                draw("ADDITIONAL NOTES", font: headerFont)
                draw(plan.additionalNotes, font: bodyFont, spacingAfter: 10)
            }

            let reviewText: String
            if let lastReviewedAt = plan.lastReviewedAt {
                reviewText = "Last reviewed \(lastReviewedAt.formatted(date: .abbreviated, time: .omitted))"
            } else {
                reviewText = "Not reviewed yet"
            }
            draw(reviewText, font: UIFont.italicSystemFont(ofSize: 9), color: .gray)
        }

        let sanitizedName = displayName.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("EAP - \(sanitizedName).pdf")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
