//
//  AppUser.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//


struct AppUser: Identifiable {
    let id: String
    var email: String
    var username: String
    var profilePicURL: String
    var friendIDs: [String]
    var pendingRequests: [String]

    // Manual Dictionary Initializer to fix the compiler errors
    init(id: String, dict: [String: Any]) {
        self.id = id
        self.email = dict["email"] as? String ?? ""
        self.username = dict["username"] as? String ?? ""
        self.profilePicURL = dict["profilePicURL"] as? String ?? ""
        self.friendIDs = dict["friendIDs"] as? [String] ?? []
        self.pendingRequests = dict["pendingRequests"] as? [String] ?? []
    }
}
