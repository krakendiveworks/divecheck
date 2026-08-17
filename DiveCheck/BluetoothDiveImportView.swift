import SwiftUI
import CoreBluetooth
import LibDCSwift

/// Scans for, connects to, and downloads dive logs from any BLE dive
/// computer LibDCSwift/libdivecomputer knows how to talk to -- not just
/// Shearwater. `DeviceConfiguration.supportedModels` (inside the LibDCSwift
/// package) currently includes, among others: Shearwater Perdix/Petrel/
/// Teric/Peregrine/Tern/NERD 2; Aqualung i770R/i550C/i300C/i200C/i330R;
/// Oceanic Geo 4.0/Veo 4.0/Pro Plus 4/Atom 3.1/Geo Air; Sherwood Wisdom 3/
/// Sage; Apeks DSX; Suunto EON Steel/Core/D5; Scubapro G2/G3/Aladin/Luna;
/// Heinrichs Weikamp OSTC 2/3/4/Sport; Mares Icon HD/Puck/Quad/Genius;
/// Cressi Goa/Cartesio/Leonardo 2.0/Donatello; Divesoft Freedom/Liberty;
/// Halcyon Symbios; Seac Screen; and a few smaller brands. This screen and
/// its device-detection logic are entirely generic -- nothing here is
/// Shearwater-specific -- so any of the above should work without further
/// code changes, though only Shearwater hardware has actually been tested
/// against this screen so far.
///
/// Aqualung/Oceanic/Sherwood computers (the `oceanicAtom2`/`pelagicI330R`
/// families above) only work here if they have Bluetooth LE -- older
/// USB/infrared-only Oceanic models (Atom, Atom 2.0, Pro Plus 2/3, VT3,
/// VTX, etc.) can't be reached from an iPhone at all, since iOS has no
/// generic USB-serial or infrared support the way a desktop app would.
///
/// LibDCSwift wraps the real libdivecomputer C library (including its BLE
/// protocol implementations for every family above) rather than
/// reimplementing any of these protocols here -- see the LibDCSwift/
/// fit-parser-swift setup note in PROJECT.md for the two package
/// dependencies this screen depends on.
struct BluetoothDiveImportView: View {
    @ObservedObject var store: AppStore
    @StateObject private var bluetoothManager = CoreBluetoothManager.sharedManager
    @StateObject private var diveViewModel = DiveDataViewModel()

    @State private var isConnecting = false
    @State private var connectionError: String?
    @State private var selectedDiveIDs: Set<UUID> = []
    @State private var importSummary: String?

    /// Terminal result of a download, captured by our own `completion`
    /// handler in `startDownload()` rather than read live off
    /// `diveViewModel.progress`.
    ///
    /// LibDCSwift's 0.25s progress-timer callback and its completion
    /// handler both land on the main queue via their own internal
    /// `DispatchQueue.main.async` calls, and there's a real race window
    /// right at the end of a download: a straggling progress tick that was
    /// already in flight when the download finished can get applied to
    /// `diveViewModel.progress` *after* the library's own completion state
    /// (.completed / .failed / .noNewDives), flipping it back to
    /// `.inProgress` and leaving the screen stuck on "Downloading…"
    /// forever even though the download genuinely finished. This was
    /// observed on a real Petrel 3 after 22 dives fully downloaded.
    ///
    /// Our own `completion` closure is only ever scheduled once, after the
    /// library has already applied its terminal state (nested dispatches
    /// from the same outer completion block are FIFO-ordered), so reading
    /// `diveViewModel.progress` at that single point and caching it here is
    /// race-free -- the view then trusts this cached value instead of the
    /// live (and later-clobberable) `diveViewModel.progress`.
    private enum DownloadOutcome {
        case success
        case noNewDives
        case failed(String)
    }
    @State private var downloadOutcome: DownloadOutcome?

    private var connectedPeripheral: CBPeripheral? {
        bluetoothManager.connectedDevice
    }

    private var isConnected: Bool {
        bluetoothManager.openedDeviceDataPtr != nil
    }

