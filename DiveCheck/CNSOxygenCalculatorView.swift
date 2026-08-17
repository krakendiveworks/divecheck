import SwiftUI

/// Calculates CNS (Central Nervous System) oxygen toxicity percentage for a
/// single dive segment, using the NOAA single-exposure oxygen time limits --
/// the same table taught in Nitrox and tech courses alongside PPO2 and MOD.
/// Pairs directly with the PPO2 calculator.
///
/// CNS% = (bottom time / NOAA max single exposure time for this PPO2) * 100.
/// The NOAA table only defines limits at 0.1 ATA steps, so the looked-up
/// PPO2 is rounded *up* to the next step -- the conservative direction,
/// since a higher PPO2 has a shorter allowed time. An optional "Starting
/// CNS %" carries over loading from earlier dives the same day (this
/// calculator doesn't model the ~90-minute surface-interval decay itself --
/// a dive computer or a manual look at the decay tables is the right tool
/// for that).
struct CNSOxygenCalculatorView: View {
    @State private var o2Percent: Int = 32
    @State private var depthFt: Int = 100
    @State private var bottomTimeMin: Int = 30
    @State private var startingCNSPercent: Int = 0

    private static let o2PercentRange = Array(8...100)
    private static let depthRange = Array(0...300)
    private static let bottomTimeRange = Array(1...300)
    private static let startingCNSRange = Array(stride(from: 0, through: 150, by: 5))

    /// NOAA single-exposure oxygen limits, keyed by PPO2 in tenths of an
    /// atmosphere (0.6...1.6 ATA), value is the max exposure time in
    /// minutes for 100% CNS loading at that PPO2.
    private static let noaaLimits: [Int: Int] = [
        6: 720, 7: 570, 8: 450, 9: 360, 10: 300,
        11: 240, 12: 210, 13: 180, 14: 150, 15: 120, 16: 45,
    ]

    private var fo2: Double {
        Double(o2Percent) / 100.0
    }

    private var ata: Double {
        Double(depthFt) / 33.0 + 1.0
    }

    private var ppo2: Double {
        fo2 * ata
    }

    /// PPO2 rounded up to the nearest table step, clamped to the table's
    /// 0.6...1.6 range.
    private var lookupTenths: Int {
        min(16, max(6, Int((ppo2 * 10).rounded(.up))))
    }

    private var exceedsRecommendedLimit: Bool {
        ppo2 > 1.6
    }

    private var isNegligible: Bool {
        ppo2 < 0.6
    }

    private var maxExposureMinutes: Int? {
        isNegligible ? nil : Self.noaaLimits[lookupTenths]
    }

    private var segmentCNSPercent: Double {
        guard let maxExposureMinutes, maxExposureMinutes > 0 else { return 0 }
        return (Double(bottomTimeMin) / Double(maxExposureMinutes)) * 100.0
    }

    private var totalCNSPercent: Double {
        Double(startingCNSPercent) + segmentCNSPercent
    }

    var body: some View {
        Form {
            Section("Gas Mix, Depth & Time") {
                NumberWheel(label: "O2 in Mix (%)", selection: $o2Percent, values: Self.o2PercentRange)
                NumberWheel(label: "Depth (ft)", selection: $depthFt, values: Self.depthRange)
                NumberWheel(label: "Bottom Time (min)", selection: $bottomTimeMin, values: Self.bottomTimeRange)
            }

            Section {
                NumberWheel(label: "Starting CNS % (earlier dives today)", selection: $startingCNSPercent, values: Self.startingCNSRange)
            } footer: {
                Text("Leave at 0 for a first dive of the day. CNS loading decays over a surface interval but not fully -- if you've dived already today, enter your running total from your computer or logbook here.")
            }

            Section("Results") {
                if isNegligible {
                    Text("PPO2 is below 0.6 ATA -- negligible CNS loading at this depth and mix.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    HStack {
                        Text("Total CNS").font(.headline)
                        Spacer()
                        Text(String(format: "%.0f %%", totalCNSPercent))
                            .font(.headline)
                            .foregroundStyle(totalCNSPercent > 100 ? .red : .blue)
                    }
                    .padding(.vertical, 2)
                    if segmentCNSPercent > 0 {
                        HStack {
                            Text("This Dive")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(String(format: "%.0f%%", segmentCNSPercent))
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                    HStack {
                        Text("PPO2")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.2f ata", ppo2))
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    if exceedsRecommendedLimit {
                        Label("PPO2 exceeds the 1.6 ATA NOAA recommended maximum -- shown using the 1.6 ATA limit, but this mix/depth combination isn't recommended.", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if totalCNSPercent > 100 {
                        Label("Exceeds 100% CNS -- this exposure is beyond NOAA's single-exposure limit.", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .navigationTitle("CNS O2 Toxicity")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CNSOxygenCalculatorView()
    }
}
