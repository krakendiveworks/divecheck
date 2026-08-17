import SwiftUI

/// Calculates the "Best Mix" of Nitrox for a chosen target PPO2 and planned
/// depth -- the richest O2 percentage that keeps PPO2 at or below the target
/// at that depth.
///
/// FO2 = PPO2 / ATA, where ATA is atmospheres absolute at depth
/// (depth / 33 + 1). The result is rounded down to the nearest whole
/// percent, since rounding up could push the actual PPO2 of a purchased
/// blend above the target.
struct BestMixCalculatorView: View {
    @State private var depthFt: Int = 100
    @State private var ppo2Tenths: Int = 14 // 1.4

    private static let depthRange = Array(0...300)
    private static let ppo2TenthsRange = Array(7...16) // 0.7 ... 1.6

    private var ppo2: Double {
        Double(ppo2Tenths) / 10.0
    }

    private var ata: Double {
        Double(depthFt) / 33.0 + 1.0
    }

    /// Exact best-mix O2 percentage, clamped to a physically valid 0...100.
    private var bestMixPercentExact: Double {
        min(100, max(0, (ppo2 / ata) * 100.0))
    }

    /// The conservative, buyable percentage -- rounded down so the actual
    /// PPO2 of a tank blended to this number never exceeds the target.
    private var bestMixPercentSafe: Int {
        min(100, max(0, Int(bestMixPercentExact.rounded(.down))))
    }

    var body: some View {
        Form {
            Section("Depth & Target PPO2") {
                NumberWheel(label: "Depth (ft)", selection: $depthFt, values: Self.depthRange)
                NumberWheel(
                    label: "Target PPO2",
                    selection: $ppo2Tenths,
                    values: Self.ppo2TenthsRange,
                    format: { String(format: "%.1f", Double($0) / 10.0) }
                )
            }

            Section("Results") {
                ResultRow(label: "Best Mix", value: Double(bestMixPercentSafe), unit: "% O2", decimalPlaces: 0)
                HStack {
                    Text("Exact")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f%% O2", bestMixPercentExact))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                HStack {
                    Text("Depth ATA")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.2f ata", ata))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
        .navigationTitle("Best Mix Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        BestMixCalculatorView()
    }
}
