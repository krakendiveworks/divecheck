import Foundation

enum DiveLogType: String, Codable, CaseIterable, Identifiable {
    case openCircuit = "Open Circuit"
    case closedCircuit = "Closed Circuit"
    case technical = "Technical"

    var id: String { rawValue }
}

enum WaterType: String, Codable, CaseIterable, Identifiable {
    case salt = "Salt"
    case fresh = "Fresh"

    var id: String { rawValue }
}

enum DiveEntryType: String, Codable, CaseIterable, Identifiable {
    case shore = "Shore"
    case boat = "Boat"
    case dock = "Dock"
    case boatRamp = "Boat Ramp"

    var id: String { rawValue }
}

enum DepthUnit: String, Codable, CaseIterable, Identifiable {
    case feet = "ft"
    case meters = "m"

    var id: String { rawValue }
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable {
    case lbs = "lbs"
    case kg = "kg"

    var id: String { rawValue }
}

enum SiteType: String, Codable, CaseIterable, Identifiable {
    case reef = "Reef"
    case wreck = "Wreck"
    case wall = "Wall"
    case quarry = "Quarry"
    case seaGrass = "Sea Grass"
    case lake = "Lake"
    case cave = "Cave"
    case cavern = "Cavern"
    case kelpForest = "Kelp Forest"
    case muckSand = "Muck / Sand"
    case artificialReef = "Artificial Reef"
    case river = "River"
    case springCenote = "Spring / Cenote"
    case pierJetty = "Pier / Jetty"
    case driftDive = "Drift Dive"
    case iceDive = "Ice Dive"
    case openWater = "Open Water / Blue Water"
    case other = "Other"

    var id: String { rawValue }
}

enum TemperatureUnit: String, Codable, CaseIterable, Identifiable {
    case fahrenheit = "°F"
    case celsius = "°C"

    var id: String { rawValue }
}

/// Surface conditions on top of the water (distinct from underwater
/// visibility).
enum WaterSurfaceCondition: String, Codable, CaseIterable, Identifiable {
    case calm = "Calm"
    case wavelets = "Wavelets"
    case chop = "Chop"
    case surge = "Surge"
    case rough = "Rough"
    case veryRough = "Very Rough"

    var id: String { rawValue }
}

enum SkyCondition: String, Codable, CaseIterable, Identifiable {
    case sunny = "Sunny"
    case partlyCloudy = "Partly Cloudy"
    case cloudy = "Cloudy"
    case overcast = "Overcast"
    case rain = "Rain"

    var id: String { rawValue }
}

enum WindSpeedRange: String, Codable, CaseIterable, Identifiable {
    case calm = "Calm (0-5 kt)"
    case light = "Light (5-10 kt)"
    case moderate = "Moderate (10-15 kt)"
    case fresh = "Fresh (15-20 kt)"
    case strong = "Strong (20-25 kt)"
    case veryStrong = "Very Strong (25+ kt)"

    var id: String { rawValue }
}

/// The direction the wind is blowing toward (as requested), not the
/// meteorological "blowing from" convention.
enum WindDirection: String, Codable, CaseIterable, Identifiable {
    case n = "N"
    case ne = "NE"
    case e = "E"
    case se = "SE"
    case s = "S"
    case sw = "SW"
    case w = "W"
    case nw = "NW"

