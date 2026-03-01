//
//  Users.swift
//  Proxy
//
//  Created by Kevin Alinazar on 2026-02-08.
//

import FirebaseAuth
@preconcurrency import FirebaseFirestore

extension AppViewModel {

    // MARK: - User & Friends Data (Manual Mapping)

    func fetchCurrentUser() {
        guard let uid = userSession?.uid else { return }

        userListener = db.collection("users").document(uid).addSnapshotListener { snapshot, error in
            guard let document = snapshot, document.exists, let data = document.data() else { return }

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

            self.friends = snapshot.documents.compactMap { doc in
                AppUser(id: doc.documentID, dict: doc.data())
            }
        } catch {
            print("Error fetching friends: \(error)")
        }
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
}