    var body: some View {
        List {
            if !bluetoothManager.isBluetoothReady {
                Section {
                    Label("Turn on Bluetooth to scan for dive computers.", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                }
            } else if !isConnected {
                scanSection
            } else {
                downloadSection
            }

            if let connectionError {
                Section {
                    Text(connectionError)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Import from Bluetooth")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if bluetoothManager.isBluetoothReady && !isConnected {
                bluetoothManager.startScanning()
            }
        }
        .onDisappear {
            bluetoothManager.stopScanning()
            if isConnected && !bluetoothManager.isRetrievingLogs {
                bluetoothManager.close(clearDevicePtr: true)
            }
        }
        .alert("Import Complete", isPresented: .constant(importSummary != nil), actions: {
            Button("OK") { importSummary = nil }
        }, message: {
            Text(importSummary ?? "")
        })
    }

    // MARK: - Scanning / connecting

    @ViewBuilder
    private var scanSection: some View {
        Section("Nearby Dive Computers") {
            if bluetoothManager.discoveredPeripherals.isEmpty {
                HStack {
                    ProgressView()
                    Text(bluetoothManager.isScanning ? "Scanning…" : "No devices found yet.")
                        .foregroundStyle(.secondary)
                }
            }
            ForEach(bluetoothManager.discoveredPeripherals, id: \.identifier) { peripheral in
                Button {
                    connect(to: peripheral)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(peripheral.name ?? "Unknown Device")
                            Text(DeviceConfiguration.getDeviceDisplayName(from: peripheral.name ?? ""))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if isConnecting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isConnecting)
            }
        }
        Section {
            Button {
                bluetoothManager.stopScanning()
                bluetoothManager.clearDiscoveredPeripherals()
                bluetoothManager.startScanning()
            } label: {
                Label("Rescan", systemImage: "arrow.clockwise")
            }
            .disabled(isConnecting)
        }
    }

    private func connect(to peripheral: CBPeripheral) {
        isConnecting = true
        connectionError = nil
        bluetoothManager.stopScanning()
        let name = peripheral.name ?? "Dive Computer"
        let address = peripheral.identifier.uuidString

        DispatchQueue.global(qos: .userInitiated).async {
            let success = DeviceConfiguration.openBLEDevice(name: name, deviceAddress: address)
            DispatchQueue.main.async {
                isConnecting = false
                if success {
                    startDownload()
                } else {
                    connectionError = "Couldn't connect to \(name). Make sure the dive computer is on, within range, and not already connected to another app (like Shearwater Cloud, DiverLog+, or Aqualung's app)."
                }
            }
        }
    }

    // MARK: - Download

    @ViewBuilder
    private var downloadSection: some View {
        Section {
            Text(connectedPeripheral?.name ?? "Dive Computer")
            if store.isAdminModeEnabled {
                Button {
                    diveViewModel.clearAllFingerprints()
                    diveViewModel.clear()
                    downloadOutcome = nil
                } label: {
                    Label("Forget Downloaded Dives", systemImage: "arrow.counterclockwise")
                }
            }
            Button(role: .destructive) {
                bluetoothManager.close(clearDevicePtr: true)
                diveViewModel.clear()
                selectedDiveIDs = []
                downloadOutcome = nil
            } label: {
                Label("Disconnect", systemImage: "xmark.circle")
            }
        } header: {
            Text("Connected")
        } footer: {
            // "Forget Downloaded Dives" clears the per-computer fingerprint
            // the library uses to skip already-downloaded dives -- handy
            // while testing, but not something a diver should stumble into
            // by accident, so it's gated behind Admin Mode (Settings) the
            // same as the Dive Log's other bulk/destructive actions.
            if store.isAdminModeEnabled {
                Text("If a download reports \"No dives found\" even though the computer has dives, tap Forget Downloaded Dives first -- the app remembers the most recent dive it already pulled from each computer, to avoid re-downloading everything every time, and that memory can get out of sync while testing.")
            } else {
                Text("If a download reports \"No dives found\" even though the computer has dives, the app may be remembering it as already downloaded. Turn on Admin Mode in Settings to reset that.")
            }
        }

        Section("Dive Logs") {
            // downloadOutcome (set only by our own completion handler, once,
            // after the library has already applied its own terminal state)
            // is checked ahead of the live diveViewModel.progress so a stray
            // late progress tick can't get the view stuck on "Downloading…"
            // after the download has genuinely finished -- see the comment
            // on downloadOutcome's declaration above.
            if let downloadOutcome {
                switch downloadOutcome {
                case .success:
                    if diveViewModel.dives.isEmpty {
                        Text("No dives found on this computer.")
                            .foregroundStyle(.secondary)
                    } else {
                        diveListSection
                    }
                case .noNewDives:
                    Text("No new dives found -- everything on this computer has already been downloaded before.")
                        .foregroundStyle(.secondary)
                case .failed(let message):
                    Text(message).foregroundStyle(.red).font(.footnote)
                    Button("Try Again") { startDownload() }
                }
            } else {
                switch diveViewModel.progress {
                case .notStarted:
                    Button {
                        startDownload()
                    } label: {
                        Label("Download Dive Logs", systemImage: "arrow.down.circle")
                    }
                case .inProgress, .completed, .cancelled, .noNewDives:
                    // .completed/.cancelled/.noNewDives shouldn't normally be
                    // reached here since downloadOutcome is set in the same
                    // completion pass that applies them, but fall back to the
                    // spinner rather than showing a stale/empty list if they
                    // are for some reason observed before downloadOutcome.
                    HStack {
                        ProgressView()
                        Text(diveViewModel.status.isEmpty ? "Downloading…" : diveViewModel.status)
                            .foregroundStyle(.secondary)
                    }
                case .failed(let message):
                    Text(message).foregroundStyle(.red).font(.footnote)
                    Button("Try Again") { startDownload() }
                }
            }
        }
    }

    @ViewBuilder
    private var diveListSection: some View {
        ForEach(diveViewModel.dives.sorted(by: { $0.datetime > $1.datetime })) { dive in
            Button {
                if selectedDiveIDs.contains(dive.id) {
                    selectedDiveIDs.remove(dive.id)
                } else {
                    selectedDiveIDs.insert(dive.id)
                }
            } label: {
                HStack {
                    Image(systemName: selectedDiveIDs.contains(dive.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text(dive.datetime.formatted(date: .abbreviated, time: .shortened))
                        Text(String(format: "Max %.1f m · %d min", dive.maxDepth, Int(dive.divetime / 60)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        Button {
            importSelectedDives()
        } label: {
            Label("Import \(selectedDiveIDs.count) Dive\(selectedDiveIDs.count == 1 ? "" : "s")", systemImage: "square.and.arrow.down")
        }
        .disabled(selectedDiveIDs.isEmpty)
    }

    private func startDownload() {
        guard let devicePtr = bluetoothManager.openedDeviceDataPtr,
              let peripheral = connectedPeripheral else {
            connectionError = "Not connected to a device."
            return
        }

        diveViewModel.clear()
        downloadOutcome = nil
        bluetoothManager.isRetrievingLogs = true
        bluetoothManager.currentRetrievalDevice = peripheral

        DiveLogRetriever.retrieveDiveLogs(
            from: devicePtr,
            device: peripheral,
            viewModel: diveViewModel,
            bluetoothManager: bluetoothManager,
            onProgress: { current, _ in
                DispatchQueue.main.async {
                    // Once downloadOutcome is set, the download is over --
                    // ignore any straggling progress tick so it can't flip
                    // diveViewModel.progress back to .inProgress (see the
                    // comment on downloadOutcome's declaration).
                    guard downloadOutcome == nil else { return }
                    diveViewModel.updateProgress(count: current)
                }
            },
            completion: { success in
                DispatchQueue.main.async {
                    bluetoothManager.clearRetrievalState()
                    // Read diveViewModel.progress exactly once here to
                    // capture the library's terminal state. This is safe
                    // (not racy) because the library sets that state via a
                    // nested DispatchQueue.main.async call from within the
                    // same outer completion block, textually before it
                    // calls our completion closure -- both dispatches land
                    // on the main queue FIFO, so that state mutation is
                    // guaranteed to have already run by the time we get here.
                    switch diveViewModel.progress {
                    case .noNewDives:
                        downloadOutcome = .noNewDives
                    case .failed(let message):
                        downloadOutcome = .failed(message)
                    default:
                        downloadOutcome = success ? .success : .failed("Download failed. Please try again.")
                    }
                    if success {
                        selectedDiveIDs = Set(diveViewModel.dives.map(\.id))
                    }
                }
            }
        )
    }

    // MARK: - Import into the app's Dive Log

    private func importSelectedDives() {
        let deviceName = connectedPeripheral?.name ?? "dive computer"
        var imported = 0
        var skipped = 0
        var importedIDs: [UUID] = []

        // Resolved once per import batch, keyed on the paired peripheral's
        // stable identifier (not its display name, which can be nil/generic
        // or shared across two units of the same model) -- see
        // AppStore.resolveDiveComputer for why this matters for Statistics.
        let diveComputerID: UUID? = connectedPeripheral.map { peripheral in
            store.resolveDiveComputer(matchKey: peripheral.identifier.uuidString, detectedModelName: peripheral.name ?? "Dive Computer")
        }

        for dive in diveViewModel.dives where selectedDiveIDs.contains(dive.id) {
            // Skip dives that look like they're already in the log (same
            // start time, within a minute -- device clocks are exact to the
            // second, but this leaves room for clock drift).
            let alreadyExists = store.diveLogEntries.contains { existing in
                abs(existing.date.timeIntervalSince(dive.datetime)) < 60
            }
            if alreadyExists {
                skipped += 1
                continue
            }

            var entry = DiveImportMapping.entry(from: dive, deviceName: deviceName)
            entry.sourceDeviceID = diveComputerID
            store.addDiveLogEntry(entry)
            importedIDs.append(entry.id)
            imported += 1
        }

        var summary = "Imported \(imported) dive\(imported == 1 ? "" : "s")."
        if skipped > 0 {
            summary += " Skipped \(skipped) already in your log."
        }
        importSummary = summary
        selectedDiveIDs = []

        if imported > 0 {
            Task { await assignSuggestedLocations(for: importedIDs) }
        }
    }

    /// For each freshly-imported entry that has GPS data but no Location
    /// assigned yet, reverse-geocodes the coordinates and auto-creates/
    /// matches a Location by that name (see `AppStore.addLocation(name:
    /// latitude:longitude:)`, which dedupes by name). This is a batch
    /// import screen, so there's no natural single-dive review step to ask
    /// "does this look right?" for each one the way the Garmin screen
    /// does -- this stays a quiet, best-effort convenience rather than an
    /// interactive prompt, and the user can always rename or reassign the
    /// Location afterward from the Dive Log entry or Locations screen.
    private func assignSuggestedLocations(for entryIDs: [UUID]) async {
        for id in entryIDs {
            guard let entry = store.diveLogEntries.first(where: { $0.id == id }),
                  entry.locationID == nil,
                  let lat = entry.gpsLatitude, let lon = entry.gpsLongitude,
                  let name = await LocationSuggestion.suggestName(latitude: lat, longitude: lon)
            else { continue }
            guard let locationID = store.addLocation(name: name, latitude: lat, longitude: lon) else { continue }
            if let idx = store.diveLogEntries.firstIndex(where: { $0.id == id }) {
                store.diveLogEntries[idx].locationID = locationID
            }
        }
    }
}

/// Maps a LibDCSwift `DiveData` (from a BLE dive computer download) into a
/// DiveCheck `DiveLogEntry`. Depth and temperature are left in the metric
/// units libdivecomputer reports them in (meters / Celsius) rather than
/// converted, so the numbers on screen always match what the dive computer
/// itself recorded -- the entry's unit fields are set to match.
enum DiveImportMapping {
    static func entry(from dive: DiveData, deviceName: String) -> DiveLogEntry {
        var entry = DiveLogEntry(
            date: dive.datetime,
            diveType: diveType(for: dive),
            durationMinutes: String(Int((dive.divetime / 60).rounded())),
            depthUnit: .meters,
            maxDepth: String(format: "%.1f", dive.maxDepth),
            averageDepth: String(format: "%.1f", dive.avgDepth),
            temperatureUnit: .celsius,
            waterTemperature: String(format: "%.1f", dive.temperature),
            airTemperature: dive.surfaceTemperature.map { String(format: "%.1f", $0) } ?? ""
        )
        entry.sourceDevice = deviceName

        if entry.diveType == .closedCircuit {
            if let setpoint = dive.setpoint {
                let formatted = String(format: "%.2f", setpoint)
                entry.gasDetails.o2SetpointHigh = formatted
                entry.gasDetails.o2SetpointLow = formatted
            }
            if let diluent = dive.gasMixes?.first {
                entry.gasDetails.diluent = "\(Int((diluent.oxygen * 100).rounded()))%"
            }
        } else {
            if let primary = dive.gasMixes?.first {
                let o2 = Int((primary.oxygen * 100).rounded())
                let he = Int((primary.helium * 100).rounded())
                entry.gasDetails.gasMix = he > 0 ? "\(he)/\(o2) Trimix" : "\(o2)% O2"
            }
            if let tanks = dive.tanks, !tanks.isEmpty {
                entry.gasDetails.cylinderConfig = "\(tanks.count) tank\(tanks.count == 1 ? "" : "s")"
                let first = tanks[0]
                if first.beginPressure > 0 {
                    entry.gasDetails.startPressure = String(Int((first.beginPressure * 14.5038).rounded()))
                }
                if first.endPressure > 0 {
                    entry.gasDetails.endPressure = String(Int((first.endPressure * 14.5038).rounded()))
                }
                if tanks.count > 1 {
                    entry.gasDetails.additionalCylinders = tanks.dropFirst().map { tank in
                        String(format: "%.0f -> %.0f psi", tank.beginPressure * 14.5038, tank.endPressure * 14.5038)
                    }.joined(separator: "; ")
                }
            }
        }

        var notes = "Imported via Bluetooth from \(deviceName)."
        if let location = dive.location {
            notes += String(format: " GPS: %.4f, %.4f", location.latitude, location.longitude)
            entry.gpsLatitude = location.latitude
            entry.gpsLongitude = location.longitude
        }
        entry.notes = notes

        return entry
    }

    private static func diveType(for dive: DiveData) -> DiveLogType {
        // `DiveData.DiveMode` doesn't conform to Equatable, so this checks
        // the case with pattern matching (`if case`) rather than `==`.
        if case .closedCircuit = dive.diveMode {
            return .closedCircuit
        }
        if case .semiClosedCircuit = dive.diveMode {
            return .closedCircuit
        }
        let tankCount = dive.tanks?.count ?? dive.gasMixCount ?? 1
        return tankCount > 1 ? .technical : .openCircuit
    }
}

#Preview {
    NavigationStack {
        BluetoothDiveImportView(store: AppStore())
    }
}
