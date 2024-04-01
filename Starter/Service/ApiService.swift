//
//  ApiService.swift
//  Starter
//
//  Created by Alex on 31/3/24.
//

import Foundation
import UIKit

struct PaginatedChatList: Codable {
    let items: [Chat]
    let total: Int
}

struct PaginatedMessageList: Codable {
    let items: [ChatMessage]
    let total: Int
}

final class ApiService {
    
    static let shared = ApiService()
    private init() {}
    
    let chatListUrl = URL(string: "http://localhost/api/chats")!
    let createChatUrl = URL(string: "http://localhost/api/chats")!
    let updateChatUrlTemplate = "http://localhost/api/chat/{chatId}"
    let messageListUrlTemplate = "http://localhost/api/chat/{chatId}/messages"
    let addMessageUrlTemplate = "http://localhost/api/chat/{chatId}/messages"
    let deleteMessageUrlTemplate = "http://localhost/api/message/{messageId}"
    let joinChatUrlTemplate = "http://localhost/api/chat/{chatId}/join"
    let leaveChatUrlTemplate = "http://localhost/api/chat/{chatId}/leave"
    
    func prepareRequest(url: URL, method: String) -> URLRequest? {
        guard let authToken = KeychainService.shared.read(service: "access-token", account: "org.smartcalc.starter", type: AuthToken.self) else { return nil }
        
        var request = URLRequest(url: url)
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(authToken.token)", forHTTPHeaderField: "Authorization")
        
        request.httpMethod = method
        
        return request
    }
    
    public func getChatList(afterId: String?, pageSize: Int, query: String = "") async throws -> PaginatedChatList? {
        guard var request = prepareRequest(url: chatListUrl, method: "GET") else { return nil }
        
        if let afterId = afterId {
            request.url?.append(queryItems: [URLQueryItem(name: "afterId", value: String(afterId))])
        }
        request.url?.append(queryItems: [URLQueryItem(name: "perPage", value: String(pageSize))])
        
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if query != "" {
            request.url?.append(queryItems: [URLQueryItem(name: "query", value: String(query))])
        }
        
        print("Request chats from API", request.url as Any)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
//        let test = String(data: data, encoding: .utf8)
//        print(test as Any)
        
        do {
            return try JSONDecoder().decode(PaginatedChatList.self, from: data)
        } catch {
            print("DEBUG :: Chat list error", error.localizedDescription)
            
            return nil
        }
    }
    
    public func createChat(topic: String) async throws -> Chat? {
        guard let request = prepareRequest(url: createChatUrl, method: "POST") else { return nil }
        
        let body: [String: String] = ["topic": topic]
        let finalBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: finalBody)
            return try JSONDecoder().decode(Chat.self, from: data)
        } catch {
            print("DEBUG :: Error creating chat: ", error.localizedDescription)
            
            return nil
        }
    }
    
    public func updateChat(topic: String, chatId: String) async throws -> Chat? {
        let url = URL(string: updateChatUrlTemplate.replacingOccurrences(of: "{chatId}", with: chatId))!
        
        guard let request = prepareRequest(url: url, method: "PATCH") else { return nil }
        
        let body: [String: String] = ["topic": topic]
        let finalBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: finalBody)
            return try JSONDecoder().decode(Chat.self, from: data)
        } catch {
            print("DEBUG :: Error updating chat: ", error.localizedDescription)
            
            return nil
        }
    }
    
    public func joinChat(chatId: String) async throws -> Chat? {
        let url = URL(string: joinChatUrlTemplate.replacingOccurrences(of: "{chatId}", with: chatId))!
        
        guard let request = prepareRequest(url: url, method: "PUT") else { return nil }
        
        let body: [String: String] = [:]
        let finalBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: finalBody)
            
//            let test = String(data: data, encoding: .utf8)
//            print(test as Any)
            
            return try JSONDecoder().decode(Chat.self, from: data)
        } catch {
            print("DEBUG :: Error joining chat: ", error.localizedDescription)
            
            return nil
        }
    }
    
    public func leaveChat(chatId: String) async throws -> Chat? {
        let url = URL(string: leaveChatUrlTemplate.replacingOccurrences(of: "{chatId}", with: chatId))!
        
        guard let request = prepareRequest(url: url, method: "PUT") else { return nil }
        
        let body: [String: String] = [:]
        let finalBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: finalBody)
            
//            let test = String(data: data, encoding: .utf8)
//            print(test as Any)
            
            return try JSONDecoder().decode(Chat.self, from: data)
            
        } catch {
            print("DEBUG :: Error leaving chat: ", error.localizedDescription)
            
            return nil
        }
    }
    
    public func getMessageList(chatId: String, afterId: String?, pageSize: Int) async throws -> PaginatedMessageList? {
        let url = URL(string: messageListUrlTemplate.replacingOccurrences(of: "{chatId}", with: chatId))!
        
        guard var request = prepareRequest(url: url, method: "GET") else { return nil }
        
        if let afterId = afterId {
            request.url?.append(queryItems: [URLQueryItem(name: "afterId", value: String(afterId))])
        }
        request.url?.append(queryItems: [URLQueryItem(name: "perPage", value: String(pageSize))])
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
//        let test = String(data: data, encoding: .utf8)
//        print(test as Any)
        
        do {
            return try JSONDecoder().decode(PaginatedMessageList.self, from: data)
        } catch {
            print("DEBUG :: Chat message list error", error.localizedDescription)
            
            return nil
        }
    }
    
    public func addMessage(chatId: String, message: String) async throws -> ChatMessage? {
        let url = URL(string: addMessageUrlTemplate.replacingOccurrences(of: "{chatId}", with: chatId))!
        
        guard let request = prepareRequest(url: url, method: "POST") else { return nil }
        
        let body: [String: String] = ["message": message]
        let finalBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: finalBody)
            return try JSONDecoder().decode(ChatMessage.self, from: data)
        } catch {
            print("DEBUG :: Error adding message: ", error.localizedDescription)
            
            return nil
        }
    }
    
    public func deleteMessage(messageId: String) async throws {
        let url = URL(string: deleteMessageUrlTemplate.replacingOccurrences(of: "{messageId}", with: messageId))!
        
        guard let request = prepareRequest(url: url, method: "DELETE") else { return }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        if response.http?.statusCode != 200 {
            print("DEBUG :: Error deleting message ID \(messageId)")
        }
    }
}
