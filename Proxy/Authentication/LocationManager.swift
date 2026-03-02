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

    // Location is OFF by default — starts at Montreal LaSalle College
    @Published var ghostMode: Bool = true {
        didSet {
            if ghostMode {
                manager.stopUpdatingLocation()
                userLocation = LocationManager.defaultCoordinate
            } else {
                // Only request permission when user actively turns on location
                requestPermissionAndStart()
            }
        }
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10
        // Start in ghost mode — default to LaSalle College
        userLocation = LocationManager.defaultCoordinate
    }

    func requestPermissionAndStart() {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
        } else {
            manager.requestWhenInUseAuthorization()
        }
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        if !ghostMode {
            manager.startUpdatingLocation()
        }
    }

    func stopTracking() {
        manager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !ghostMode, let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
        }
        // Only start tracking if user has turned off ghost mode
        if !ghostMode {
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
