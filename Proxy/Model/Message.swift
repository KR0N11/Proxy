//
//  Message.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//
import Foundation
import FirebaseFirestore

struct Message: Identifiable {
    let id: String // Use the document ID or a UUID string
    let fromId: String
    let toId: String
    let text: String
    let timestamp: Date

    init(id: String, dict: [String: Any]) {
        self.id = id
        self.fromId = dict["fromId"] as? String ?? ""
        self.toId = dict["toId"] as? String ?? ""
        self.text = dict["text"] as? String ?? ""
        self.timestamp = (dict["timestamp"] as? Timestamp)?.dateValue() ?? Date()
    }
}
