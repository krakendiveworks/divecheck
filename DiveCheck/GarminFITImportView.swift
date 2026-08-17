import SwiftUI
import UniformTypeIdentifiers
// FITParser (the type used below) is vendored directly into this target as
// GarminFITParser.swift rather than imported from the fit-parser-swift
// package -- see that file's header comment for why.

/// Imports a dive from a Garmin `.fit` file.
///
/// Garmin doesn't allow third-party apps to pair directly over Bluetooth
/// with a Descent watch -- that channel is reserved for the official Garmin
/// Connect app. The supported route for third-party apps is the `.fit` file
/// itself: export/share it from Garmin Connect (or pull it off the watch
/// over USB), then hand it to this screen. Parsing is done with the
/// FITParser package, which wraps Garmin's own official FIT SDK rather than
/// a reimplementation -- see the FITParser setup note in PROJECT.md for the
/// package dependency this screen depends on.
struct GarminFITImportView: View {
    @ObservedObject var store: AppStore

    @State private var isPickerPresented = false
    @State private var isParsing = false
    @State private var parseError: String?
    @State private var pendingEntry: DiveLogEntry?
    @State private var pendingSummaryLine: String = ""
    @State private var looksLikeDuplicate = false
    @State private var importedMessage: String?
    @State private var suggestedLocationName: String?
    @State private var isSuggestingLocation = false

