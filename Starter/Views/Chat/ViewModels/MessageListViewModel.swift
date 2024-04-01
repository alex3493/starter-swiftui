//
//  MessageListViewModel.swift
//  Starter
//
//  Created by Alex on 1/4/24.
//

import Foundation
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
