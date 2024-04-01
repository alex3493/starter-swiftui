//
//  ChatEditViewModel.swift
//  Starter
//
//  Created by Alex on 1/4/24.
//

import Foundation

@MainActor
class EditChatViewModel: ObservableObject {
    let chatId: String
    
    init(chatId: String) {
        self.chatId = chatId
    }
    
    func updateChat(topic: String) async throws -> Chat? {
        print("Updating chat: \(topic)")
        
        if let chat = try await ApiService.shared.updateChat(topic: topic, chatId: chatId) {
            print("Chat updated", chat)
            return chat
        } else {
            print("Couldn't update chat")
            return nil
        }
    }
}
