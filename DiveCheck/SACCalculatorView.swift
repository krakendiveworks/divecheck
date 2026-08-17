import SwiftUI

/// Calculates a diver's SAC (Surface Air Consumption) rate and RMV/SCR
/// (Respiratory Minute Volume / Surface Consumption Rate) from a single
/// dive's tank capacity, service pressure, max depth, average depth, total
/// dive time, and gas used. All inputs are entered via scrolling number
/// wheels.
///
/// SAC rate is expressed in psi/min and is specific to the tank used.
/// RMV/SCR is expressed in cu ft/min and is tank-independent, normalized to
/// the surface, which makes it the better metric for comparing consumption
/// across dives on different cylinders.
struct SACCalculatorView: View {
    @State private var tankCapacityCuFt: Int = 80
    @State private var servicePressurePsi: Int = 3000
    @State private var maxDepthFt: Int = 80
    @State private var averageDepthFt: Int = 60
    @State private var totalTimeMin: Int = 40
    @State private var gasUsedPsi: Int = 1500

    private static let tankCapacityRange = Array(6...200)
    private static let servicePressureRange = Array(stride(from: 2000, through: 3500, by: 50))
    private static let depthRange = Array(1...300)
    private static let timeRange = Array(1...180)
    private static let gasUsedRange = Array(stride(from: 0, through: 3600, by: 50))

    /// Atmospheres absolute at max depth (33 ft of seawater per atmosphere).
    private var maxDepthATA: Double {
        Double(maxDepthFt) / 33.0 + 1.0
    }

    /// Atmospheres absolute at average depth.
    private var averageDepthATA: Double {
        Double(averageDepthFt) / 33.0 + 1.0
    }

    /// Cubic feet of gas per psi of tank pressure.
    private var tankFactor: Double {
        guard servicePressurePsi > 0 else { return 0 }
        return Double(tankCapacityCuFt) / Double(servicePressurePsi)
    }

    private var gasUsedCuFt: Double {
        Double(gasUsedPsi) * tankFactor
    }

    /// psi/min, normalized to the surface. Tank-specific. Uses average
    /// depth, not max depth, since that's what actually reflects gas
    /// consumption over the whole dive.
    private var sacRate: Double {
        guard totalTimeMin > 0, averageDepthATA > 0 else { return 0 }
        return (Double(gasUsedPsi) / Double(totalTimeMin)) / averageDepthATA
    }

    /// cu ft/min, normalized to the surface. Tank-independent.
    private var rmvRate: Double {
        sacRate * tankFactor
    }

    var body: some View {
        Form {
            Section("Tank") {
                NumberWheel(label: "Tank Capacity (cu ft)", selection: $tankCapacityCuFt, values: Self.tankCapacityRange)
                NumberWheel(label: "Service Pressure (psi)", selection: $servicePressurePsi, values: Self.servicePressureRange)
            }

            Section("Dive") {
                NumberWheel(label: "Max Depth (ft)", selection: $maxDepthFt, values: Self.depthRange)
                NumberWheel(label: "Average Depth (ft)", selection: $averageDepthFt, values: Self.depthRange)
                NumberWheel(label: "Total Dive Time (min)", selection: $totalTimeMin, values: Self.timeRange)
                NumberWheel(label: "Gas Used (psi)", selection: $gasUsedPsi, values: Self.gasUsedRange)
            }

            Section("Results") {
                ResultRow(label: "SAC Rate", value: sacRate, unit: "psi/min")
                ResultRow(label: "RMV / SCR", value: rmvRate, unit: "cu ft/min")
                HStack {
                    Text("Gas Used")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f cu ft", gasUsedCuFt))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                HStack {
                    Text("Max Depth ATA")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.2f ata", maxDepthATA))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                HStack {
                    Text("Average Depth ATA")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.2f ata", averageDepthATA))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
        .navigationTitle("SAC / RMV Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SACCalculatorView()
    }
}
