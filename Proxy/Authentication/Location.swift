//
//  Location.swift
//  Proxy
//
//  Firebase location sync + checkpoint + points logic.
//

import FirebaseFirestore
import CoreLocation

extension AppViewModel {

    // MARK: - Upload my location to Firebase

    func updateMyLocation(latitude: Double, longitude: Double) async {
        guard let uid = currentUser?.id else { return }
        do {
            try await db.collection("users").document(uid).updateData([
                "latitude": latitude,
                "longitude": longitude,
                "lastLocationUpdate": FieldValue.serverTimestamp()
            ])
        } catch {
            print("Error updating location: \(error)")
        }
    }

    // MARK: - Fetch friends locations (re-fetches friend docs)

    func refreshFriendsLocations() async {
        guard let ids = currentUser?.friendIDs, !ids.isEmpty else { return }
        do {
            let snapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: ids)
                .getDocuments()
            self.friends = snapshot.documents.compactMap {
                AppUser(id: $0.documentID, dict: $0.data())
            }
        } catch {
            print("Error refreshing friend locations: \(error)")
        }
    }

    // MARK: - Checkpoints (community spots)

    func fetchNearbyCheckpoints(latitude: Double, longitude: Double) async {
        // Fetch all checkpoints from Firestore
        do {
            let snapshot = try await db.collection("checkpoints").getDocuments()
            self.checkpoints = snapshot.documents.compactMap { doc in
                Checkpoint(id: doc.documentID, dict: doc.data())
            }
        } catch {
            print("Error fetching checkpoints: \(error)")
        }
    }

    func createCheckpoint(name: String, type: String, latitude: Double, longitude: Double) async {
        let data: [String: Any] = [
            "name": name,
            "type": type,
            "latitude": latitude,
            "longitude": longitude,
            "createdAt": FieldValue.serverTimestamp()
        ]
        do {
            try await db.collection("checkpoints").addDocument(data: data)
        } catch {
            print("Error creating checkpoint: \(error)")
        }
    }

    // MARK: - Checkpoint Chat

    func fetchCheckpointMessages(checkpointId: String) {
        checkpointChatListener?.remove()
        checkpointChatListener = db.collection("checkpoints").document(checkpointId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let docs = snapshot?.documents else { return }
                self.checkpointMessages = docs.compactMap {
                    CheckpointMessage(id: $0.documentID, dict: $0.data())
                }
            }
    }

    func sendCheckpointMessage(checkpointId: String, text: String) async {
        guard let user = currentUser else { return }
        let data: [String: Any] = [
            "userId": user.id,
            "username": user.username,
            "text": text,
            "timestamp": FieldValue.serverTimestamp()
        ]
        do {
            try await db.collection("checkpoints").document(checkpointId)
                .collection("messages").addDocument(data: data)
            // Award a point for interacting
            await addPoints(userId: user.id, amount: 1)
        } catch {
            print("Error sending checkpoint message: \(error)")
        }
    }

    func setCheckpointQuestion(checkpointId: String, question: String) async {
        guard let user = currentUser else { return }
        do {
            try await db.collection("checkpoints").document(checkpointId).updateData([
                "question": question,
                "questionBy": user.id,
                "questionByUsername": user.username,
                "questionAt": FieldValue.serverTimestamp()
            ])
            await addPoints(userId: user.id, amount: 2)
        } catch {
            print("Error setting question: \(error)")
        }
    }

    // MARK: - Points

    func addPoints(userId: String, amount: Int) async {
        do {
            try await db.collection("users").document(userId).updateData([
                "points": FieldValue.increment(Int64(amount))
            ])
            // Update local if it's us
            if userId == currentUser?.id {
                currentUser?.points += amount
            }
        } catch {
            print("Error adding points: \(error)")
        }
    }

    func fetchLeaderboard() async {
        do {
            let snapshot = try await db.collection("users")
                .order(by: "points", descending: true)
                .limit(to: 20)
                .getDocuments()
            self.leaderboard = snapshot.documents.compactMap {
                AppUser(id: $0.documentID, dict: $0.data())
            }
        } catch {
            print("Error fetching leaderboard: \(error)")
        }
    }
}
