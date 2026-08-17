import Foundation

/// Computes SAC Rate and RMV/SCR from a Dive Log entry's tank size, service
/// pressure, start/end pressure, average depth, and duration -- same math
/// as the standalone SAC/RMV calculator (SACCalculatorView.swift),
/// generalized to accept either feet or meters. Triggered by a "Calculate"
/// button on the Dive Log entry rather than recomputed on every keystroke,
/// so it never fights with a value the diver typed in by hand.
enum SACCalculation {
    /// Returns nil if there isn't enough valid data to compute a result
    /// (missing/zero tank size or service pressure, zero duration, or a gas
    /// used that comes out to zero or negative).
    static func calculate(
        tankSizeCuFt: Double,
        servicePressurePsi: Double,
        startPressurePsi: Double,
        endPressurePsi: Double,
        averageDepth: Double,
        depthUnit: DepthUnit,
        durationMinutes: Double
    ) -> (sacRate: Double, rmvRate: Double)? {
        guard tankSizeCuFt > 0, servicePressurePsi > 0, durationMinutes > 0 else { return nil }

        let gasUsedPsi = startPressurePsi - endPressurePsi
        guard gasUsedPsi > 0 else { return nil }

        // 33 ft (10 m) of seawater per additional atmosphere.
        let depthInFeet = depthUnit == .meters ? averageDepth * 3.28084 : averageDepth
        let averageDepthATA = depthInFeet / 33.0 + 1.0
        guard averageDepthATA > 0 else { return nil }

        let tankFactor = tankSizeCuFt / servicePressurePsi
        let sacRate = (gasUsedPsi / durationMinutes) / averageDepthATA
        let rmvRate = sacRate * tankFactor
        return (sacRate, rmvRate)
    }
}
