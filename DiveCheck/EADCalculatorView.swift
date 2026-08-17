import SwiftUI

/// Calculates Equivalent Air Depth (EAD) -- the depth that would produce the
/// same nitrogen narcosis on air as diving a given Nitrox mix at a given
/// depth. Standard Nitrox-course material, and a natural companion to the
/// MOD calculator.
///
/// EAD (ft) = ((Depth + 33) * (FN2 / 0.79)) - 33, where FN2 = 1 - FO2 is the
/// fraction of nitrogen in the mix and 0.79 is the fraction of nitrogen in
/// air. Assumes no helium in the mix (Nitrox, not Trimix).
struct EADCalculatorView: View {
    @State private var o2Percent: Int = 32
    @State private var depthFt: Int = 100

    private static let o2PercentRange = Array(21...100)
    private static let depthRange = Array(0...300)

    private var fo2: Double {
        Double(o2Percent) / 100.0
    }

    private var fn2: Double {
        1.0 - fo2
    }

    /// Exact EAD in feet -- never deeper than the actual depth, since any
    /// O2-enriched mix has less nitrogen than air.
    private var eadFtExact: Double {
        ((Double(depthFt) + 33.0) * (fn2 / 0.79)) - 33.0
    }

    /// EAD rounded up to the nearest whole foot -- the conservative,
    /// diveable number (rounding a narcosis-equivalent depth down would
    /// understate it).
    private var eadFtSafe: Int {
        max(0, Int(eadFtExact.rounded(.up)))
    }

    var body: some View {
        Form {
            Section("Gas Mix & Depth") {
                NumberWheel(label: "O2 in Mix (%)", selection: $o2Percent, values: Self.o2PercentRange)
                NumberWheel(label: "Actual Depth (ft)", selection: $depthFt, values: Self.depthRange)
            }

            Section {
                ResultRow(label: "Equivalent Air Depth", value: Double(eadFtSafe), unit: "ft", decimalPlaces: 0)
                HStack {
                    Text("Exact")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f ft", eadFtExact))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            } header: {
                Text("Results")
            } footer: {
                Text("Shows the depth that would feel equally narcotic if you were breathing air instead of this mix. On air (21% O2) EAD always equals actual depth.")
            }
        }
        .navigationTitle("EAD Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        EADCalculatorView()
    }
}
