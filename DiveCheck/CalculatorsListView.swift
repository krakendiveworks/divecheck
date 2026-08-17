import SwiftUI

/// The "Calculators" Tools entry, one tap in from the home screen. Grouped
/// into three sections by what question each calculator answers, rather
/// than one flat list:
/// - **Gas Mix & Exposure Limits** -- is this mix/depth/time combination
///   within safe operating limits (PPO2, narcosis, CNS oxygen exposure)?
/// - **Gas Consumption & Reserves** -- how much gas will/did I use, and how
///   much do I need in reserve?
/// - **Weighting** -- how much lead do I need to be neutrally buoyant?
struct CalculatorsListView: View {
    var body: some View {
        List {
            Section {
                NavigationLink(value: ChecklistRoute.modCalculator) {
                    ToolRow(
                        title: "MOD Calculator",
                        subtitle: "Max operating depth for a gas mix",
                        symbolName: "arrow.down.to.line"
                    )
                }
                NavigationLink(value: ChecklistRoute.ppo2Calculator) {
                    ToolRow(
                        title: "PPO2 Calculator",
                        subtitle: "Partial pressure of O2 at depth",
                        symbolName: "percent"
                    )
                }
                NavigationLink(value: ChecklistRoute.bestMixCalculator) {
                    ToolRow(
                        title: "Best Mix Calculator",
                        subtitle: "Optimal Nitrox blend for PPO2 and depth",
                        symbolName: "flask.fill"
                    )
                }
                NavigationLink(value: ChecklistRoute.eadCalculator) {
                    ToolRow(
                        title: "EAD Calculator",
                        subtitle: "Equivalent air depth for a Nitrox mix",
                        symbolName: "arrow.up.and.down"
                    )
                }
                NavigationLink(value: ChecklistRoute.endCalculator) {
                    ToolRow(
                        title: "END Calculator",
                        subtitle: "Equivalent narcotic depth for a Trimix",
                        symbolName: "arrow.up.and.down.circle"
                    )
                }
                NavigationLink(value: ChecklistRoute.cnsOxygenCalculator) {
                    ToolRow(
                        title: "CNS O2 Toxicity",
                        subtitle: "NOAA single-exposure oxygen limit %",
                        symbolName: "waveform.path.ecg"
                    )
                }
            } header: {
                Text("Gas Mix & Exposure Limits")
            }

            Section {
                NavigationLink(value: ChecklistRoute.sacCalculator) {
                    ToolRow(
                        title: "SAC / RMV Calculator",
                        subtitle: "Estimate gas consumption rates",
                        symbolName: "chart.xyaxis.line"
                    )
                }
                NavigationLink(value: ChecklistRoute.gasTimeCalculator) {
                    ToolRow(
                        title: "Gas Time Remaining",
                        subtitle: "Minutes left and turn pressure mid-dive",
                        symbolName: "gauge.with.dots.needle.33percent"
                    )
                }
                NavigationLink(value: ChecklistRoute.minimumGasCalculator) {
                    ToolRow(
                        title: "Minimum Gas",
                        subtitle: "Reserve gas to share a problem and ascend",
                        symbolName: "exclamationmark.arrow.triangle.2.circlepath"
                    )
                }
                NavigationLink(value: ChecklistRoute.tankFillCalculator) {
                    ToolRow(
                        title: "Tank Fill",
                        subtitle: "Cubic feet added for a given pressure rise",
                        symbolName: "cylinder.fill"
                    )
                }
            } header: {
                Text("Gas Consumption & Reserves")
            }

            Section {
                NavigationLink(value: ChecklistRoute.weightCheckCalculator) {
                    ToolRow(
                        title: "Weight Check",
                        subtitle: "Starting weight estimate for your setup",
                        symbolName: "scalemass.fill"
                    )
                }
            } header: {
                Text("Weighting")
            }
        }
        .navigationTitle("Calculators")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CalculatorsListView()
    }
}
