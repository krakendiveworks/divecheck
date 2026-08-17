import SwiftUI

/// Calculates Maximum Operating Depth (MOD) for a given gas mix and target
/// PPO2. MOD is the deepest a diver can go on that mix before PPO2 exceeds
/// the chosen limit.
///
/// MOD (ft) = 33 * (PPO2 / FO2 - 1), where FO2 is the fraction of O2 in the
/// mix (e.g. 32% = 0.32) and 33 ft of seawater equals one atmosphere.
struct MODCalculatorView: View {
    @State private var o2Percent: Int = 32
    @State private var ppo2Tenths: Int = 14 // 1.4

    private static let o2PercentRange = Array(8...100)
    private static let ppo2TenthsRange = Array(7...16) // 0.7 ... 1.6

    private var ppo2: Double {
        Double(ppo2Tenths) / 10.0
    }

    private var fo2: Double {
        Double(o2Percent) / 100.0
    }

    /// Exact MOD in feet.
    private var modFtExact: Double {
        guard fo2 > 0 else { return 0 }
        return 33.0 * (ppo2 / fo2 - 1.0)
    }

    /// MOD rounded down to the nearest whole foot — the conservative,
    /// diveable number.
    private var modFtSafe: Int {
        max(0, Int(modFtExact.rounded(.down)))
    }

    var body: some View {
        Form {
            Section("Gas Mix") {
                NumberWheel(label: "O2 in Mix (%)", selection: $o2Percent, values: Self.o2PercentRange)
                NumberWheel(
                    label: "Target PPO2",
                    selection: $ppo2Tenths,
                    values: Self.ppo2TenthsRange,
                    format: { String(format: "%.1f", Double($0) / 10.0) }
                )
            }

            Section("Results") {
                ResultRow(label: "MOD", value: Double(modFtSafe), unit: "ft", decimalPlaces: 0)
                HStack {
                    Text("Exact")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f ft", modFtExact))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
        .navigationTitle("MOD Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MODCalculatorView()
    }
}
