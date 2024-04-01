//
//  ChatCreateViewModel.swift
//  Starter
//
//  Created by Alex on 1/4/24.
//

import Foundation

@MainActor
class CreateChatViewModel: ObservableObject {
    func createChat(topic: String) async throws -> Chat? {
        print("Creating chat: \(topic)")
        
        if let chat = try await ApiService.shared.createChat(topic: topic) {
            print("Chat created", chat)
            return chat
        } else {
            print("Couldn't create chat")
            return nil
        }
    }
}
