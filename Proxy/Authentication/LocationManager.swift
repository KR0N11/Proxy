//
//  LocationManager.swift
//  Proxy
//
//  Location tracking wrapper using CLLocationManager.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    // LaSalle College: 2000 Rue Sainte-Catherine O, Montréal, QC H3H 2T2
    static let defaultCoordinate = CLLocationCoordinate2D(latitude: 45.4916, longitude: -73.5818)

    @Published var userLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    // Location is completely OFF by default — always Montreal
    @Published var useCurrentLocation: Bool = false {
        didSet {
            if useCurrentLocation {
                requestPermissionAndStart()
            } else {
                manager.stopUpdatingLocation()
                userLocation = LocationManager.defaultCoordinate
            }
        }
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        // Always start at Montreal LaSalle College
        userLocation = LocationManager.defaultCoordinate
    }

    private func requestPermissionAndStart() {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        } else {
            manager.requestWhenInUseAuthorization()
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard useCurrentLocation, let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
        if useCurrentLocation {
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.startUpdatingLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
