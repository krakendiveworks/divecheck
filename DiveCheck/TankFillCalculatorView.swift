import SwiftUI

/// Converts a pressure increase at the fill station into the equivalent
/// free-gas volume added, supporting either of the two ways divers
/// describe tank size:
/// - **Cubic Feet** -- the tank's nominal rated capacity (the number
///   printed on a US-market tank, e.g. "80" for an AL80), which only means
///   something paired with the tank's rated Service Pressure -- the same
///   "capacity / service pressure = cu ft per psi" relationship the Gas
///   Time Remaining and Minimum Gas calculators already use.
/// - **Liters** -- the tank's physical water volume, how metric-market
///   tanks (mostly steel) are usually labeled, e.g. "12L". Cu ft per psi
///   here follows directly from Boyle's Law and depends only on that
///   physical volume -- unlike Cubic Feet mode, Service Pressure/Material/
///   Pressure Rating don't change the answer, since those describe the
///   tank's *maximum* fill, not its psi-to-volume ratio. Those fields are
///   hidden in Liters mode rather than shown-but-inert, so nothing on
///   screen looks like it should do something and silently doesn't.
struct TankFillCalculatorView: View {
    private enum VolumeUnit: String, CaseIterable, Identifiable {
        case cubicFeet = "Cubic Feet"
        case liters = "Liters"
        var id: String { rawValue }
    }

    private enum TankMaterial: String, CaseIterable, Identifiable {
        case aluminum = "Aluminum"
        case steel = "Steel"
        var id: String { rawValue }
    }

    private enum PressureRating: String, CaseIterable, Identifiable {
        case low = "Low Pressure"
        case high = "High Pressure"
        var id: String { rawValue }
    }

    @State private var volumeUnit: VolumeUnit = .cubicFeet
    @State private var material: TankMaterial = .aluminum
    @State private var rating: PressureRating = .low
    @State private var tankCapacityCuFt: Int = 80
    @State private var waterVolumeLiterTenths: Int = 111 // 11.1 L -- an AL80's actual water volume
    @State private var servicePressurePsi: Int = 3000
    @State private var pressureAddedPsi: Int = 1000

    private static let tankCapacityRange = Array(6...200)
    private static let literTenthsRange = Array(10...250) // 1.0 ... 25.0 L
    private static let pressureRange = Array(stride(from: 0, through: 3500, by: 50))

    /// 1 atmosphere in psi -- the constant tying a physical water volume
    /// (Liters mode) to how much free gas one psi of pressure represents
    /// in it.
    private static let psiPerAtmosphere = 14.696
    private static let cuFtPerLiter = 0.0353147
    private static let literPerCuFt = 28.3168

    private var waterVolumeLiters: Double {
        Double(waterVolumeLiterTenths) / 10.0
    }

    /// Cubic feet of free gas added per psi of pressure increase.
    private var tankFactor: Double {
        switch volumeUnit {
        case .cubicFeet:
            guard servicePressurePsi > 0 else { return 0 }
            return Double(tankCapacityCuFt) / Double(servicePressurePsi)
        case .liters:
            return (waterVolumeLiters * Self.cuFtPerLiter) / Self.psiPerAtmosphere
        }
    }

    private var cuFtAdded: Double {
        tankFactor * Double(pressureAddedPsi)
    }

    private var litersAdded: Double {
        cuFtAdded * Self.literPerCuFt
    }

    var body: some View {
        Form {
            Section {
                Picker("Volume Unit", selection: $volumeUnit) {
                    ForEach(VolumeUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Volume Unit")
            } footer: {
                Text(volumeUnit == .cubicFeet
                     ? "The tank's nominal rated capacity (e.g. \"80\" for an AL80) -- only meaningful paired with a Service Pressure, since that's what the cu ft number is measured at."
                     : "The tank's physical water volume, often stamped on steel tanks (e.g. \"12L\"). This conversion follows directly from that volume and doesn't depend on the tank's material or pressure rating.")
            }

            if volumeUnit == .cubicFeet {
                Section {
                    Picker("Material", selection: $material) {
                        ForEach(TankMaterial.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: material) { _ in applyDefaultServicePressure() }
                    Picker("Rating", selection: $rating) {
                        ForEach(PressureRating.allCases) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: rating) { _ in applyDefaultServicePressure() }
                    NumberWheel(label: "Tank Capacity (cu ft)", selection: $tankCapacityCuFt, values: Self.tankCapacityRange)
                    NumberWheel(label: "Service Pressure (psi)", selection: $servicePressurePsi, values: Self.pressureRange)
                } header: {
                    Text("Tank")
                } footer: {
                    Text("Material/Rating just fill in a typical Service Pressure to start from -- adjust the wheel directly if your tank is rated differently.")
                }
            } else {
                Section("Tank") {
                    NumberWheel(
                        label: "Water Volume (L)",
                        selection: $waterVolumeLiterTenths,
                        values: Self.literTenthsRange,
                        format: { String(format: "%.1f", Double($0) / 10.0) }
                    )
                }
            }

            Section("Fill") {
                NumberWheel(label: "Pressure Added (psi)", selection: $pressureAddedPsi, values: Self.pressureRange)
            }

            Section {
                ResultRow(label: "Cubic Feet Added", value: cuFtAdded, unit: "cu ft", decimalPlaces: 1)
                HStack {
                    Text("Equivalent")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.1f L", litersAdded))
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            } header: {
                Text("Results")
            } footer: {
                Text("A planning estimate from the ideal gas relationship between pressure and volume -- actual fills vary slightly with tank temperature during filling.")
            }
        }
        .navigationTitle("Tank Fill")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Nudges Service Pressure to a typical value for the selected
    /// Material/Rating combo, rounded to the nearest 50 psi step on the
    /// wheel above. Still just a starting point -- the wheel itself stays
    /// fully editable for a tank rated differently.
    private func applyDefaultServicePressure() {
        switch (material, rating) {
        case (.aluminum, .low):
            servicePressurePsi = 3000 // e.g. AL80
        case (.aluminum, .high):
            servicePressurePsi = 3300
        case (.steel, .low):
            servicePressurePsi = 2650 // e.g. LP85/95/108, nominally ~2640
        case (.steel, .high):
            servicePressurePsi = 3450 // e.g. HP100/120/133, nominally 3442
        }
    }
}

#Preview {
    NavigationStack {
        TankFillCalculatorView()
    }
}
