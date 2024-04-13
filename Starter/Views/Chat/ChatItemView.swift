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
    
    let manager = PusherManager.shared
    
    @State var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        VStack {
            VStack {
                ForEach(showUsers, id: \.self) { user in
                    HStack {
                        Text(user.name)
                        Spacer()
                    }
                }
            }
            if showMoreUsersCount > 0 {
                HStack {
                    Text("... and \(showMoreUsersCount) more")
                    Spacer()
                }
            }
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
        .navigationTitle(chat.topic)
        .padding()
        .task {
            //
        }
        .onAppear {
            print("***** Chat view appeared!", chat.users.count)
            addSubscribers()
        }
        .onDisappear {
            print("***** Chat view disappeared!")
            unsubscribeFromMessages()
        }
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
                        
                        FeedbackAlertService.shared.showAlertView(withTitle: "Chat deleted", withMessage: "Chat is not available any more")
                        dismiss()
                    }
                }
            }
            .store(in: &cancellables)
        }
    }
    
    func unsubscribeFromMessages() {
        manager.disconnectChannel(channelName: "private-chat.updates.\(chat.id)")
    }
    
    var showUsers: ArraySlice<User> {
        if chat.users.count > 3 {
            return chat.users[..<3]
        } else {
            return chat.users[...]
        }
    }
    
    var showMoreUsersCount: Int {
        return chat.users.count - 3
    }
}

struct ChatItemView_Previews: PreviewProvider {
    static let users: [User] = [
        User(id: "1", email: "User 1", dateCreated: Date(), name: "Name 1"),
        User(id: "2", email: "User 2", dateCreated: Date(), name: "Name 2"),
        User(id: "3", email: "User 3", dateCreated: Date(), name: "Name 3"),
        User(id: "4", email: "User 4", dateCreated: Date(), name: "Name 4")
    ]
    static let chat = Chat(id: "1", topic: "Topic 1", createdAt: Date(), users: users)
    
    static var authViewModel = AuthViewModel()
    
    static var previews: some View {
        ChatItemView(chat: chat)
            .id(chat.id)
            .environmentObject(authViewModel)
    }
}
