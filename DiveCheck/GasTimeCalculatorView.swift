import SwiftUI

/// Calculates gas time remaining and a turn pressure mid-dive -- the
/// forward-looking counterpart to the SAC/RMV calculator, which works out
/// consumption after a dive is already logged. Enter your RMV (from the
/// SAC/RMV calculator or a logged dive), current depth, tank info, current
/// pressure, and a reserve, and this shows how many minutes of gas that
/// leaves and what pressure to turn the dive at.
struct GasTimeCalculatorView: View {
    @State private var rmvTenths: Int = 5 // 0.5 cu ft/min
    @State private var depthFt: Int = 60
    @State private var tankCapacityCuFt: Int = 80
    @State private var servicePressurePsi: Int = 3000
    @State private var currentPressurePsi: Int = 2500
    @State private var reservePressurePsi: Int = 500

    private static let rmvTenthsRange = Array(1...30) // 0.1 ... 3.0 cu ft/min
    private static let depthRange = Array(0...300)
    private static let tankCapacityRange = Array(6...200)
    private static let pressureRange = Array(stride(from: 0, through: 3500, by: 50))
    private static let reserveRange = Array(stride(from: 0, through: 1500, by: 50))

    private var rmv: Double {
        Double(rmvTenths) / 10.0
    }

    private var ata: Double {
        Double(depthFt) / 33.0 + 1.0
    }

    /// Cubic feet of gas per psi of tank pressure.
    private var tankFactor: Double {
        guard servicePressurePsi > 0 else { return 0 }
        return Double(tankCapacityCuFt) / Double(servicePressurePsi)
    }

    /// Consumption rate at depth, converted from cu ft/min back to psi/min
    /// for this specific tank.
    private var consumptionPsiPerMin: Double {
        guard tankFactor > 0 else { return 0 }
        return (rmv * ata) / tankFactor
    }

    private var usablePressurePsi: Int {
        max(0, currentPressurePsi - reservePressurePsi)
    }

    private var minutesRemaining: Double {
        guard consumptionPsiPerMin > 0 else { return 0 }
        return Double(usablePressurePsi) / consumptionPsiPerMin
    }

    /// Pressure at which to turn the dive so you're back at your reserve by
    /// the time you've used up your usable gas on the way out and back --
    /// the midpoint between current pressure and reserve.
    private var turnPressurePsi: Int {
        currentPressurePsi - usablePressurePsi / 2
    }

    var body: some View {
        Form {
            Section("Consumption Rate") {
                NumberWheel(
                    label: "RMV (cu ft/min)",
                    selection: $rmvTenths,
                    values: Self.rmvTenthsRange,
                    format: { String(format: "%.1f", Double($0) / 10.0) }
                )
                NumberWheel(label: "Depth (ft)", selection: $depthFt, values: Self.depthRange)
            }

            Section("Tank & Gas") {
                NumberWheel(label: "Tank Capacity (cu ft)", selection: $tankCapacityCuFt, values: Self.tankCapacityRange)
                NumberWheel(label: "Service Pressure (psi)", selection: $servicePressurePsi, values: Self.pressureRange)
                NumberWheel(label: "Current Pressure (psi)", selection: $currentPressurePsi, values: Self.pressureRange)
                NumberWheel(label: "Reserve (psi)", selection: $reservePressurePsi, values: Self.reserveRange)
            }

            Section {
                ResultRow(label: "Time Remaining", value: minutesRemaining, unit: "min", decimalPlaces: 0)
                ResultRow(label: "Turn Pressure", value: Double(max(0, turnPressurePsi)), unit: "psi", decimalPlaces: 0)
                HStack {
                    Text("Consumption at Depth")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f psi/min", consumptionPsiPerMin))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            } header: {
                Text("Results")
            } footer: {
                Text("Turn Pressure assumes the swim back out uses roughly the same gas as the swim in -- adjust for current, task loading, or an out-and-back profile that isn't symmetric.")
            }
        }
        .navigationTitle("Gas Time Remaining")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GasTimeCalculatorView()
    }
}
