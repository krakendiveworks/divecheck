import Foundation

/// A named dive site within a Location (e.g. "Molasses Reef" within "Key
/// Largo, FL"). Locations can hold any number of these.
struct DiveSite: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    /// Optional coordinates for the Dive Site Map -- set either manually in
    /// LocationDetailView or automatically the first time a dive computer
    /// import with GPS data gets matched to this site.
    var latitude: Double?
    var longitude: Double?

    init(id: UUID = UUID(), name: String, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// A dive location the user has entered before, offered as a quick pick the
/// next time they log a dive. Holds any number of named Dive Sites
/// underneath it (e.g. "Key Largo, FL" containing "Molasses Reef",
/// "Christ of the Abyss", etc.) so a place that's dived repeatedly doesn't
/// need to be re-typed for every distinct site.
struct SavedLocation: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var diveSites: [DiveSite]
    /// Optional coordinates for the Dive Site Map, for the Location as a
    /// whole (e.g. the general area of "Key Largo, FL") -- individual Dive
    /// Sites can have their own, more precise coordinates too.
    var latitude: Double?
    var longitude: Double?

    init(id: UUID = UUID(), name: String, diveSites: [DiveSite] = [], latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.name = name
        self.diveSites = diveSites
        self.latitude = latitude
        self.longitude = longitude
    }

    // Custom Codable so locations saved before `diveSites`/coordinates
    // existed (just an id + name) still decode cleanly instead of failing
    // to load -- a missing key just means "nothing set yet" rather than a
    // decode error.
    private enum CodingKeys: String, CodingKey {
        case id, name, diveSites, latitude, longitude
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        diveSites = try container.decodeIfPresent([DiveSite].self, forKey: .diveSites) ?? []
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
    }
}
