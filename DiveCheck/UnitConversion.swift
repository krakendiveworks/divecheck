import Foundation

/// Converts the numeric text fields on a DiveLogEntry when the diver
/// switches a unit picker (feet/meters, °F/°C, lbs/kg), so the displayed
/// numbers stay physically consistent instead of silently keeping the old
/// number under a new unit label. Blank or non-numeric text is left as-is
/// (nothing to convert).
enum UnitConversion {
    private static func convert(_ text: String, _ factor: (Double) -> Double) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed) else { return text }
        let converted = factor(value)
        // One decimal place keeps things readable and matches the
        // formatting already used elsewhere in the app (e.g. import
        // mapping) without implying false precision.
        return String(format: "%.1f", converted)
    }

    static func convertDepth(_ text: String, from: DepthUnit, to: DepthUnit) -> String {
        guard from != to else { return text }
        switch (from, to) {
        case (.feet, .meters):
            return convert(text) { $0 / 3.28084 }
        case (.meters, .feet):
            return convert(text) { $0 * 3.28084 }
        default:
            return text
        }
    }

    static func convertTemperature(_ text: String, from: TemperatureUnit, to: TemperatureUnit) -> String {
        guard from != to else { return text }
        switch (from, to) {
        case (.fahrenheit, .celsius):
            return convert(text) { ($0 - 32) * 5 / 9 }
        case (.celsius, .fahrenheit):
            return convert(text) { $0 * 9 / 5 + 32 }
        default:
            return text
        }
    }

    static func convertWeight(_ text: String, from: WeightUnit, to: WeightUnit) -> String {
        guard from != to else { return text }
        switch (from, to) {
        case (.lbs, .kg):
            return convert(text) { $0 / 2.20462 }
        case (.kg, .lbs):
            return convert(text) { $0 * 2.20462 }
        default:
            return text
        }
    }
}
