import SwiftUI
import PhotosUI
import UIKit

struct DiveLogDetailView: View {
    @ObservedObject var store: AppStore
    let entryID: UUID
    @State private var photoPickerItems: [PhotosPickerItem] = []
    @State private var isShowingLocationPicker = false
    @State private var isShowingDiveComputerPicker = false
    @State private var isShowingBuddyPicker = false
    @State private var isShowingEquipmentPicker = false
    @State private var isShowingSavedConfirmation = false
    @State private var sacCalculationMessage: String?

    private var entry: Binding<DiveLogEntry> {
        store.diveLogBinding(for: entryID)
    }

    private var photosPickerButton: some View {
        PhotosPicker(selection: $photoPickerItems, maxSelectionCount: 10, matching: .images) {
            Label("Add Photos", systemImage: "photo.badge.plus")
        }
    }

    private var tankSizeBinding: Binding<String> {
        Binding<String>(
            get: { entry.wrappedValue.gasDetails.tankSizeCuFt ?? "" },
            set: { entry.wrappedValue.gasDetails.tankSizeCuFt = $0 }
        )
    }

    private var servicePressureBinding: Binding<String> {
        Binding<String>(
            get: { entry.wrappedValue.gasDetails.servicePressurePsi ?? "" },
            set: { entry.wrappedValue.gasDetails.servicePressurePsi = $0 }
        )
    }

