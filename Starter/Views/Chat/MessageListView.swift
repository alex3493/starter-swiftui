//
//  MessageListView.swift
//  Starter
//
//  Created by Alex on 31/3/24.
//

import SwiftUI

struct MessageListView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @StateObject private var vm: MessageListViewModel
    
    @State private var scrolledID: String? = nil
    
    @State var newMessage: String = ""
    @FocusState var messageInputFocused: Bool
    
    init(chat: Chat) {
        print("MessageListView init!")
        self._vm = .init(wrappedValue: MessageListViewModel(chatId: chat.id))
    }
    
    func scrollToLatest() {
        scrolledID = vm.messages.last?.id
        vm.unreadMessages = false
    }
    
    var currentUser: User? {
        authViewModel.currentUser
    }
    
    private func isOutgoing(message: ChatMessage) -> Bool {
        return message.user.id == currentUser?.id
    }
    
    var body: some View {
        VStack {
            let items = vm.messages.enumerated().map({ $0 })
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(items, id: \.element.id) { index, item in
                        HStack {
                            if currentUser?.id == item.user.id {
                                Spacer()
                            }
                            MessageView(index: index, item: item, isOutgoing: currentUser?.id == item.user.id, isSenderConnected: vm.chatMembers.contains(where: { $0.id == item.user.id }))
                                .id(item.id)
                                .task {
                                    do {
                                        try await vm.loadMoreMessagesIfRequired(index: index)
                                    } catch {
                                        print("DEBUG :: Error loading more messages: ", error.localizedDescription)
                                    }
                                }
                                .onAppear {
                                    if item.id == vm.messages.last?.id {
                                        vm.unreadMessages = false
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        newMessage = item.message
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                    
                                    if isOutgoing(message: item) {
                                        Button {
                                            Task {
                                                do {
                                                    try await vm.deleteMessage(message: item)
                                                } catch {
                                                    print("DEBUG :: Error deleting message: ", error.localizedDescription)
                                                }
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "minus.circle")
                                        }
                                    }
                                }
                            
                        }
                        
                        if currentUser?.id != item.user.id {
                            Spacer()
                        }
                    }
                    // TODO: We have to solve scrolling issue first!
//                    ForEach(vm.usersTyping, id: \.self) { user in
//                        UserTypingView(item: user)
//                    }
                    .padding(.trailing, 20)
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging) // TODO: check all-view...
            .scrollPosition(id: $scrolledID, anchor: .bottom)
            
            Spacer()
            
            if vm.unreadMessages {
                Button {
                    scrollToLatest()
                } label: {
                    Text("There are new messages")
                        .fontWeight(.bold)
                }
            }
            
            HStack {
                // TODO: close keyboard after submit... ?
                TextField("", text: $newMessage, prompt: Text("Message..."), axis: .vertical)
                    .focused($messageInputFocused)
                Button {
                    Task {
                        try await vm.addMessage(messageBody: newMessage)
                        newMessage = ""
                        messageInputFocused = false
                        // This is a workaround to avoid scroll flicker.
                        // TODO: check if we can make it better.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            scrollToLatest()
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Text("Send")
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 16))
                }
            }
            .padding(.top, 5)
        }
        .overlay(content: {
            if vm.dataLoading {
                ProgressView()
            }
        })
        .task {
            print("Message list view appeared!")
            vm.currentUser = currentUser
            
            await vm.loadMessages()
            scrollToLatest()
            
            vm.addSubscriber()
        }
        .onDisappear {
            print("Message list view disappeared!")
            vm.unsubscribeFromMessages()
        }
        //        .onChange(of: scrolledID) { oldValue, newValue in
        //            print("ScrollID changed: ", oldValue as Any, newValue as Any)
        //        }
        .onChange(of: vm.unreadMessages) { _, newValue in
            if newValue && (scrolledID == nil || scrolledID == vm.messages.last?.id) {
                scrollToLatest()
            }
        }
        .onChange(of: messageInputFocused) { _, newValue in
            vm.triggerTypingEvent(isTyping: newValue)
        }
    }
}

//#Preview {
//    MessageListView()
//}
