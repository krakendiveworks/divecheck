import Foundation
import CoreLocation

/// Turns a dive computer's raw GPS coordinates into a human-readable
/// suggested Location name via Apple's reverse geocoder, so imported dives
/// can offer to create/assign a matching Location instead of staying
/// unassigned. Used by both the Bluetooth and Garmin import screens. This
/// is a one-off geocoding lookup, not device location tracking, so it
/// doesn't need location permission.
enum LocationSuggestion {
    /// Reverse-geocodes to a short display name, e.g. "Molasses Reef" or
    /// "Key Largo, FL" -- returns nil if the lookup fails or there's no
    /// network available. Import always succeeds either way; this is purely
    /// a convenience suggestion layered on top.
    static func suggestName(latitude: Double, longitude: Double) async -> String? {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        let geocoder = CLGeocoder()
        let placemarks: [CLPlacemark]? = await withCheckedContinuation { continuation in
            geocoder.reverseGeocodeLocation(location) { placemarks, _ in
                continuation.resume(returning: placemarks)
            }
        }
        guard let placemark = placemarks?.first else { return nil }

        // Prefer a named point of interest/body of water (e.g. "Molasses
        // Reef") over the generic locality when one's available.
        if let name = placemark.name, !name.isEmpty, name != placemark.locality {
            return name
        }
        let parts = [placemark.locality, placemark.administrativeArea ?? placemark.country].compactMap { $0 }
        return parts.isEmpty ? placemark.country : parts.joined(separator: ", ")
    }
}

/// Fetches the device's current coordinates once, for "Use My Current
/// Location" buttons (e.g. pinning a Location while standing at the dive
/// site). Requests when-in-use permission on first use.
@MainActor
final class CurrentLocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestCurrentLocation() async -> CLLocationCoordinate2D? {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            let status = manager.authorizationStatus
            switch status {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            default:
                self.continuation = nil
                continuation.resume(returning: nil)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                self.continuation?.resume(returning: nil)
                self.continuation = nil
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.continuation?.resume(returning: locations.first?.coordinate)
            self.continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.continuation?.resume(returning: nil)
            self.continuation = nil
        }
    }
}
