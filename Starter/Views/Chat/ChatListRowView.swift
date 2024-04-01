//
//  ChatListRowView.swift
//  Starter
//
//  Created by Alex on 31/3/24.
//

import SwiftUI

struct ChatListRowView: View {
    let item: Chat
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showEditView = false
    
    var currentUser: User? {
        authViewModel.currentUser
    }
    
    var canEditChatTopic: Bool {
        item.users.first == authViewModel.currentUser
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(item.topic)
                HStack {
                    Text(item.createdAt?.formatted() ?? "")
                    if let user = item.users.first {
                        Text("- " + user.name)
                        if item.users.count > 1 {
                            Text("and \(item.users.count - 1) more...")
                        }
                    }
                }
            }
            Spacer()
            NavigationLink(destination: ChatItemView(chat: item)) {
                Image(systemName: "chevron.right")
            }
        }
        .contextMenu(canEditChatTopic ? ContextMenu {
            Button {
                showEditView = true
            } label: {
                Label("Edit topic", systemImage: "pencil")
            }
        } : nil)
        .padding()
        // TODO: we temporarily put navigationDestination on each item in list.
        .navigationDestination(isPresented: $showEditView) {
            ChatEditView(topic: item.topic, chatId: item.id)
        }
    }
}

struct ChatListRowView_Previews: PreviewProvider {
    static let users: [User] = [
        User(id: "1", email: "User 1", dateCreated: Date(), name: "Name 1"),
        User(id: "2", email: "User 2", dateCreated: Date(), name: "Name 2")
    ]
    static let chat = Chat(id: "1", topic: "Topic 1", createdAt: Date(), users: users)
    
    static var authViewModel = AuthViewModel()
    
    static var previews: some View {
        ChatListRowView(item: chat)
            .id(chat.id)
            .environmentObject(authViewModel)
    }
}

