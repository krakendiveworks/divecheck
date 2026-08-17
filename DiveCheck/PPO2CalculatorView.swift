import SwiftUI

/// Calculates PPO2 (partial pressure of oxygen) for a given gas mix at a
/// given depth.
///
/// PPO2 = FO2 * ATA, where FO2 is the fraction of O2 in the mix (e.g. 32% =
/// 0.32) and ATA is atmospheres absolute at depth (depth / 33 + 1).
struct PPO2CalculatorView: View {
    @State private var o2Percent: Int = 21
    @State private var depthFt: Int = 60

    private static let o2PercentRange = Array(8...100)
    private static let depthRange = Array(0...300)

    private var fo2: Double {
        Double(o2Percent) / 100.0
    }

    private var ata: Double {
        Double(depthFt) / 33.0 + 1.0
    }

    private var ppo2: Double {
        fo2 * ata
    }

    var body: some View {
        Form {
            Section("Gas Mix & Depth") {
                NumberWheel(label: "O2 in Mix (%)", selection: $o2Percent, values: Self.o2PercentRange)
                NumberWheel(label: "Depth (ft)", selection: $depthFt, values: Self.depthRange)
            }

            Section("Results") {
                ResultRow(label: "PPO2", value: ppo2, unit: "ata")
                HStack {
                    Text("Depth")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.2f ata", ata))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
        .navigationTitle("PPO2 Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        PPO2CalculatorView()
    }
}
