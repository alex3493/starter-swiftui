//
//  ChatCreateView.swift
//  Starter
//
//  Created by Alex on 31/3/24.
//

import SwiftUI

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

struct ChatCreateView: View {
    @State var topic: String = ""
    
    @StateObject var vm = CreateChatViewModel()
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            TextInputView(text: $topic, title: "Topic", placeholder: "Chat topic")
            Spacer()
            HStack {
                Button {
                    Task {
                        if let _ = try await vm.createChat(topic: topic.trimmingCharacters(in: .whitespacesAndNewlines)) {
                            dismiss()
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text("Create")
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
    ChatCreateView()
}

