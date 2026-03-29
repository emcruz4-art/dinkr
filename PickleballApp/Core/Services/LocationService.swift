import Foundation
import CoreLocation
import Observation

@Observable
final class LocationService: NSObject {
    var currentLocation: CLLocation? = nil
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var currentCity: String = "Austin, TX"
    var error: Error? = nil

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
    }

    func reverseGeocode(location: CLLocation) async -> String {
        let geocoder = CLGeocoder()
        guard let placemark = try? await geocoder.reverseGeocodeLocation(location).first else {
            return "Unknown Location"
        }
        let city = placemark.locality ?? ""
        let state = placemark.administrativeArea ?? ""
        return [city, state].filter { !$0.isEmpty }.joined(separator: ", ")
    }

    func distance(to coordinates: GeoPoint) -> CLLocationDistance? {
        guard let current = currentLocation else { return nil }
        let target = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        return current.distance(from: target)
    }

    func distanceString(to coordinates: GeoPoint) -> String? {
        guard let meters = distance(to: coordinates) else { return nil }
        let miles = meters / 1609.34
        if miles < 0.5 { return "< 0.5 mi" }
        if miles < 10 { return String(format: "%.1f mi", miles) }
        return String(format: "%.0f mi", miles)
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        Task { @MainActor in
            currentCity = await reverseGeocode(location: location)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            startUpdating()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error
    }
}
