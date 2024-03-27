//
//  User.swift
//  Starter
//
//  Created by Alex on 27/3/24.
//

import Foundation

struct User: Codable, Hashable, Identifiable {
    let id: String
    let email: String
    let name: String
    let dateCreated: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case dateCreated = "created_at"
    }
    
    init(
        id: String,
        email: String,
        dateCreated: Date?,
        name: String
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.dateCreated = dateCreated ?? Date()
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        // We support both integer and string id.
        if let intId = try? values.decode(Int.self, forKey: .id) {
            id = "\(intId)"
        } else {
            id = try values.decode(String.self, forKey: .id)
        }
        
        email = try values.decode(String.self, forKey: .email)
        name = try values.decode(String.self, forKey: .name)
        
        // Date decoding requires some extra work.
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        
        let dateString: String = try values.decode(String.self, forKey: .dateCreated)
        dateCreated = formatter.date(from: dateString)
    }
}

extension User {
    /// Presentation only - show user name initials.
    var initials: String {
        let parts = name.split(separator: " ")
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .filter { !$0.isEmpty }
        
        return parts.map({ $0.prefix(1) }).joined()
    }
}
