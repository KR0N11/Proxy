//
//  AppUser.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//

import FirebaseFirestore

struct AppUser: Identifiable {
    let id: String
    var email: String
    var username: String
    var profilePicURL: String
    var friendIDs: [String]
    var pendingRequests: [String]
    var latitude: Double
    var longitude: Double
    var lastLocationUpdate: Date?
    var points: Int

    // Manual Dictionary Initializer to fix the compiler errors
    init(id: String, dict: [String: Any]) {
        self.id = id
        self.email = dict["email"] as? String ?? ""
        self.username = dict["username"] as? String ?? ""
        self.profilePicURL = dict["profilePicURL"] as? String ?? ""
        self.friendIDs = dict["friendIDs"] as? [String] ?? []
        self.pendingRequests = dict["pendingRequests"] as? [String] ?? []
        self.latitude = dict["latitude"] as? Double ?? 0.0
        self.longitude = dict["longitude"] as? Double ?? 0.0
        if let ts = dict["lastLocationUpdate"] as? FirebaseFirestore.Timestamp {
            self.lastLocationUpdate = ts.dateValue()
        } else {
            self.lastLocationUpdate = nil
        }
        self.points = dict["points"] as? Int ?? 0
    }
}
