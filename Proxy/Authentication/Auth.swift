//
//  AppViewModelAuth.swift
//  Proxy
//
//  Created by Kevin Alinazar on 2026-02-08.
//

import FirebaseAuth
import FirebaseFirestore

extension AppViewModel {

    // MARK: - Authentication

    func signIn(identifier: String, password: String) async {
        isLoading = true
        errorMessage = ""

        let cleanIdentifier = identifier
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        do {
            let emailToUse: String

            if cleanIdentifier.contains("@") {
                emailToUse = cleanIdentifier
            } else {
                emailToUse = try await fetchEmailFromUsername(cleanIdentifier)
            }

            let result = try await Auth.auth().signIn(
                withEmail: emailToUse,
                password: password
            )

            self.userSession = result.user
            fetchCurrentUser()

        } catch {
            self.errorMessage = "Username or email is incorrect."
        }

        isLoading = false
    }

    private func fetchEmailFromUsername(_ username: String) async throws -> String {
        let usernameLower = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let snapshot = try await Firestore.firestore()
            .collection("users")
            .whereField("username_lower", isEqualTo: usernameLower)
            .getDocuments()

        guard let doc = snapshot.documents.first,
              let email = doc["email"] as? String else {
            throw NSError(domain: "UsernameNotFound", code: 404)
        }

        return email
    }

    func signUp(email: String, password: String, username: String) async {
        isLoading = true
        errorMessage = ""

        let emailDisplay = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let usernameDisplay = username.trimmingCharacters(in: .whitespacesAndNewlines)

        let emailLower = emailDisplay.lowercased()
        let usernameLower = usernameDisplay.lowercased()


        guard !emailLower.isEmpty, !password.isEmpty, !usernameLower.isEmpty else {
            errorMessage = "Please fill in all fields."
            isLoading = false
            return
        }

        do {
            let db = Firestore.firestore()

            let usernameDocRef = db.collection("usernames").document(usernameLower)
            let usernameSnap = try await usernameDocRef.getDocument()

            if usernameSnap.exists {
                errorMessage = "Username has been taken."
                isLoading = false
                return
            }

            let result = try await Auth.auth().createUser(withEmail: emailLower, password: password)

            let uid = result.user.uid

            let userRef = db.collection("users").document(uid)

            let batch = db.batch()
            batch.setData(["uid": uid], forDocument: usernameDocRef)
            batch.setData([
                "uid": uid,
                "email": emailDisplay,
                "email_lower": emailLower,
                "username": usernameDisplay,
                "username_lower": usernameLower,
                "createdAt": Timestamp(date: Date())
            ], forDocument: userRef)

            do {
                try await batch.commit()
            } catch {
                try? await result.user.delete()
                throw error
            }

            self.userSession = result.user
            fetchCurrentUser()

        } catch {
            let nsError = error as NSError
            let code = AuthErrorCode(rawValue: nsError.code)

            if code == .emailAlreadyInUse {
                self.errorMessage = "Email has been taken."
            } else {
                self.errorMessage = error.localizedDescription
            }
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
}
