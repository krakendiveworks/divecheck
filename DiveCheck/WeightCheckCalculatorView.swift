import SwiftUI

/// Exposure suit thickness, for the Weight Check calculator's suit
/// baseline. Baselines follow the PADI Peak Performance Buoyancy starting
/// points (as published in Scuba Diving Magazine's buoyancy calculator
/// guide): swimsuit/skin is a flat few pounds rather than a percentage,
/// 3mm is 5% of body weight, 5mm/7mm is 10%, and drysuits are 10% plus a
/// flat undergarment allowance. Drysuit is broken into light/medium/heavy
/// undergarments (rather than one flat "drysuit" number) since undergarment
/// bulk affects inherent buoyancy nearly as much as the suit itself.
enum WetsuitExposure: String, CaseIterable, Identifiable {
    case none = "None / Rash Guard / Dive Skin"
    case shorty3mm = "3mm Shorty"
    case full3mm = "3mm Full"
    case full5mm = "5mm Full"
    case full7mm = "7mm Full / Semi-Dry"
    case drysuitLight = "Drysuit, Light Undergarments"
    case drysuitMedium = "Drysuit, Medium Undergarments"
    case drysuitHeavy = "Drysuit, Heavy Undergarments"

    var id: String { rawValue }

    /// Suit baseline in pounds for a given body weight -- a mix of flat
    /// amounts and percentages of body weight, per PADI's published
    /// starting points.
    func baselineLb(bodyWeightLb: Double) -> Double {
        switch self {
        case .none: return 2.5
        case .shorty3mm: return bodyWeightLb * 0.04
        case .full3mm: return bodyWeightLb * 0.05
        case .full5mm: return bodyWeightLb * 0.10
        case .full7mm: return bodyWeightLb * 0.10
        case .drysuitLight: return bodyWeightLb * 0.10 + 4
        case .drysuitMedium: return bodyWeightLb * 0.10 + 7
        case .drysuitHeavy: return bodyWeightLb * 0.10 + 11
        }
    }
}

/// Overall body composition, for the Weight Check calculator's body
/// composition offset. Muscle is denser than fat, so a more muscular/lean
/// diver needs less added lead than an average build, and a heavier-set
/// build needs somewhat more -- a rule of thumb, not a precise number.
enum BodyBuild: String, CaseIterable, Identifiable {
    case leanSlender = "Lean / Slender"
    case average = "Average"
    case athleticMuscular = "Athletic / Muscular"
    case broadHeavySet = "Broad / Heavy-set"

    var id: String { rawValue }

    var offsetLb: Double {
        switch self {
        case .leanSlender: return -2
        case .average: return 0
        case .athleticMuscular: return -3
        case .broadHeavySet: return 3
        }
    }
}

/// Diver experience/comfort level, for a small optional margin on the
/// Weight Check calculator. Experience doesn't change anyone's actual
/// physical buoyancy -- what it changes is breath control and relaxation,
/// which is why newer divers are commonly taught to carry a couple of
/// extra pounds of margin while they're still developing that, and why
/// experienced divers can often trim a pound back off once they've dialed
/// their setup in.
enum DiverExperience: String, CaseIterable, Identifiable {
    case new = "New"
    case comfortable = "Comfortable"
    case experienced = "Experienced"

    var id: String { rawValue }

    var offsetLb: Double {
        switch self {
        case .new: return 2
        case .comfortable: return 0
        case .experienced: return -1
        }
    }
}

/// Cylinder material, for the Weight Check calculator's cylinder offset.
/// Steel cylinders are typically more negatively buoyant than aluminum of
/// similar capacity, so a steel-tank diver needs less added lead.
enum TankMaterial: String, CaseIterable, Identifiable {
    case aluminum = "Aluminum"
    case steel = "Steel"

    var id: String { rawValue }

    var perCylinderOffsetLb: Double {
        self == .steel ? -6 : 0
    }
}

/// Estimates a starting weight for a weight belt/integrated pockets, built
/// from body weight, body build, exposure suit, neoprene accessories, water
/// type, cylinder setup, and worn hardware -- following the PADI Peak
/// Performance Buoyancy starting-point percentages (published in Scuba
/// Diving Magazine's buoyancy calculator guide) and the line-item structure
/// of Dive With Frank's DWF Weight Estimator. This is a starting point for
/// an actual in-water weight check, not a replacement for one -- every
/// source this was built from says exactly that.
struct WeightCheckCalculatorView: View {
    @State private var bodyWeightLb: Int = 160
    @State private var bodyBuild: BodyBuild = .average
    @State private var experience: DiverExperience = .comfortable
    @State private var wetsuit: WetsuitExposure = .full3mm
    @State private var wearingHood = false
    @State private var wearingGloves = false
    @State private var waterType: WaterType = .salt
    @State private var tankMaterial: TankMaterial = .aluminum
    @State private var usingDoubles = false
    @State private var hardwareWeightLb: Int = 0

    private static let bodyWeightRange = Array(stride(from: 60, through: 300, by: 5))
    private static let hardwareWeightRange = Array(0...20)

    /// Neoprene accessories add a small amount of buoyant material even
    /// though they cover comparatively little surface area.
    private static let hoodOffsetLb = 1.0
    private static let glovesOffsetLb = 1.0