    var body: some View {
        List {
            Section {
                Text("Export the dive from Garmin Connect as a .fit file (or copy it from the watch over USB), then pick it here to import it into your Dive Log.")
                    .foregroundStyle(.secondary)
                Button {
                    isPickerPresented = true
                } label: {
                    Label("Choose .fit File", systemImage: "doc.badge.plus")
                }
                .disabled(isParsing)
            }

            if isParsing {
                Section {
                    HStack {
                        ProgressView()
                        Text("Parsing…")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let parseError {
                Section {
                    Text(parseError)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }

            if let pendingEntry {
                Section("Dive Found") {
                    Text(pendingEntry.date.formatted(date: .abbreviated, time: .shortened))
                    Text(pendingSummaryLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if looksLikeDuplicate {
                        Label("A dive at this date/time is already in your log.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.footnote)
                    }
                    if isSuggestingLocation {
                        HStack {
                            ProgressView()
                            Text("Looking up location…")
                                .foregroundStyle(.secondary)
                        }
                        .font(.footnote)
                    } else if let suggestedLocationName {
                        Button {
                            guard let lat = self.pendingEntry?.gpsLatitude, let lon = self.pendingEntry?.gpsLongitude,
                                  let locationID = store.addLocation(name: suggestedLocationName, latitude: lat, longitude: lon)
                            else { return }
                            self.pendingEntry?.locationID = locationID
                            self.suggestedLocationName = nil
                        } label: {
                            Label("Assign Location: \(suggestedLocationName)", systemImage: "mappin.and.ellipse")
                        }
                        .font(.footnote)
                    }
                    Button {
                        store.addDiveLogEntry(pendingEntry)
                        importedMessage = "Imported \"\(pendingEntry.location.isEmpty ? "Untitled Dive" : pendingEntry.location)\" from \(pendingEntry.date.formatted(date: .abbreviated, time: .shortened))."
                        self.pendingEntry = nil
                        self.suggestedLocationName = nil
                    } label: {
                        Label(looksLikeDuplicate ? "Import Anyway" : "Import This Dive", systemImage: "square.and.arrow.down")
                    }
                }
            }
        }
        .navigationTitle("Import from Garmin (.fit)")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(isPresented: $isPickerPresented, allowedContentTypes: allowedTypes) { result in
            switch result {
            case .success(let url):
                parse(url: url)
            case .failure(let error):
                parseError = error.localizedDescription
            }
        }
        .alert("Import Complete", isPresented: .constant(importedMessage != nil), actions: {
            Button("OK") { importedMessage = nil }
        }, message: {
            Text(importedMessage ?? "")
        })
    }

    private var allowedTypes: [UTType] {
        if let fitType = UTType(filenameExtension: "fit") {
            return [fitType, .data]
        }
        return [.data]
    }

    private func parse(url: URL) {
        parseError = nil
        pendingEntry = nil
        isParsing = true

        let needsSecurityScope = url.startAccessingSecurityScopedResource()

        DispatchQueue.global(qos: .userInitiated).async {
            defer {
                if needsSecurityScope {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            // FITParser reads from a plain filesystem path, so the picked
            // file (which may live outside the app's sandbox, e.g. iCloud
            // Drive) is copied into a local temp file first.
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("fit")

            do {
                let data = try Data(contentsOf: url)
                try data.write(to: tempURL)
            } catch {
                DispatchQueue.main.async {
                    isParsing = false
                    parseError = "Couldn't read that file: \(error.localizedDescription)"
                }
                return
            }

            let result = FITParser.parse(fitFilePath: tempURL.path)
            try? FileManager.default.removeItem(at: tempURL)

            DispatchQueue.main.async {
                isParsing = false
                switch result {
                case .success(let fitData):
                    var entry = GarminDiveMapping.entry(from: fitData)
                    entry.sourceDeviceID = resolveDiveComputer(for: fitData)
                    pendingEntry = entry
                    pendingSummaryLine = GarminDiveMapping.summaryLine(for: fitData)
                    looksLikeDuplicate = store.diveLogEntries.contains {
                        abs($0.date.timeIntervalSince(entry.date)) < 60
                    }
                    suggestedLocationName = nil
                    if entry.locationID == nil, let lat = entry.gpsLatitude, let lon = entry.gpsLongitude {
                        isSuggestingLocation = true
                        Task {
                            let name = await LocationSuggestion.suggestName(latitude: lat, longitude: lon)
                            isSuggestingLocation = false
                            suggestedLocationName = name
                        }
                    }
                case .failure(let error):
                    parseError = "Couldn't parse that .fit file: \(error.localizedDescription). Make sure it's a dive log exported from Garmin Connect, not an activity summary."
                }
            }
        }
    }

    /// Resolves (or creates) a saved DiveComputer for this .fit file, keyed
    /// on the watch's device serial number when the file reports one --
    /// that's what lets two physical units of the same Garmin model show up
    /// separately in Statistics. Falls back to keying on the detected model
    /// name alone when no serial number is present (older/less complete FIT
    /// files), which won't distinguish two same-model units without serials
    /// but is still better than lumping every Garmin import together.
    private func resolveDiveComputer(for fit: FITParser) -> UUID {
        let detectedModelName = fit.deviceInfo.first?.productName ?? fit.fileId?.manufacturer ?? "Garmin"
        let serialNumber = fit.deviceInfo.first?.serialNumber ?? fit.fileId?.serialNumber
        let matchKey = serialNumber.map { "garmin-serial-\($0)" } ?? "garmin-model-\(detectedModelName)"
        return store.resolveDiveComputer(matchKey: matchKey, detectedModelName: detectedModelName)
    }
}

/// Maps a parsed Garmin `.fit` dive (via FITParser) into a DiveCheck
/// `DiveLogEntry`. Depth and temperature are left in the metric units the
/// FIT file reports (meters / Celsius), matching the Bluetooth import path,
/// with the entry's unit fields set to match.
enum GarminDiveMapping {
    static func entry(from fit: FITParser) -> DiveLogEntry {
        let session = fit.session
        let primaryGas = fit.diveGases.first(where: { $0.status == "enabled" }) ?? fit.diveGases.first
        let isClosedCircuit = fit.diveGases.contains { $0.mode == "closed circuit diluent" }

        var entry = DiveLogEntry(
            date: session.startTime ?? Date(),
            diveType: isClosedCircuit ? .closedCircuit : (fit.diveGases.count > 1 ? .technical : .openCircuit),
            durationMinutes: durationMinutes(for: fit),
            depthUnit: .meters,
            maxDepth: (session.maxDepth ?? fit.summary?.maxDepth).map { String(format: "%.1f", $0) } ?? "",
            averageDepth: fit.laps.first?.avgDepth.map { String(format: "%.1f", $0) } ?? "",
            temperatureUnit: .celsius,
            waterTemperature: session.avgTemperature.map { String(format: "%.1f", $0) } ?? ""
        )
        entry.sourceDevice = fit.deviceInfo.first?.productName ?? fit.fileId?.manufacturer ?? "Garmin"

        if let waterType = fit.settings?.waterType {
            entry.waterType = waterType == "Fresh" ? .fresh : .salt
        }

        if let primaryGas = primaryGas, let o2 = primaryGas.oxygenContent {
            let he = primaryGas.heliumContent ?? 0
            if entry.diveType == .closedCircuit {
                entry.gasDetails.diluent = "\(o2)%"
            } else {
                entry.gasDetails.gasMix = he > 0 ? "\(he)/\(o2) Trimix" : "\(o2)% O2"
            }
        }

        if !fit.tankSummaries.isEmpty {
            entry.gasDetails.cylinderConfig = "\(fit.tankSummaries.count) tank\(fit.tankSummaries.count == 1 ? "" : "s")"
            if let first = fit.tankSummaries.first {
                if let begin = first.startPressure {
                    entry.gasDetails.startPressure = String(Int((begin * 14.5038).rounded()))
                }
                if let end = first.endPressure {
                    entry.gasDetails.endPressure = String(Int((end * 14.5038).rounded()))
                }
            }
        }

        var notes = "Imported from a Garmin .fit file"
        if let product = fit.fileId?.product {
            notes += " (device \(product))"
        }
        notes += "."
        if let coords = session.startCoordinates {
            notes += String(format: " GPS: %.4f, %.4f", coords.latitude, coords.longitude)
            entry.gpsLatitude = coords.latitude
            entry.gpsLongitude = coords.longitude
        }
        entry.notes = notes

        return entry
    }

    static func summaryLine(for fit: FITParser) -> String {
        var parts: [String] = []
        if let depth = fit.session.maxDepth ?? fit.summary?.maxDepth {
            parts.append(String(format: "Max %.1f m", depth))
        }
        let minutes = Int(durationMinutes(for: fit)) ?? 0
        if minutes > 0 {
            parts.append("\(minutes) min")
        }
        if let temp = fit.session.avgTemperature {
            parts.append(String(format: "%.1f°C", temp))
        }
        return parts.joined(separator: " · ")
    }

    private static func durationMinutes(for fit: FITParser) -> String {
        if let seconds = fit.session.diveTime {
            return String(Int((Double(seconds) / 60).rounded()))
        }
        if let seconds = fit.summary?.bottomTime {
            return String(Int((Double(seconds) / 60).rounded()))
        }
        return ""
    }
}

#Preview {
    NavigationStack {
        GarminFITImportView(store: AppStore())
    }
}
