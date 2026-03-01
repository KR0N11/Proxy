import Foundation
import CoreLocation

struct UserProfile: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var latitude: Double
    var longitude: Double
    var lastUpdated: Date
    var points: Int

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Friend: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var email: String
}

struct FriendLocation: Identifiable {
    var id: String
    var name: String
    var latitude: Double
    var longitude: Double
    var lastUpdated: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Checkpoint: Identifiable, Codable {
    var id: String
    var name: String
    var type: String // "school" or "park"
    var latitude: Double
    var longitude: Double
    var question: String?
    var createdBy: String?
    var createdByName: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct ChatMessage: Identifiable, Codable {
    var id: String
    var userId: String
    var userName: String
    var text: String
    var timestamp: Date
}

struct LeaderboardEntry: Identifiable {
    var id: String
    var name: String
    var points: Int
}
