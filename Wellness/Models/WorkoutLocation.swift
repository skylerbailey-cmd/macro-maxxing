//
//  WorkoutLocation.swift
//  Wellness
//
//  Lightweight, transport-agnostic representation of the gym or place
//  a user tags when logging a workout. Kept deliberately flat so it can
//  be stored as flat fields in Firestore (`gymName`, `gymAddress`,
//  `gymLatitude`, `gymLongitude`) and mirrored into SwiftData models
//  that can't nest structs the same way.
//

import CoreLocation
import Foundation

struct WorkoutLocation: Codable, Hashable {
    /// Human-readable name of the place (e.g. "Gold's Gym - Downtown").
    var name:      String
    /// Optional street/full address returned by MapKit; empty string when unknown.
    var address:   String
    var latitude:  Double
    var longitude: Double

    init(name: String, address: String = "", latitude: Double, longitude: Double) {
        self.name      = name
        self.address   = address
        self.latitude  = latitude
        self.longitude = longitude
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Whether the location has meaningful content. Used as the
    /// "is tagged?" check across the app, since we mirror this struct as
    /// flat fields and can't rely on `== nil`.
    var isValid: Bool {
        !name.isEmpty && (latitude != 0 || longitude != 0)
    }
}
