import Foundation
import UIKit

/// Renders a DiverMedicalID to a simple, printable PDF -- meant to be kept
/// in a dry bag, handed to a boat crew, or shown to EMS if the diver
/// themselves is the one who's hurt and can't speak for themselves. Same
/// plain UIKit text-drawing approach as EAPPDFRenderer.swift.
enum DiverMedicalIDPDFRenderer {
    /// Writes the rendered PDF to a temp file and returns its URL, or nil if
    /// rendering/writing fails.
    static func renderPDF(card: DiverMedicalID) -> URL? {
        let pageWidth: CGFloat = 612 // US Letter at 72 dpi
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 48
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        let displayName = card.fullName.isEmpty ? "Diver Medical ID" : card.fullName

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

            draw("Diver Medical ID", font: titleFont, spacingAfter: 2)
            draw(displayName, font: subtitleFont, color: .darkGray, spacingAfter: 10)
            drawRule()

            draw("IDENTITY", font: headerFont)
            if let dateOfBirth = card.dateOfBirth {
                draw("Date of Birth: \(dateOfBirth.formatted(date: .abbreviated, time: .omitted))", font: bodyFont)
            }
            if !card.bloodType.isEmpty { draw("Blood Type: \(card.bloodType)", font: bodyFont) }
            y += 4

            draw("MEDICAL", font: headerFont)
            draw("Allergies: \(card.allergies.isEmpty ? "None on file" : card.allergies)", font: bodyFont)
            draw("Medications: \(card.medications.isEmpty ? "None on file" : card.medications)", font: bodyFont)
            draw("Medical Conditions: \(card.medicalConditions.isEmpty ? "None on file" : card.medicalConditions)", font: bodyFont, spacingAfter: 10)

            draw("EMERGENCY CONTACT", font: headerFont)
            if !card.emergencyContactName.isEmpty { draw(card.emergencyContactName, font: bodyFont) }
            if !card.emergencyContactRelationship.isEmpty { draw(card.emergencyContactRelationship, font: bodyFont) }
            if !card.emergencyContactPhone.isEmpty { draw("Phone: \(card.emergencyContactPhone)", font: bodyFont) }
            y += 4

            draw("PHYSICIAN", font: headerFont)
            if !card.physicianName.isEmpty { draw(card.physicianName, font: bodyFont) }
            if !card.physicianPhone.isEmpty { draw("Phone: \(card.physicianPhone)", font: bodyFont) }
            y += 4

            draw("DAN MEMBERSHIP", font: headerFont)
            draw(card.danMembershipNumber.isEmpty ? "Not on file" : card.danMembershipNumber, font: bodyFont)
            draw("DAN Emergency Hotline: \(EmergencyActionPlan.danEmergencyHotline)", font: bodyFont, spacingAfter: 10)

            if !card.additionalNotes.isEmpty {
                draw("ADDITIONAL NOTES", font: headerFont)
                draw(card.additionalNotes, font: bodyFont, spacingAfter: 10)
            }
        }

        let sanitizedName = displayName.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Diver Medical ID - \(sanitizedName).pdf")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
