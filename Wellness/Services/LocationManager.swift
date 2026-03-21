//
//  LocationManager.swift
//  Wellness
//

import CoreLocation
import Foundation

@Observable final class LocationManager: NSObject, CLLocationManagerDelegate {

    /// Reverse-geocoded city name from GPS (e.g. "Austin"). Empty until permission granted.
    var city: String = ""
    /// Raw GPS coordinate. nil until permission granted and first fix received.
    var coordinate: CLLocationCoordinate2D? = nil
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager  = CLLocationManager()
    private var isGeocoding = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    /// Call when the Local tab is shown to trigger permission + location fetch.
    func requestLocationIfNeeded() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        coordinate = location.coordinate
        guard !isGeocoding else { return }
        isGeocoding = true
        
        Task { [weak self] in
            guard let self else { return }
            defer { self.isGeocoding = false }

            do {
                let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
                self.city = placemarks.first?.locality ?? ""
            } catch {
                self.city = ""
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isGeocoding = false
    }
}
