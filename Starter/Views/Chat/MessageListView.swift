//
//  MessageListView.swift
//  Starter
//
//  Created by Alex on 31/3/24.
//

import SwiftUI
import Combine

@MainActor
class MessageListViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var dataLoading = false
    
    private (set) var totalItems: Int = 0
    private (set) var lastFetchedId: String? = nil
    let pageSize = 10
    
    @Published var chatId: String
    
    @Published var unreadMessages: Bool = false
    
    @Published var chatMembers: [User] = []
    
    @Published var membersTypingIds: Set<String> = []
    
    let manager = PusherManager.shared
    
    var cancellables = Set<AnyCancellable>()
    
    var currentUser: User? = nil
    
    init(chatId: String) {
        self.chatId = chatId
    }
    
    func loadMessages() async {
        dataLoading = true
        
        if let paginatedList: PaginatedMessageList = try? await ApiService.shared.getMessageList(chatId: chatId, afterId: lastFetchedId, pageSize: pageSize) {
            totalItems = paginatedList.total
            lastFetchedId = paginatedList.items.first?.id
            
            messages.insert(contentsOf: paginatedList.items, at: 0)
            totalItems = paginatedList.total
            
            dataLoading = false
        } else {
            print("Couldn't load message list")
            dataLoading = false
        }
    }
    
    func addMessage(messageBody: String) async throws {
        dataLoading = true
        
        if let _ = try? await ApiService.shared.addMessage(chatId: chatId, message: messageBody) {
            // print("Message added ", message)
        } else {
            print("Couldn't add message")
        }
        
        dataLoading = false
    }
    
    func deleteMessage(message: ChatMessage) async throws {
        print("Deleting message: ", message)
        
        dataLoading = true
        
        try? await ApiService.shared.deleteMessage(messageId: message.id)
        
        dataLoading = false
    }
    
    func loadMoreMessagesIfRequired(index: Int) async throws {
        if messages.count < totalItems && index == 0 {
            try await requestNextPage()
        }
    }
    
    private func requestNextPage() async throws {
        
        print("Loading more data. After ID: ", lastFetchedId as Any)
        
        await loadMessages()
    }
    
    private func removeMessage(messageId: String) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages.remove(at: index)
            
            totalItems -= 1
            
            // TODO: not sure we need it.
            //            if lastFetchedId == messageId {
            //                print("Must update lastFetchedId \(lastFetchedId as Any)")
            //                lastFetchedId = messages.first?.id
            //                print("Updated lastFetchedId: \(lastFetchedId as Any)")
            //            }
        }
    }
    
    private func updateMessage(message: ChatMessage) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        }
    }
    
    func addSubscriber() {
        let channelName = "presence-chat.\(chatId)"
        
        if let subscriber = manager.getPublisher(channelName: channelName, eventName: "message_added", as: ChatMessage.self) {
            subscriber.sink { completion in
                //
            } receiveValue: { [weak self] value in
                // print("Messages subscriber's value", value)
                if let message = value["data"] as? ChatMessage {
                    self?.messages.append(message)
                    self?.totalItems += 1
                    
                    if message.user.id != self?.currentUser?.id {
                        self?.unreadMessages = true
                    }
                }
            }
            .store(in: &cancellables)
        }
        
        if let subscriber = manager.getPublisher(channelName: channelName, eventName: "message_updated", as: ChatMessage.self) {
            subscriber.sink { completion in
                //
            } receiveValue: { [weak self] value in
                // print("Messages subscriber's value", value)
                if let message = value["data"] as? ChatMessage {
                    print("Message updated event: ", message.id)
                    self?.updateMessage(message: message)
                }
            }
            .store(in: &cancellables)
        }
        
        if let subscriber = manager.getPublisher(channelName: channelName, eventName: "message_deleted", as: [String: String].self) {
            subscriber.sink { completion in
                //
            } receiveValue: { [weak self] value in
                // print("Messages subscriber's value", value)
                if let data = value["data"] as? [String: String], let messageId = data["messageId"] {
                    print("Message deleted event: ", messageId)
                    self?.removeMessage(messageId: messageId)
                }
            }
            .store(in: &cancellables)
        }
        
        if let presenceSubscriber = manager.channels[channelName]?.presencePublisher {
            presenceSubscriber.sink { completion in
                //
            } receiveValue: { [weak self] value in
                // print("Presence subscriber's value", value)
                
                let (event, data) = value
                
                switch event {
                case .connection:
                    // print("***** Connection event: ", data)
                    self?.chatMembers = data
                case .member_added:
                    // print("***** Member added event: ", data.first as Any)
                    if let user = data.first, self?.chatMembers.contains(where: { $0.id == user.id }) == false {
                        self?.chatMembers.append(user)
                    }
                case .member_removed:
                    // print("***** Member removed event: ", data.first as Any)
                    if let user = data.first, let index = self?.chatMembers.firstIndex(where: { $0.id == user.id }) {
                        self?.chatMembers.remove(at: index)
                        self?.membersTypingIds.remove(user.id)
                    }
                }
            }
            .store(in: &cancellables)
        }
        
        if let clientSubscriber = manager.getPublisher(channelName: channelName, eventName: "client-typing_message", as: [String: Bool].self) {
            clientSubscriber.sink { completion in
                //
            } receiveValue: { [weak self] value in
                // print("***** Client event subscriber's value", value)
                if let data = value["data"] as? [String: Bool],
                   let typing = data["typing"],
                   let presenceData = value["presence"] as? [String: Any] {
                    
                    if let me = presenceData["me"] as? [String: Any],
                       let id = me["id"] {
                        
                        var parsedId: String?
                        if id is Int {
                            parsedId = "\(id)"
                        } else {
                            parsedId = id as? String
                        }
                        if let id = parsedId {
                            if typing {
                                self?.membersTypingIds.insert(id)
                            } else {
                                self?.membersTypingIds.remove(id)
                            }
                        }
                    }
                }
            }
            .store(in: &cancellables)
        }
    }
    
    func unsubscribeFromMessages() {
        manager.disconnectChannel(channelName: "presence-chat.\(chatId)")
    }
    
    func triggerTypingEvent(isTyping: Bool) {
        manager.triggerClientEvent(channelName: "presence-chat.\(chatId)", eventName: "client-typing_message", data: ["typing": isTyping])
    }
    
    // TODO: this is reserved...
    var usersTyping: [User] {
        chatMembers.filter { membersTypingIds.contains($0.id) }
    }
}

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
