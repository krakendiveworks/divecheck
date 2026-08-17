import SwiftUI

/// Calculates Minimum Gas (a.k.a. "Rock Bottom") -- the gas reserve needed
/// for a set number of divers sharing one gas supply to solve a problem at
/// depth and make a controlled ascent (with a safety stop) back to the
/// surface, using a stressed breathing rate rather than a resting one.
/// Standard technical-diving gas-planning material (GUE/UTD-style), not a
/// decompression calculation.
///
/// For each phase (problem-solving at depth, ascent to the safety stop, the
/// stop itself, and the stop to the surface), gas used = RMV * ATA * time,
/// using the average ATA across a phase where depth changes during it. The
/// total across all phases is multiplied by the number of divers sharing
/// the gas supply, then converted to a tank pressure.
struct MinimumGasCalculatorView: View {
    @State private var depthFt: Int = 100
    @State private var rmvTenths: Int = 10 // 1.0 cu ft/min -- stressed rate
    @State private var problemTimeMin: Int = 1
    @State private var ascentRateFtPerMin: Int = 30
    @State private var safetyStopTimeMin: Int = 3
    @State private var numberOfDivers: Int = 2
    @State private var tankCapacityCuFt: Int = 80
    @State private var servicePressurePsi: Int = 3000

    private static let depthRange = Array(0...300)
    private static let rmvTenthsRange = Array(1...30) // 0.1 ... 3.0 cu ft/min
    private static let problemTimeRange = Array(0...5)
    private static let ascentRateOptions = [10, 15, 20, 30, 40, 60]
    private static let safetyStopTimeRange = Array(0...10)
    private static let diverRange = Array(1...4)
    private static let tankCapacityRange = Array(6...200)
    private static let pressureRange = Array(stride(from: 0, through: 3500, by: 50))

    private static let safetyStopDepthFt = 15

    private var rmv: Double {
        Double(rmvTenths) / 10.0
    }

    private func ata(forDepth depth: Double) -> Double {
        depth / 33.0 + 1.0
    }

    /// Total gas used across all phases, in cubic feet, for one diver.
    private var perDiverGasCuFt: Double {
        let effectiveStopDepth = min(depthFt, Self.safetyStopDepthFt)
        let ataBottom = ata(forDepth: Double(depthFt))
        let ataStop = ata(forDepth: Double(effectiveStopDepth))
        let ataSurface = 1.0
        let ascentRate = Double(max(1, ascentRateFtPerMin))

        let ascentTimeToStop = Double(max(0, depthFt - effectiveStopDepth)) / ascentRate
        let ascentTimeStopToSurface = Double(effectiveStopDepth) / ascentRate

        let gasProblemSolving = rmv * ataBottom * Double(problemTimeMin)
        let gasAscentToStop = rmv * ((ataBottom + ataStop) / 2) * ascentTimeToStop
        let gasAtStop = rmv * ataStop * Double(safetyStopTimeMin)
        let gasStopToSurface = rmv * ((ataStop + ataSurface) / 2) * ascentTimeStopToSurface

        return gasProblemSolving + gasAscentToStop + gasAtStop + gasStopToSurface
    }

    private var totalGasCuFt: Double {
        perDiverGasCuFt * Double(numberOfDivers)
    }

    /// Cubic feet of gas per psi of tank pressure.
    private var tankFactor: Double {
        guard servicePressurePsi > 0 else { return 0 }
        return Double(tankCapacityCuFt) / Double(servicePressurePsi)
    }

    private var minimumGasPsi: Double {
        guard tankFactor > 0 else { return 0 }
        return totalGasCuFt / tankFactor
    }

    var body: some View {
        Form {
            Section("Dive") {
                NumberWheel(label: "Depth (ft)", selection: $depthFt, values: Self.depthRange)
                NumberWheel(
                    label: "Stressed RMV (cu ft/min)",
                    selection: $rmvTenths,
                    values: Self.rmvTenthsRange,
                    format: { String(format: "%.1f", Double($0) / 10.0) }
                )
                NumberWheel(label: "Problem-Solving Time (min)", selection: $problemTimeMin, values: Self.problemTimeRange)
                NumberWheel(label: "Ascent Rate (ft/min)", selection: $ascentRateFtPerMin, values: Self.ascentRateOptions)
                NumberWheel(label: "Safety Stop Time (min)", selection: $safetyStopTimeMin, values: Self.safetyStopTimeRange)
                NumberWheel(label: "Divers Sharing Gas", selection: $numberOfDivers, values: Self.diverRange)
            }

            Section("Tank") {
                NumberWheel(label: "Tank Capacity (cu ft)", selection: $tankCapacityCuFt, values: Self.tankCapacityRange)
                NumberWheel(label: "Service Pressure (psi)", selection: $servicePressurePsi, values: Self.pressureRange)
            }

            Section {
                ResultRow(label: "Minimum Gas", value: minimumGasPsi, unit: "psi", decimalPlaces: 0)
                HStack {
                    Text("Total Gas Volume")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f cu ft", totalGasCuFt))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            } header: {
                Text("Results")
            } footer: {
                Text("The gas reserve needed for everyone sharing this supply to solve a problem at depth and make a controlled ascent, including a safety stop at \(Self.safetyStopDepthFt) ft, using a stressed (not resting) breathing rate. This is a planning estimate -- learn Minimum Gas / Rock Bottom procedures from a qualified instructor before relying on it in the water.")
            }
        }
        .navigationTitle("Minimum Gas")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MinimumGasCalculatorView()
    }
}
