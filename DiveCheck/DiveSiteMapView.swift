import SwiftUI
import MapKit

/// A pin for either a Location or one of its Dive Sites, whichever has
/// coordinates set.
private struct MapPin: Identifiable {
    enum Kind {
        case location(UUID)
        case diveSite(locationID: UUID)
    }

    let id: String
    let title: String
    let coordinate: CLLocationCoordinate2D
    let kind: Kind
}

/// Computes a region that frames every pin, used to seed the map's initial
/// camera position/region so it doesn't default to a hardcoded spot on the
/// globe. Shared by both map implementations below.
private func framingRegion(for pins: [MapPin]) -> MKCoordinateRegion? {
    guard !pins.isEmpty else { return nil }
    let latitudes = pins.map { $0.coordinate.latitude }
    let longitudes = pins.map { $0.coordinate.longitude }
    guard let minLat = latitudes.min(), let maxLat = latitudes.max(),
          let minLon = longitudes.min(), let maxLon = longitudes.max()
    else { return nil }
    let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
    let span = MKCoordinateSpan(
        latitudeDelta: max(0.5, (maxLat - minLat) * 1.6),
        longitudeDelta: max(0.5, (maxLon - minLon) * 1.6)
    )
    return MKCoordinateRegion(center: center, span: span)
}

/// Shows every saved Location/Dive Site that has coordinates as a pin on a
/// map. Coordinates come from either a reverse-geocoded dive computer
/// import or from manually setting them in LocationDetailView -- Locations
/// added by name alone (the common case) simply don't show up here.
///
/// The actual map rendering is split into two sibling views -- LegacyPinMap
/// (iOS 16's region-based Map API) and ModernPinMap (iOS 17's
/// MapContentBuilder-based Map(position:)/Annotation API) -- picked at
/// runtime via `#available`, so the app keeps iOS 16 support without
/// carrying a deprecation warning on newer OS versions.
struct DiveSiteMapView: View {
    @ObservedObject var store: AppStore
    @Binding var path: [ChecklistRoute]

    private var pins: [MapPin] {
        var result: [MapPin] = []
        for location in store.savedLocations {
            if let lat = location.latitude, let lon = location.longitude {
                result.append(MapPin(
                    id: "loc-\(location.id)",
                    title: location.name,
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    kind: .location(location.id)
                ))
            }
            for site in location.diveSites {
                if let lat = site.latitude, let lon = site.longitude {
                    result.append(MapPin(
                        id: "site-\(site.id)",
                        title: "\(site.name) — \(location.name)",
                        coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                        kind: .diveSite(locationID: location.id)
                    ))
                }
            }
        }
        return result
    }

    var body: some View {
        Group {
            if pins.isEmpty {
                ContentUnavailableFallback()
            } else if #available(iOS 17.0, *) {
                ModernPinMap(pins: pins, path: $path)
            } else {
                LegacyPinMap(pins: pins, path: $path)
            }
        }
        .navigationTitle("Dive Site Map")
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// iOS 16-compatible map. `Map(coordinateRegion:annotationItems:...)` and
/// `MapAnnotation` were deprecated in iOS 17, but they're still the only
/// option available pre-17, so this stays in place rather than being
/// removed -- see ModernPinMap below for the iOS 17+ replacement. The
private struct LegacyPinMap: View {
    let pins: [MapPin]
    @Binding var path: [ChecklistRoute]
    @State private var region: MKCoordinateRegion

    init(pins: [MapPin], path: Binding<[ChecklistRoute]>) {
        self.pins = pins
        self._path = path
        self._region = State(initialValue: framingRegion(for: pins) ?? MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 25.0, longitude: -80.0),
            span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
        ))
    }

    // `@available(deprecated:)` here (rather than on the whole struct)
    // tells the compiler this deprecated-API usage is intentional (kept
    // only for pre-17 devices, never reached at runtime on 17+ since
    // DiveSiteMapView picks ModernPinMap there instead), so it doesn't
    // warn about it on every build -- scoped to just `body` so
    // *instantiating* LegacyPinMap from DiveSiteMapView's `else` branch
    // above doesn't itself pick up a new deprecation warning too.
    @available(iOS, deprecated: 17.0, message: "Intentionally kept for pre-iOS 17 devices -- see ModernPinMap for the iOS 17+ replacement actually used there.")
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: pins) { pin in
            MapAnnotation(coordinate: pin.coordinate) {
                pinButton(for: pin)
            }
        }
    }

    private func pinButton(for pin: MapPin) -> some View {
        Button {
            switch pin.kind {
            case .location(let id), .diveSite(let id):
                path.append(.locationDetail(id))
            }
        } label: {
            PinLabel(title: pin.title)
        }
    }
}

/// iOS 17+ map using the modern MapContentBuilder-based API
/// (`Map(position:)` / `Annotation`), which is what `LegacyPinMap` above
/// would otherwise show a deprecation warning for using.
@available(iOS 17.0, *)
private struct ModernPinMap: View {
    let pins: [MapPin]
    @Binding var path: [ChecklistRoute]
    @State private var cameraPosition: MapCameraPosition

    init(pins: [MapPin], path: Binding<[ChecklistRoute]>) {
        self.pins = pins
        self._path = path
        if let region = framingRegion(for: pins) {
            self._cameraPosition = State(initialValue: .region(region))
        } else {
            self._cameraPosition = State(initialValue: .automatic)
        }
    }

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(pins) { pin in
                Annotation(pin.title, coordinate: pin.coordinate) {
                    Button {
                        switch pin.kind {
                        case .location(let id), .diveSite(let id):
                            path.append(.locationDetail(id))
                        }
                    } label: {
                        PinLabel(title: pin.title)
                    }
                }
            }
        }
    }
}

/// Shared pin visual for both map implementations.
private struct PinLabel: View {
    let title: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundStyle(.red)
            Text(title)
                .font(.caption2)
                .padding(.horizontal, 4)
                .background(.thinMaterial, in: Capsule())
        }
    }
}

/// Empty state, kept as its own view so the Group's ViewBuilder body above
/// doesn't have to mix map content and plain text in the same branch.
private struct ContentUnavailableFallback: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "map")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No mapped locations yet")
                .font(.headline)
            Text("Locations get a pin once they have coordinates -- set one manually from a Location's detail screen, or accept a suggested Location the next time you import a dive with GPS data.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

#Preview {
    NavigationStack {
        DiveSiteMapView(store: AppStore(), path: .constant([]))
    }
}
