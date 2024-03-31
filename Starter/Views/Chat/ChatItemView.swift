//
//  ChatItemView.swift
//  Starter
//
//  Created by Alex on 31/3/24.
//

import SwiftUI

import Combine

struct ChatItemView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @Environment(\.dismiss) var dismiss
    
    // Source of truth.
    let chat: Chat
    
    @State var chatDeleted: Bool = false

    let manager = PusherManager.shared

    @State var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack {
            if chatDeleted {
                // TODO: show custom text here - if a user leaves his own chat and there are no other chat members - we delete chat, so this is not a moderation effect. However, if the chat was deleted explicitly, we should should "moderator" alert...
                Text("Chat was deleted")
                Button {
                    dismiss()
                } label: {
                    Text("Return to chat list")
                }
            } else {
                Text("\(chat.users.count) user(s) connected")
                if isChatMember {
                    Button {
                        Task {
                            try await leaveChat()
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Text("Leave")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 16))
                    }
                    
                    Spacer()
                    
                    MessageListView(chat: chat)
                } else {
                    Button {
                        Task {
                            try await joinChat()
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Text("Join")
                                .fontWeight(.bold)
                        }
                        .font(.system(size: 16))
                    }
                    
                    Spacer()
                }
            }
        }
        .navigationTitle(chat.topic)
        .padding()
        .task {
            //
        }
        .onAppear {
            print("***** Chat view appeared!", chat.users.count)
            addSubscribers()
            
            print("+++++ Cancellables count on appear", cancellables.count)
        }
        .onDisappear {
            print("***** Chat view disappeared!")
            unsubscribeFromMessages()
            
            print("+++++ Cancellables count on disappear", cancellables.count)
        }
//        .onChange(of: chat) { oldValue, newValue in
//            print("***** Chat has changed!", oldValue.users.count, newValue.users.count)
//        }
    }
    
    var isChatMember: Bool {
        return authViewModel.currentUser != nil && chat.users.contains(where: { user in
            user.id == authViewModel.currentUser?.id
        })
    }
    
    func joinChat() async throws {
        if let _ = try await ApiService.shared.joinChat(chatId: chat.id) {
            //
        } else {
            print("DEBUG :: Error joining chat")
        }
    }
    
    func leaveChat() async throws {
        if let _ = try await ApiService.shared.leaveChat(chatId: chat.id) {
            //
        } else {
            print("DEBUG :: Error leaving chat")
        }
    }
    
    func addSubscribers() {
        let channelName = "private-chat.updates.\(chat.id)"
        
        if let deleteChatSubscriber = manager.getPublisher(channelName: channelName, eventName: "chat_deleted", as: ChatIdWrapper.self) {
            deleteChatSubscriber.sink { completion in
                //
            } receiveValue: { value in
                print("***** Chat deleted event subscriber's value", value)
                
                if let data = value["data"] as? ChatIdWrapper {
                    if data.chatId == "\(self.chat.id)" {
                        print("Deleted chat!")
                        self.chatDeleted = true
                    }
                }
            }
            .store(in: &cancellables)
        }
    }
    
    func unsubscribeFromMessages() {
        manager.disconnectChannel(channelName: "private-chat.updates.\(chat.id)")
    }
}


//#Preview {
//    ChatItemView()
//}
