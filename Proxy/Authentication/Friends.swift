//
//  Friends.swift
//  Proxy
//
//  Created by Kevin Alinazar on 2026-02-08.
//

import FirebaseFirestore

extension AppViewModel {

    // MARK: - Friends Logic

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
}