    var body: some View {
        Form {
            Section("Overview") {
                DatePicker("Date & Time", selection: entry.date)
                Picker("Dive Type", selection: entry.diveType) {
                    ForEach(DiveLogType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                Button {
                    isShowingLocationPicker = true
                } label: {
                    HStack {
                        Text("Location")
                        Spacer()
                        Text(displayLocationName.isEmpty ? "Select" : displayLocationName)
                            .foregroundStyle(displayLocationName.isEmpty ? .blue : .secondary)
                    }
                }
                Button {
                    isShowingDiveComputerPicker = true
                } label: {
                    HStack {
                        Text("Source Computer")
                        Spacer()
                        Text(store.displayDeviceName(for: entry.wrappedValue))
                            .foregroundStyle(.secondary)
                    }
                }
                Picker("Site Type", selection: Binding(
                    get: { entry.wrappedValue.siteType ?? .reef },
                    set: { entry.wrappedValue.siteType = $0 }
                )) {
                    ForEach(SiteType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                Picker("Entry Type", selection: Binding(
                    get: { entry.wrappedValue.entryType ?? .boat },
                    set: { entry.wrappedValue.entryType = $0 }
                )) {
                    ForEach(DiveEntryType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }

            Section("Depth & Time") {
                Picker("Depth Unit", selection: Binding(
                    get: { entry.wrappedValue.depthUnit },
                    set: { newUnit in
                        let oldUnit = entry.wrappedValue.depthUnit
                        guard newUnit != oldUnit else { return }
                        entry.wrappedValue.maxDepth = UnitConversion.convertDepth(entry.wrappedValue.maxDepth, from: oldUnit, to: newUnit)
                        entry.wrappedValue.averageDepth = UnitConversion.convertDepth(entry.wrappedValue.averageDepth, from: oldUnit, to: newUnit)
                        entry.wrappedValue.visibility = UnitConversion.convertDepth(entry.wrappedValue.visibility, from: oldUnit, to: newUnit)
                        entry.wrappedValue.depthUnit = newUnit
                    }
                )) {
                    ForEach(DepthUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                LabeledTextField(label: "Duration (min)", text: entry.durationMinutes, keyboardType: .numberPad)
                LabeledTextField(label: "Max Depth (\(entry.wrappedValue.depthUnit.rawValue))", text: entry.maxDepth, keyboardType: .decimalPad)
                LabeledTextField(label: "Average Depth (\(entry.wrappedValue.depthUnit.rawValue))", text: entry.averageDepth, keyboardType: .decimalPad)
            }

            Section("Conditions") {
                Picker("Temperature Unit", selection: Binding(
                    get: { entry.wrappedValue.temperatureUnit },
                    set: { newUnit in
                        let oldUnit = entry.wrappedValue.temperatureUnit
                        guard newUnit != oldUnit else { return }
                        entry.wrappedValue.waterTemperature = UnitConversion.convertTemperature(entry.wrappedValue.waterTemperature, from: oldUnit, to: newUnit)
                        entry.wrappedValue.airTemperature = UnitConversion.convertTemperature(entry.wrappedValue.airTemperature, from: oldUnit, to: newUnit)
                        entry.wrappedValue.temperatureUnit = newUnit
                    }
                )) {
                    ForEach(TemperatureUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                LabeledTextField(label: "Water Temp (\(entry.wrappedValue.temperatureUnit.rawValue))", text: entry.waterTemperature, keyboardType: .decimalPad)
                LabeledTextField(label: "Air Temp (\(entry.wrappedValue.temperatureUnit.rawValue))", text: entry.airTemperature, keyboardType: .decimalPad)
                LabeledTextField(label: "Visibility (\(entry.wrappedValue.depthUnit.rawValue))", text: entry.visibility, keyboardType: .decimalPad)
                Picker("Water Type", selection: entry.waterType) {
                    ForEach(WaterType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                Picker("Water Surface", selection: Binding(
                    get: { entry.wrappedValue.waterSurfaceCondition ?? .calm },
                    set: { entry.wrappedValue.waterSurfaceCondition = $0 }
                )) {
                    ForEach(WaterSurfaceCondition.allCases) { cond in
                        Text(cond.rawValue).tag(cond)
                    }
                }
                Picker("Sky", selection: Binding(
                    get: { entry.wrappedValue.skyCondition ?? .sunny },
                    set: { entry.wrappedValue.skyCondition = $0 }
                )) {
                    ForEach(SkyCondition.allCases) { cond in
                        Text(cond.rawValue).tag(cond)
                    }
                }
                Picker("Wind Speed", selection: Binding(
                    get: { entry.wrappedValue.windSpeedRange ?? .calm },
                    set: { entry.wrappedValue.windSpeedRange = $0 }
                )) {
                    ForEach(WindSpeedRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                Picker("Wind Direction", selection: Binding(
                    get: { entry.wrappedValue.windDirection ?? .n },
                    set: { entry.wrappedValue.windDirection = $0 }
                )) {
                    ForEach(WindDirection.allCases) { direction in
                        Text(direction.rawValue).tag(direction)
                    }
                }
            }

            Section("Gas & Consumption") {
                if entry.wrappedValue.diveType == .closedCircuit {
                    LabeledTextField(label: "High O2 Setpoint", text: entry.gasDetails.o2SetpointHigh, keyboardType: .decimalPad)
                    LabeledTextField(label: "Low O2 Setpoint", text: entry.gasDetails.o2SetpointLow, keyboardType: .decimalPad)
                    LabeledTextField(label: "Diluent (O2%)", text: entry.gasDetails.diluent, keyboardType: .decimalPad)
                    LabeledTextField(label: "Bailout Gas (O2%)", text: entry.gasDetails.bailoutGas, keyboardType: .decimalPad)
                } else {
                    LabeledTextField(label: "Gas Mix", text: entry.gasDetails.gasMix)
                    LabeledTextField(label: "Cylinder Config", text: entry.gasDetails.cylinderConfig)
                    LabeledTextField(label: "Tank Size (cu ft)", text: tankSizeBinding, keyboardType: .decimalPad)
                    LabeledTextField(label: "Service Pressure (psi)", text: servicePressureBinding, keyboardType: .decimalPad)
                    LabeledTextField(label: "Start Pressure (psi)", text: entry.gasDetails.startPressure, keyboardType: .decimalPad)
                    LabeledTextField(label: "End Pressure (psi)", text: entry.gasDetails.endPressure, keyboardType: .decimalPad)
                    LabeledMultilineField(label: "Additional Cylinders / Gas Switches", text: entry.gasDetails.additionalCylinders)
                }
                LabeledTextField(label: "SAC Rate", text: entry.sacRate)
                LabeledTextField(label: "RMV / SCR", text: entry.rmvRate)
                if entry.wrappedValue.diveType != .closedCircuit {
                    Button {
                        calculateSACAndRMV()
                    } label: {
                        Label("Calculate from Tank Data", systemImage: "function")
                    }
                    if let sacCalculationMessage {
                        Text(sacCalculationMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Dive Buddies") {
                Button {
                    isShowingBuddyPicker = true
                } label: {
                    HStack {
                        Text("Select Buddies")
                        Spacer()
                        Text("\(entry.wrappedValue.buddyIDs.count) selected")
                            .foregroundStyle(.secondary)
                    }
                }
                if !buddyNames.isEmpty {
                    Text(buddyNames.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Gear & What You Wore") {
                Button {
                    isShowingEquipmentPicker = true
                } label: {
                    HStack {
                        Text("Select Gear Used")
                        Spacer()
                        Text("\(entry.wrappedValue.equipmentUsedIDs.count) selected")
                            .foregroundStyle(.secondary)
                    }
                }
                if !equipmentNames.isEmpty {
                    Text(equipmentNames.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Picker("Weight Unit", selection: Binding(
                    get: { entry.wrappedValue.weightUnit },
                    set: { newUnit in
                        let oldUnit = entry.wrappedValue.weightUnit
                        guard newUnit != oldUnit else { return }
                        entry.wrappedValue.weightUsed = UnitConversion.convertWeight(entry.wrappedValue.weightUsed, from: oldUnit, to: newUnit)
                        entry.wrappedValue.weightUnit = newUnit
                    }
                )) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
                LabeledTextField(label: "Weight Used (\(entry.wrappedValue.weightUnit.rawValue))", text: entry.weightUsed, keyboardType: .decimalPad)
            }

            Section("Reflection") {
                Picker("Rating", selection: Binding(
                    get: { entry.wrappedValue.rating ?? 0 },
                    set: { entry.wrappedValue.rating = $0 == 0 ? nil : $0 }
                )) {
                    Text("None").tag(0)
                    ForEach(1...5, id: \.self) { n in
                        Text(String(repeating: "★", count: n)).tag(n)
                    }
                }
                LabeledMultilineField(label: "Notes / What You Saw", text: entry.notes, placeholder: "Marine life, wreck details, anything worth remembering")
            }

            Section("Photos") {
                if let filenames = entry.wrappedValue.photoFilenames, !filenames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(filenames, id: \.self) { filename in
                                DivePhotoThumbnail(filename: filename) {
                                    removePhoto(filename)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                // onChange(of:perform:) was deprecated in iOS 17 in favor of a
                // two-parameter (or zero-parameter) closure, but the
                // replacement isn't available pre-iOS 17 -- branching here
                // keeps iOS 16 support while avoiding the deprecation warning
                // on newer OS versions.
                if #available(iOS 17.0, *) {
                    photosPickerButton
                        .onChange(of: photoPickerItems) { _, _ in
                            loadPickedPhotos()
                        }
                } else {
                    photosPickerButton
                        .onChange(of: photoPickerItems) { _ in
                            loadPickedPhotos()
                        }
                }
            }
        }
        .navigationTitle(displayLocationName.isEmpty ? "Dive Log Entry" : displayLocationName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    entry.wrappedValue.savedAt = Date()
                    isShowingSavedConfirmation = true
                } label: {
                    Label("Save", systemImage: "tray.and.arrow.down")
                }
            }
        }
        .alert("Dive Log Saved", isPresented: $isShowingSavedConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This entry has been saved. It stays fully editable — keep making changes and tap Save again anytime to update it.")
        }
        .sheet(isPresented: $isShowingLocationPicker) {
            LocationPickerView(store: store, locationID: entry.locationID, diveSiteID: entry.diveSiteID)
        }
        .sheet(isPresented: $isShowingDiveComputerPicker) {
            DiveComputerPickerView(store: store, sourceDeviceID: entry.sourceDeviceID)
        }
        .sheet(isPresented: $isShowingBuddyPicker) {
            BuddyPickerView(store: store, selectedIDs: entry.buddyIDs)
        }
        .sheet(isPresented: $isShowingEquipmentPicker) {
            EquipmentPickerView(store: store, selectedIDs: entry.equipmentUsedIDs)
        }
    }

    private var displayLocationName: String {
        store.displayLocationName(for: entry.wrappedValue)
    }

    private var equipmentNames: [String] {
        entry.wrappedValue.equipmentUsedIDs.compactMap { id in
            store.equipmentLocker.first { $0.id == id }?.name
        }
    }

    private var buddyNames: [String] {
        entry.wrappedValue.buddyIDs.compactMap { id in
            store.savedBuddies.first { $0.id == id }?.name
        }
    }

    /// Fills SAC Rate/RMV from Tank Size, Service Pressure, Start/End
    /// Pressure, Average Depth, and Duration -- see SACCalculation.swift.
    /// Overwrites whatever's currently in those two fields, same as
    /// re-running the standalone SAC/RMV calculator would; a message
    /// explains why nothing happened when the inputs aren't there yet.
    private func calculateSACAndRMV() {
        let gas = entry.wrappedValue.gasDetails
        guard let tankSize = Double(gas.tankSizeCuFt ?? ""), tankSize > 0,
              let servicePressure = Double(gas.servicePressurePsi ?? ""), servicePressure > 0
        else {
            sacCalculationMessage = "Enter Tank Size and Service Pressure to calculate."
            return
        }
        guard let startPressure = Double(gas.startPressure), let endPressure = Double(gas.endPressure) else {
            sacCalculationMessage = "Enter Start and End Pressure to calculate."
            return
        }
        guard let averageDepth = Double(entry.wrappedValue.averageDepth), averageDepth > 0 else {
            sacCalculationMessage = "Enter Average Depth to calculate."
            return
        }
        guard let duration = Double(entry.wrappedValue.durationMinutes), duration > 0 else {
            sacCalculationMessage = "Enter Duration to calculate."
            return
        }

        guard let result = SACCalculation.calculate(
            tankSizeCuFt: tankSize,
            servicePressurePsi: servicePressure,
            startPressurePsi: startPressure,
            endPressurePsi: endPressure,
            averageDepth: averageDepth,
            depthUnit: entry.wrappedValue.depthUnit,
            durationMinutes: duration
        ) else {
            sacCalculationMessage = "Couldn't calculate -- check that End Pressure is less than Start Pressure."
            return
        }

        entry.wrappedValue.sacRate = String(format: "%.1f", result.sacRate)
        entry.wrappedValue.rmvRate = String(format: "%.2f", result.rmvRate)
        sacCalculationMessage = nil
    }

    /// Writes each freshly-picked photo to disk via PhotoStorage and
    /// appends the resulting filenames to the entry, then clears the
    /// picker's own selection so it doesn't re-import the same items if
    /// the picker reopens.
    private func loadPickedPhotos() {
        let items = photoPickerItems
        photoPickerItems = []
        Task {
            var newFilenames: [String] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self), let filename = PhotoStorage.save(data) {
                    newFilenames.append(filename)
                }
            }
            guard !newFilenames.isEmpty else { return }
            var current = entry.wrappedValue.photoFilenames ?? []
            current.append(contentsOf: newFilenames)
            entry.wrappedValue.photoFilenames = current
        }
    }

    private func removePhoto(_ filename: String) {
        PhotoStorage.delete(filename)
        entry.wrappedValue.photoFilenames?.removeAll { $0 == filename }
    }
}

/// One photo thumbnail in a Dive Log entry's Photos section, with a small
/// delete button overlaid in the corner. Loads its image lazily from
/// PhotoStorage rather than the caller holding decoded UIImages for every
/// photo up front.
private struct DivePhotoThumbnail: View {
    let filename: String
    let onDelete: () -> Void
    @State private var image: UIImage?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(.systemGray5)
                }
            }
            .frame(width: 90, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white, .black.opacity(0.6))
            }
            .padding(4)
        }
        .onAppear {
            if image == nil {
                image = PhotoStorage.load(filename)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DiveLogDetailView(store: AppStore(), entryID: UUID())
    }
}