    var id: String { rawValue }
}

/// Gas/tank info. Open Circuit and Technical dives use the first group;
/// Closed Circuit dives use the setpoint/diluent/bailout group instead.
struct DiveGasDetails: Codable, Equatable {
    var gasMix: String = ""
    var cylinderConfig: String = ""
    var startPressure: String = ""
    var endPressure: String = ""
    var additionalCylinders: String = ""
    var o2SetpointHigh: String = ""
    var o2SetpointLow: String = ""
    var diluent: String = ""
    var bailoutGas: String = ""
    /// Optional (Codable-safe for already-persisted entries) tank capacity
    /// and service/fill pressure, used only to auto-calculate SAC/RMV from
    /// start/end pressure + average depth + duration -- see
    /// SACCalculation.swift. Blank unless the diver fills them in.
    var tankSizeCuFt: String?
    var servicePressurePsi: String?
}

struct DiveLogEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var date: Date
    var diveType: DiveLogType
    /// Legacy free-text location, kept only so entries saved before the
    /// structured Locations feature still show something -- new/edited
    /// entries use `locationID`/`diveSiteID` instead (see SavedLocation.swift).
    var location: String
    /// References a SavedLocation in AppStore.savedLocations. nil if this
    /// entry hasn't been assigned a structured Location yet.
    var locationID: UUID?
    /// References a DiveSite nested under the SavedLocation above. nil if
    /// no specific site was picked (just the general Location).
    var diveSiteID: UUID?
    var siteType: SiteType?
    var entryType: DiveEntryType?
    var durationMinutes: String
    var depthUnit: DepthUnit
    var maxDepth: String
    var averageDepth: String
    var temperatureUnit: TemperatureUnit
    var waterTemperature: String
    var airTemperature: String
    var waterSurfaceCondition: WaterSurfaceCondition?
    var skyCondition: SkyCondition?
    var windSpeedRange: WindSpeedRange?
    var windDirection: WindDirection?
    var visibility: String
    var waterType: WaterType
    var weightUsed: String
    var weightUnit: WeightUnit
    var buddyIDs: [UUID]
    var gasDetails: DiveGasDetails
    var sacRate: String
    var rmvRate: String
    var equipmentUsedIDs: [UUID]
    var rating: Int?
    var notes: String
    /// Set the first time the user taps Save, and updated on every
    /// subsequent Save tap. Saving never locks the entry — it stays fully
    /// editable, same as a saved checklist snapshot.
    var savedAt: Date?
    /// The dive computer this entry was downloaded from (e.g. "Petrel 3"),
    /// set by the Bluetooth/Garmin import mappings. nil for manually-logged
    /// entries and for anything imported before this field existed. Used by
    /// Statistics' "dive time by computer" breakdown.
    var sourceDevice: String?
    /// References a DiveComputer in AppStore.diveComputers -- the actual
    /// source of truth for "which computer" once one's been resolved (see
    /// AppStore.resolveDiveComputer), since it's keyed on a stable hardware
    /// identifier rather than the display name `sourceDevice` holds. nil
    /// for entries imported before DiveComputer records existed, or
    /// hand-logged dives that haven't had one assigned.
    var sourceDeviceID: UUID?
    /// Raw GPS coordinates from a Bluetooth/Garmin import, when the dive
    /// computer reported one -- used to suggest/create a matching Location
    /// via reverse geocoding and to show a pin on the Dive Site Map. nil
    /// for manually-logged entries or computers that don't report GPS.
    var gpsLatitude: Double?
    var gpsLongitude: Double?
    /// Filenames (not full paths -- see PhotoStorage.swift) of photos
    /// attached to this dive, stored as separate files in Documents rather
    /// than embedded here so they don't bloat every JSON encode/decode of
    /// the whole Dive Log or eat into CloudSync's iCloud budget. Optional
    /// rather than defaulting to `[]` so already-persisted entries without
    /// this key still decode.
    var photoFilenames: [String]?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        diveType: DiveLogType = .openCircuit,
        location: String = "",
        locationID: UUID? = nil,
        diveSiteID: UUID? = nil,
        siteType: SiteType? = nil,
        entryType: DiveEntryType? = nil,
        durationMinutes: String = "",
        depthUnit: DepthUnit = .feet,
        maxDepth: String = "",
        averageDepth: String = "",
        temperatureUnit: TemperatureUnit = .fahrenheit,
        waterTemperature: String = "",
        airTemperature: String = "",
        waterSurfaceCondition: WaterSurfaceCondition? = nil,
        skyCondition: SkyCondition? = nil,
        windSpeedRange: WindSpeedRange? = nil,
        windDirection: WindDirection? = nil,
        visibility: String = "",
        waterType: WaterType = .salt,
        weightUsed: String = "",
        weightUnit: WeightUnit = .lbs,
        buddyIDs: [UUID] = [],
        gasDetails: DiveGasDetails = DiveGasDetails(),
        sacRate: String = "",
        rmvRate: String = "",
        equipmentUsedIDs: [UUID] = [],
        rating: Int? = nil,
        notes: String = "",
        savedAt: Date? = nil,
        sourceDevice: String? = nil,
        sourceDeviceID: UUID? = nil,
        gpsLatitude: Double? = nil,
        gpsLongitude: Double? = nil,
        photoFilenames: [String]? = nil
    ) {
        self.id = id
        self.date = date
        self.diveType = diveType
        self.location = location
        self.locationID = locationID
        self.diveSiteID = diveSiteID
        self.siteType = siteType
        self.entryType = entryType
        self.durationMinutes = durationMinutes
        self.depthUnit = depthUnit
        self.maxDepth = maxDepth
        self.averageDepth = averageDepth
        self.temperatureUnit = temperatureUnit
        self.waterTemperature = waterTemperature
        self.airTemperature = airTemperature
        self.waterSurfaceCondition = waterSurfaceCondition
        self.skyCondition = skyCondition
        self.windSpeedRange = windSpeedRange
        self.windDirection = windDirection
        self.visibility = visibility
        self.waterType = waterType
        self.weightUsed = weightUsed
        self.weightUnit = weightUnit
        self.buddyIDs = buddyIDs
        self.gasDetails = gasDetails
        self.sacRate = sacRate
        self.rmvRate = rmvRate
        self.equipmentUsedIDs = equipmentUsedIDs
        self.rating = rating
        self.notes = notes
        self.savedAt = savedAt
        self.sourceDevice = sourceDevice
        self.sourceDeviceID = sourceDeviceID
        self.gpsLatitude = gpsLatitude
        self.gpsLongitude = gpsLongitude
        self.photoFilenames = photoFilenames
    }
}
