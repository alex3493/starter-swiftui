//
//  ChatEditView.swift
//  Starter
//
//  Created by Alex on 31/3/24.
//

import SwiftUI

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

struct ChatEditView: View {
    @State var topic: String
    
    @StateObject var vm: EditChatViewModel
    
    init(topic: String, chatId: String) {
        self.topic = topic
        self._vm = StateObject(wrappedValue: EditChatViewModel(chatId: chatId))
    }
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            TextInputView(text: $topic, title: "Topic", placeholder: "Chat topic")
            Spacer()
            HStack {
                Button {
                    Task {
                        if let _ = try await vm.updateChat(topic: topic.trimmingCharacters(in: .whitespacesAndNewlines)) {
                            dismiss()
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text("Update")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 16))
                }
                .disabled(topic.trimmingCharacters(in: .whitespacesAndNewlines) == "")
                .padding()
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 3) {
                        Text("Cancel")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 16))
                }
                .padding()
            }
        }
        .padding()
    }
}

#Preview {
    ChatEditView(topic: "TEST", chatId: "fake_id")
}

