import SwiftUI

/// Calculates Equivalent Narcotic Depth (END) for a Trimix (O2/He/N2) blend
/// -- the depth that would produce the same narcotic effect on air, same
/// idea as EAD but accounting for helium, which isn't narcotic. Standard
/// technical/Trimix-course material.
///
/// Two conventions are in use for whether O2 counts as narcotic:
/// - **Counting O2** (the modern, more conservative default most tech
///   agencies teach today, since evidence suggests O2 is roughly as
///   narcotic as N2): END = (Depth + 33) * (FN2 + FO2) - 33
/// - **Excluding O2** (the older convention, same structure as EAD):
///   END = (Depth + 33) * (FN2 / 0.79) - 33
///
/// Both reduce to EAD's formula when Helium is 0%, and counting-O2 reduces
/// to exactly the actual depth for air itself (FN2 + FO2 = 1.0).
struct ENDCalculatorView: View {
    @State private var o2Percent: Int = 18
    @State private var hePercent: Int = 45
    @State private var depthFt: Int = 200
    @State private var countO2AsNarcotic = true

    private static let o2PercentRange = Array(1...100)
    private static let hePercentRange = Array(0...95)
    private static let depthRange = Array(0...400)

    private var fo2: Double {
        Double(o2Percent) / 100.0
    }

    private var fhe: Double {
        Double(hePercent) / 100.0
    }

    private var mixIsInvalid: Bool {
        fo2 + fhe > 1.0
    }

    /// Fraction of nitrogen in the mix, clamped to 0 for an invalid
    /// (O2 + He > 100%) combination rather than going negative.
    private var fn2: Double {
        max(0, 1.0 - fo2 - fhe)
    }

    private var endFtExact: Double {
        let depth = Double(depthFt)
        if countO2AsNarcotic {
            return (depth + 33.0) * (fn2 + fo2) - 33.0
        } else {
            return (depth + 33.0) * (fn2 / 0.79) - 33.0
        }
    }

    /// END rounded up to the nearest whole foot -- the conservative,
    /// diveable number (rounding a narcosis-equivalent depth down would
    /// understate it).
    private var endFtSafe: Int {
        max(0, Int(endFtExact.rounded(.up)))
    }

    var body: some View {
        Form {
            Section("Trimix & Depth") {
                NumberWheel(label: "O2 in Mix (%)", selection: $o2Percent, values: Self.o2PercentRange)
                NumberWheel(label: "He in Mix (%)", selection: $hePercent, values: Self.hePercentRange)
                NumberWheel(label: "Actual Depth (ft)", selection: $depthFt, values: Self.depthRange)
                if mixIsInvalid {
                    Label("O2 + He exceeds 100% -- adjust the mix.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
                Toggle("Count O2 as Narcotic", isOn: $countO2AsNarcotic)
            } footer: {
                Text("Counting O2 as narcotic is the more conservative, widely recommended default -- evidence suggests it's roughly as narcotic as nitrogen. Turn this off to use the older convention that only counts nitrogen.")
            }

            Section {
                ResultRow(label: "Equivalent Narcotic Depth", value: Double(endFtSafe), unit: "ft", decimalPlaces: 0)
                HStack {
                    Text("Exact")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f ft", endFtExact))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                HStack {
                    Text("N2 in Mix")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", fn2 * 100))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            } header: {
                Text("Results")
            } footer: {
                Text("Shows the depth that would feel equally narcotic if you were breathing air instead of this Trimix. On air (21/0) END always equals actual depth.")
            }
        }
        .navigationTitle("END Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ENDCalculatorView()
    }
}
