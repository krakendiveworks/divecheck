import Foundation

/// A saved dive computer -- the thing that actually distinguishes two
/// physical units so imports from each show up separately in Statistics'
/// "By Dive Computer" breakdown, even if they're the same model (e.g. two
/// Petrel 3s) or the raw name the device reports over Bluetooth/in a .fit
/// file is generic or missing.
///
/// `matchKey` is what makes this work: a stable per-device identifier
/// captured at import time -- the paired CBPeripheral's `identifier` (a
/// UUID stable for this iOS install) for Bluetooth imports, or the FIT
/// file's device serial number for Garmin imports -- rather than the
/// device's display name, which can collide across units or come back
/// nil/generic. `name` is what actually shows up in the UI and is fully
/// user-editable, defaulting to the detected model name the first time a
/// given `matchKey` is seen (see `AppStore.resolveDiveComputer(matchKey:
/// detectedModelName:)`).
struct DiveComputer: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    /// The model name/BLE name detected the first time this computer was
    /// imported from, kept around for reference even after the user
    /// renames it (e.g. to tell two same-model units apart at a glance).
    var detectedModelName: String
    var matchKey: String

    init(id: UUID = UUID(), name: String, detectedModelName: String, matchKey: String) {
        self.id = id
        self.name = name
        self.detectedModelName = detectedModelName
        self.matchKey = matchKey
    }
}
