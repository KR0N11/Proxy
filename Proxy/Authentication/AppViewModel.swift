//
//  AppsViewModel.swift
//  Proxy
//
//  Created by Kevin Alinazar on 2026-02-08.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreData
import Combine

@MainActor
class AppViewModel: ObservableObject {

    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: AppUser?
    @Published var friends: [AppUser] = []
    @Published var allUsers: [AppUser] = []
    @Published var chatMessages: [Message] = []

    // Map & Location
    @Published var checkpoints: [Checkpoint] = []
    @Published var checkpointMessages: [CheckpointMessage] = []
    @Published var leaderboard: [AppUser] = []

    @Published var isLoading = false
    @Published var errorMessage = ""

    // NOTE: must NOT be private anymore (separate files need access)
    var db = Firestore.firestore()
    var userListener: ListenerRegistration?
    var checkpointChatListener: ListenerRegistration?
    let viewContext = PersistenceController.shared.container.viewContext

    init() {
        self.userSession = Auth.auth().currentUser
        if userSession != nil {
            fetchCurrentUser()
        }
    }
}
