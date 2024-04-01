//
//  ChatMessage.swift
//  Starter
//
//  Created by Alex on 31/3/24.
//

import Foundation
struct ChatMessage: Codable, Identifiable {
    let id: String
    let message: String
    let createdAt: Date?
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case id
        case message
        case createdAt = "created_at"
        case user
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // We support both integer and string id.
        if let intId = try? values.decode(Int.self, forKey: .id) {
            id = "\(intId)"
        } else {
            id = try values.decode(String.self, forKey: .id)
        }
        message = try values.decode(String.self, forKey: .message)
        user = try values.decode(User.self, forKey: .user)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        
        let dateString: String? = try? values.decode(String.self, forKey: .createdAt)
        if let dateString = dateString {
            createdAt = formatter.date(from: dateString)
        } else {
            createdAt = nil
        }
    }
    
}
