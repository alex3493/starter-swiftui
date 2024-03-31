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
    }
}


//#Preview {
//    ChatListRowView()
//}
