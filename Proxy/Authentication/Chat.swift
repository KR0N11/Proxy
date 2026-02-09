//
//  Chat.swift
//  Proxy
//
//  Created by Kevin Alinazar on 2026-02-08.
//

import FirebaseFirestore

extension AppViewModel {

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
}
