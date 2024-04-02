//
//  Chat.swift
//  Starter
//
//  Created by Alex on 31/3/24.
//

import Foundation

struct Chat: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let topic: String
    let createdAt: Date?
    let users: [User]
    
    enum CodingKeys: String, CodingKey {
        case id
        case topic
        case createdAt = "created_at"
        case users
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // We support both integer and string id.
        if let intId = try? values.decode(Int.self, forKey: .id) {
            id = "\(intId)"
        } else {
            id = try values.decode(String.self, forKey: .id)
        }
        topic = try values.decode(String.self, forKey: .topic)
        users = try values.decode([User].self, forKey: .users)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        
        let dateString: String? = try? values.decode(String.self, forKey: .createdAt)
        if let dateString = dateString {
            createdAt = formatter.date(from: dateString)
        } else {
            createdAt = nil
        }
    }
    
    init(id: String, topic: String, createdAt: Date?, users: [User]) {
        self.id = id
        self.topic = topic
        self.createdAt = createdAt
        self.users = users
    }
    
}

struct ChatIdWrapper: Codable {
    let chatId: String
    
    enum CodingKeys: String, CodingKey {
        case chatId
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // We support both integer and string id.
        if let intId = try? values.decode(Int.self, forKey: .chatId) {
            chatId = "\(intId)"
        } else {
            chatId = try values.decode(String.self, forKey: .chatId)
        }
    }
}