    /// Backmount doubles add a manifold and steel bands on top of two
    /// cylinders, so the rig is more negative than just "twice one tank" --
    /// applied on top of each cylinder's own material offset, doubled.
    private static let doublesRiggingOffsetLb = -4.0

    private var suitBaselineLb: Double {
        wetsuit.baselineLb(bodyWeightLb: Double(bodyWeightLb))
    }

    private var neopreneAccessoriesLb: Double {
        (wearingHood ? Self.hoodOffsetLb : 0) + (wearingGloves ? Self.glovesOffsetLb : 0)
    }

    /// Saltwater is more buoyant than freshwater by roughly 2.5% -- applied
    /// to the diver + exposure protection subtotal, since that's the part
    /// of the system this adjustment is actually about.
    private var waterAdjustedSubtotalLb: Double {
        let subtotal = suitBaselineLb + neopreneAccessoriesLb
        return waterType == .fresh ? subtotal * 0.975 : subtotal
    }

    private var cylinderOffsetLb: Double {
        let perCylinder = tankMaterial.perCylinderOffsetLb
        return usingDoubles ? perCylinder * 2 + Self.doublesRiggingOffsetLb : perCylinder
    }

    /// A worn backplate or other rigid steel hardware acts as ballast
    /// that's already on the diver, so it reduces -- not adds to -- how
    /// much additional lead is needed.
    private var hardwareOffsetLb: Double {
        -Double(hardwareWeightLb)
    }

    private var estimatedWeightLb: Double {
        max(0, waterAdjustedSubtotalLb + bodyBuild.offsetLb + experience.offsetLb + cylinderOffsetLb + hardwareOffsetLb)
    }

    private func signed(_ value: Double) -> String {
        String(format: "%@%.1f lb", value >= 0 ? "+" : "", value)
    }

    var body: some View {
        Form {
            Section("You") {
                NumberWheel(label: "Body Weight (lb)", selection: $bodyWeightLb, values: Self.bodyWeightRange)
                Picker("Body Build", selection: $bodyBuild) {
                    ForEach(BodyBuild.allCases) { build in
                        Text(build.rawValue).tag(build)
                    }
                }
                Picker("Experience", selection: $experience) {
                    ForEach(DiverExperience.allCases) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
            }

            Section {
                Picker("Exposure Suit", selection: $wetsuit) {
                    ForEach(WetsuitExposure.allCases) { suit in
                        Text(suit.rawValue).tag(suit)
                    }
                }
                Toggle("Hood", isOn: $wearingHood)
                Toggle("Gloves", isOn: $wearingGloves)
            } header: {
                Text("Exposure Protection")
            }

            Section("Water") {
                Picker("Water Type", selection: $waterType) {
                    ForEach(WaterType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }

            Section {
                Picker("Tank Material", selection: $tankMaterial) {
                    ForEach(TankMaterial.allCases) { material in
                        Text(material.rawValue).tag(material)
                    }
                }
                Toggle("Doubles (Backmount)", isOn: $usingDoubles)
                NumberWheel(label: "Backplate / Hardware Worn (lb)", selection: $hardwareWeightLb, values: Self.hardwareWeightRange)
            } header: {
                Text("Cylinder & Hardware")
            } footer: {
                Text("Backplate/hardware weight is steel or other rigid gear you're already wearing (a backplate, STA, etc.) -- since it acts as ballast, it's subtracted from the estimate rather than added.")
            }

            Section {
                ResultRow(label: "Starting Weight", value: estimatedWeightLb, unit: "lb", decimalPlaces: 0)
                VStack(alignment: .leading, spacing: 4) {
                    breakdownRow("Exposure Baseline", suitBaselineLb)
                    if neopreneAccessoriesLb != 0 {
                        breakdownRow("Neoprene Accessories", neopreneAccessoriesLb)
                    }
                    if waterType == .fresh {
                        breakdownRow("Water Adjustment", waterAdjustedSubtotalLb - (suitBaselineLb + neopreneAccessoriesLb))
                    }
                    if bodyBuild.offsetLb != 0 {
                        breakdownRow("Body Build", bodyBuild.offsetLb)
                    }
                    if experience.offsetLb != 0 {
                        breakdownRow("Experience Margin", experience.offsetLb)
                    }
                    if cylinderOffsetLb != 0 {
                        breakdownRow("Cylinder / Doubles", cylinderOffsetLb)
                    }
                    if hardwareOffsetLb != 0 {
                        breakdownRow("Hardware Worn", hardwareOffsetLb)
                    }
                }
                .padding(.top, 2)
            } header: {
                Text("Results")
            } footer: {
                Text("A starting point, not a substitute for an actual weight check: in full gear with an empty BCD and a normal breath held, you should float at eye level; exhaling should make you sink slowly. The Experience Margin is a practical cushion for breath control, not a physical buoyancy calculation -- it's fine to leave it out. If you check your weighting with a full tank rather than one near reserve pressure, expect to feel about 4-5 lb lighter than this number once the tank is mostly empty near the end of the dive.")
            }
        }
        .navigationTitle("Weight Check")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func breakdownRow(_ label: String, _ value: Double) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(signed(value))
                .foregroundStyle(.secondary)
        }
        .font(.caption)
    }
}

#Preview {
    NavigationStack {
        WeightCheckCalculatorView()
    }
}
