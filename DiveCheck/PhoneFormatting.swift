import Foundation

/// Formats phone numbers as-you-type ("(555) 123-4567") and builds the
/// `tel:` links used to actually call them. Used by the Emergency Action
/// Plan screen's phone fields (Local Emergency Number, Nearest Hospital
/// Phone).
enum PhoneFormatting {
    /// Reformats raw input into "(XXX) XXX-XXXX" style as digits accumulate.
    /// Short numbers (6 digits or fewer -- "911", "999", "112", etc.) are
    /// left exactly as typed rather than forced into a shape that doesn't
    /// fit them; an optional leading "+" or an 11th+ leading digit is kept
    /// in front as a country/trunk code.
    static func format(_ raw: String) -> String {
        let hasLeadingPlus = raw.trimmingCharacters(in: .whitespaces).hasPrefix("+")
        let digits = raw.filter { $0.isNumber }
        guard !digits.isEmpty else { return hasLeadingPlus ? "+" : "" }
        guard digits.count > 6 else { return digits }

        if digits.count > 10 {
            let main = String(digits.suffix(10))
            let leading = String(digits.dropLast(10))
            return "\(hasLeadingPlus ? "+" : "")\(leading) \(formatUpToTen(main))"
        }
        return "\(hasLeadingPlus ? "+" : "")\(formatUpToTen(digits))"
    }

    /// Progressively formats 7-10 digits as "(XXX) XXX-XXXX", showing only
    /// as much of the mask as there are digits typed for.
    private static func formatUpToTen(_ digits: String) -> String {
        let area = digits.prefix(3)
        let middle = digits.dropFirst(3).prefix(3)
        let line = digits.dropFirst(6)
        if digits.count > 6 {
            return "(\(area)) \(middle)-\(line)"
        } else if digits.count > 3 {
            return "(\(area)) \(middle)"
        } else {
            return "(\(area)"
        }
    }

    /// A `tel:` URL for the given number, or nil if there's nothing to dial.
    static func telURL(_ raw: String) -> URL? {
        let digits = raw.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }
}
