//
//  LocationManager.swift
//  Proxy
//
//  Hardcoded to LaSalle College, Montreal. No GPS.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject {
    // LaSalle College: 2000 Rue Sainte-Catherine O, Montréal, QC H3H 2T2
    static let defaultCoordinate = CLLocationCoordinate2D(latitude: 45.4916, longitude: -73.5818)

    // Everyone is always at LaSalle College
    @Published var userLocation: CLLocationCoordinate2D = LocationManager.defaultCoordinate
}
