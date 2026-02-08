//
//  AppViewModel.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//
import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import CoreData

@MainActor
class AppViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: AppUser?
    @Published var friends: [AppUser] = []
    @Published var allUsers: [AppUser] = []
    @Published var chatMessages: [Message] = []
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    private var db = Firestore.firestore()
    private var userListener: ListenerRegistration?
    private let viewContext = PersistenceController.shared.container.viewContext
    
    init() {

        self.userSession = Auth.auth().currentUser
        if userSession != nil {
            fetchCurrentUser()
        }
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = ""
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.userSession = result.user
            fetchCurrentUser()
        } catch {
            self.errorMessage = "Login failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func signUp(email: String, password: String, username: String) async {
        isLoading = true
        errorMessage = ""
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            
            // Using UUID string for the document data as requested
            let userData: [String: Any] = [
                "userUUID": UUID().uuidString,
                "email": email,
                "username": username,
                "profilePicURL": "",
                "friendIDs": [],
                "pendingRequests": []
            ]
            
            // Save initial data to Firestore
            try await db.collection("users").document(result.user.uid).setData(userData)
            
            // Initialize local user with the manual dictionary
            self.currentUser = AppUser(id: result.user.uid, dict: userData)
            
            if let user = self.currentUser {
                saveUserToCoreData(user: user)
            }
            
            fetchCurrentUser()
        } catch {
            self.errorMessage = "Signup failed: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        userListener?.remove()
        self.userSession = nil
        self.currentUser = nil
        self.friends = []
        self.chatMessages = []
    }
    
    // MARK: - User & Friends Data (Manual Mapping)
    
    func fetchCurrentUser() {
        guard let uid = userSession?.uid else { return }
        
        // Use Snapshot Listener for real-time updates
        userListener = db.collection("users").document(uid).addSnapshotListener { snapshot, error in
            guard let document = snapshot, document.exists, let data = document.data() else { return }
            
            // Manual mapping to AppUser struct using the document ID (UUID)
            self.currentUser = AppUser(id: document.documentID, dict: data)
            
            if let user = self.currentUser {
                self.saveUserToCoreData(user: user)
                if !user.friendIDs.isEmpty {
                    Task { await self.fetchFriends(ids: user.friendIDs) }
                } else {
                    self.friends = []
                }
            }
        }
    }
    
    func fetchFriends(ids: [String]) async {
        guard !ids.isEmpty else {
            self.friends = []
            return
        }
        
        do {
            let snapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: ids)
                .getDocuments()
            
            // Map document list to AppUser objects
            self.friends = snapshot.documents.compactMap { doc in
                AppUser(id: doc.documentID, dict: doc.data())
            }
        } catch {
            print("Error fetching friends: \(error)")
        }
    }
    
    // MARK: - Friends Logic FIXED
    func sendFriendRequest(to targetEmail: String) async {
        guard let myID = currentUser?.id else { return }
        
        do {
           
            let querySnapshot = try await db.collection("users")
                .whereField("email", isEqualTo: targetEmail)
                .getDocuments()
            
            guard let document = querySnapshot.documents.first else {
                errorMessage = "User with email \(targetEmail) not found."
                return
            }
            
            let targetID = document.documentID

            try await db.collection("users").document(targetID).updateData([
                "pendingRequests": FieldValue.arrayUnion([myID])
            ])
            print("DEBUG: Request Sent to \(targetID)")
            
        } catch {
            errorMessage = "Failed: \(error.localizedDescription)"
        }
    }

    func acceptFriendRequest(from requesterID: String) async {
        guard let myID = currentUser?.id else { return }
        
        let batch = db.batch()
        let myRef = db.collection("users").document(myID)
        let requesterRef = db.collection("users").document(requesterID)

        batch.updateData([
            "friendIDs": FieldValue.arrayUnion([requesterID]),
            "pendingRequests": FieldValue.arrayRemove([requesterID])
        ], forDocument: myRef)

        batch.updateData([
            "friendIDs": FieldValue.arrayUnion([myID])
        ], forDocument: requesterRef)
        
        do {
            try await batch.commit()
        } catch {
            print("DEBUG: Error accepting request")
        }
    }
    
    func rejectFriendRequest(from requesterID: String) async {
            guard let myID = currentUser?.id else { return }
            try? await db.collection("users").document(myID).updateData([
                "pendingRequests": FieldValue.arrayRemove([requesterID])
            ])
        }
    // MARK: - Chat Logic (Manual Mapping)
    
    func fetchMessages(for user: AppUser) {
        guard let myId = currentUser?.id else { return }
        let partnerId = user.id
        
        db.collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let allMessages = documents.compactMap { Message(id: $0.documentID, dict: $0.data()) }

                self.chatMessages = allMessages.filter { msg in
                    return (msg.fromId == myId && msg.toId == partnerId) ||
                           (msg.fromId == partnerId && msg.toId == myId)
                }
            }
    }
    
    func sendMessage(text: String, toUser: AppUser) {
        guard let fromId = currentUser?.id else { return }
        
        let messageData: [String: Any] = [
            "fromId": fromId,
            "toId": toUser.id,
            "text": text,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("messages").addDocument(data: messageData)
    }
    
    // MARK: - Profile Update
    
    func updateProfilePic(url: String) async {
        guard let uid = currentUser?.id else { return }
        do {
            try await db.collection("users").document(uid).updateData(["profilePicURL": url])
        } catch {
            errorMessage = "Failed to update photo."
        }
    }
    
    // MARK: - CoreData Sync
    
    private func saveUserToCoreData(user: AppUser) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CachedUser")
    
        request.predicate = NSPredicate(format: "id == %@", user.id)
        
        do {
            let results = try viewContext.fetch(request)
            let cachedUser = results.first ?? NSEntityDescription.insertNewObject(forEntityName: "CachedUser", into: viewContext)
            
            cachedUser.setValue(user.id, forKey: "id")
            cachedUser.setValue(user.username, forKey: "username")
            cachedUser.setValue(user.profilePicURL, forKey: "profilePicURL")
            
            try viewContext.save()
        } catch {
            print("CoreData Error: \(error)")
        }
    }
}
