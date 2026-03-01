import Foundation
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

class FirebaseService: ObservableObject {
    private let db = Firestore.firestore()

    @Published var currentUser: UserProfile?
    @Published var friends: [Friend] = []
    @Published var friendLocations: [FriendLocation] = []
    @Published var checkpoints: [Checkpoint] = []
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var isAuthenticated = false

    private var chatListener: ListenerRegistration?

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                if let user = user {
                    self?.fetchCurrentUser(userId: user.uid)
                    self?.fetchFriends()
                }
            }
        }
    }

    // MARK: - Auth

    func signUp(name: String, email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("Sign up error: \(error.localizedDescription)")
                return
            }
            guard let uid = result?.user.uid else { return }
            let profile: [String: Any] = [
                "name": name,
                "email": email,
                "latitude": 0.0,
                "longitude": 0.0,
                "lastUpdated": Timestamp(date: Date()),
                "points": 0
            ]
            self?.db.collection("users").document(uid).setData(profile) { error in
                if let error = error {
                    print("Profile creation error: \(error.localizedDescription)")
                }
            }
        }
    }

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                print("Sign in error: \(error.localizedDescription)")
            }
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
        currentUser = nil
        friends = []
        friendLocations = []
    }

    // MARK: - User Profile

    func fetchCurrentUser(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data(), error == nil else { return }
            DispatchQueue.main.async {
                self?.currentUser = UserProfile(
                    id: userId,
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    latitude: data["latitude"] as? Double ?? 0,
                    longitude: data["longitude"] as? Double ?? 0,
                    lastUpdated: (data["lastUpdated"] as? Timestamp)?.dateValue() ?? Date(),
                    points: data["points"] as? Int ?? 0
                )
            }
        }
    }

    func updateLocation(latitude: Double, longitude: Double) {
        guard let uid = currentUserId else { return }
        db.collection("users").document(uid).updateData([
            "latitude": latitude,
            "longitude": longitude,
            "lastUpdated": Timestamp(date: Date())
        ])
        DispatchQueue.main.async {
            self.currentUser?.latitude = latitude
            self.currentUser?.longitude = longitude
            self.currentUser?.lastUpdated = Date()
        }
    }

    // MARK: - Friends

    func fetchFriends() {
        guard let uid = currentUserId else { return }
        db.collection("users").document(uid).collection("friends").getDocuments { [weak self] snapshot, error in
            guard let docs = snapshot?.documents, error == nil else { return }
            DispatchQueue.main.async {
                self?.friends = docs.compactMap { doc in
                    let data = doc.data()
                    return Friend(
                        id: doc.documentID,
                        name: data["name"] as? String ?? "",
                        email: data["email"] as? String ?? ""
                    )
                }
            }
        }
    }

    func addFriend(email: String, completion: @escaping (Bool) -> Void) {
        guard let uid = currentUserId else {
            completion(false)
            return
        }
        // Find user by email
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { [weak self] snapshot, error in
            guard let doc = snapshot?.documents.first, error == nil else {
                completion(false)
                return
            }
            let friendId = doc.documentID
            let friendData = doc.data()

            // Don't add yourself
            if friendId == uid {
                completion(false)
                return
            }

            let friendEntry: [String: Any] = [
                "name": friendData["name"] as? String ?? "",
                "email": friendData["email"] as? String ?? ""
            ]
            self?.db.collection("users").document(uid).collection("friends").document(friendId).setData(friendEntry) { error in
                if error == nil {
                    self?.fetchFriends()
                }
                completion(error == nil)
            }
        }
    }

    func removeFriend(friendId: String) {
        guard let uid = currentUserId else { return }
        db.collection("users").document(uid).collection("friends").document(friendId).delete { [weak self] _ in
            self?.fetchFriends()
        }
    }

    func fetchFriendLocations() {
        let friendIds = friends.map { $0.id }
        guard !friendIds.isEmpty else {
            DispatchQueue.main.async { self.friendLocations = [] }
            return
        }

        // Firestore 'in' queries support max 10 items per batch
        let batches = stride(from: 0, to: friendIds.count, by: 10).map {
            Array(friendIds[$0..<min($0 + 10, friendIds.count)])
        }

        var allLocations: [FriendLocation] = []
        let group = DispatchGroup()

        for batch in batches {
            group.enter()
            db.collection("users").whereField(FieldPath.documentID(), in: batch).getDocuments { snapshot, _ in
                if let docs = snapshot?.documents {
                    let locations = docs.compactMap { doc -> FriendLocation? in
                        let data = doc.data()
                        let lat = data["latitude"] as? Double ?? 0
                        let lng = data["longitude"] as? Double ?? 0
                        guard lat != 0 || lng != 0 else { return nil }
                        return FriendLocation(
                            id: doc.documentID,
                            name: data["name"] as? String ?? "",
                            latitude: lat,
                            longitude: lng,
                            lastUpdated: (data["lastUpdated"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    }
                    allLocations.append(contentsOf: locations)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.friendLocations = allLocations
        }
    }

    // MARK: - Checkpoints

    func saveCheckpoint(_ checkpoint: Checkpoint) {
        let data: [String: Any] = [
            "name": checkpoint.name,
            "type": checkpoint.type,
            "latitude": checkpoint.latitude,
            "longitude": checkpoint.longitude,
            "question": checkpoint.question ?? NSNull(),
            "createdBy": checkpoint.createdBy ?? NSNull(),
            "createdByName": checkpoint.createdByName ?? NSNull()
        ]
        db.collection("checkpoints").document(checkpoint.id).setData(data, merge: true)
    }

    func fetchCheckpoint(id: String, completion: @escaping (Checkpoint?) -> Void) {
        db.collection("checkpoints").document(id).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else {
                completion(nil)
                return
            }
            let checkpoint = Checkpoint(
                id: id,
                name: data["name"] as? String ?? "",
                type: data["type"] as? String ?? "",
                latitude: data["latitude"] as? Double ?? 0,
                longitude: data["longitude"] as? Double ?? 0,
                question: data["question"] as? String,
                createdBy: data["createdBy"] as? String,
                createdByName: data["createdByName"] as? String
            )
            completion(checkpoint)
        }
    }

    func setCheckpointQuestion(checkpointId: String, question: String) {
        guard let uid = currentUserId, let name = currentUser?.name else { return }
        db.collection("checkpoints").document(checkpointId).updateData([
            "question": question,
            "createdBy": uid,
            "createdByName": name
        ])
        addPoints(amount: 5)
    }

    // MARK: - Chat

    func sendMessage(checkpointId: String, text: String) {
        guard let uid = currentUserId, let name = currentUser?.name else { return }
        let messageData: [String: Any] = [
            "userId": uid,
            "userName": name,
            "text": text,
            "timestamp": Timestamp(date: Date())
        ]
        db.collection("checkpoints").document(checkpointId).collection("messages").addDocument(data: messageData)
        addPoints(amount: 1)
    }

    func listenForMessages(checkpointId: String, onUpdate: @escaping ([ChatMessage]) -> Void) -> ListenerRegistration {
        return db.collection("checkpoints").document(checkpointId).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                let messages = docs.compactMap { doc -> ChatMessage? in
                    let data = doc.data()
                    return ChatMessage(
                        id: doc.documentID,
                        userId: data["userId"] as? String ?? "",
                        userName: data["userName"] as? String ?? "",
                        text: data["text"] as? String ?? "",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                DispatchQueue.main.async {
                    onUpdate(messages)
                }
            }
    }

    // MARK: - Points & Leaderboard

    func addPoints(amount: Int) {
        guard let uid = currentUserId else { return }
        db.collection("users").document(uid).updateData([
            "points": FieldValue.increment(Int64(amount))
        ])
        DispatchQueue.main.async {
            self.currentUser?.points += amount
        }
    }

    func fetchLeaderboard() {
        db.collection("users")
            .order(by: "points", descending: true)
            .limit(to: 50)
            .getDocuments { [weak self] snapshot, _ in
                guard let docs = snapshot?.documents else { return }
                DispatchQueue.main.async {
                    self?.leaderboard = docs.map { doc in
                        let data = doc.data()
                        return LeaderboardEntry(
                            id: doc.documentID,
                            name: data["name"] as? String ?? "Unknown",
                            points: data["points"] as? Int ?? 0
                        )
                    }
                }
            }
    }
}
