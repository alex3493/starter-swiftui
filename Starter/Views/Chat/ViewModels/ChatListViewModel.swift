//
//  ChatListViewModel.swift
//  Starter
//
//  Created by Alex on 31/3/24.
//

import Foundation
import Combine

class ChatListViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    
    var cancellables = Set<AnyCancellable>()
    
    let manager = PusherManager.shared
    
    @Published var dataLoading: Bool = false
    private (set) var totalItems: Int = 0
    private (set) var lastFetchedId: String? = nil
    let pageSize = 20
    
    var searchQuery: String = ""

    @MainActor
    public func addSubscribers() {
        addCreatedSubscriber(channelName: "private-chat.updates", eventName: "chat_created")
        addUpdatedSubscriber(channelName: "private-chat.updates", eventName: "chat_updated")
        addDeletedSubscriber(channelName: "private-chat.updates", eventName: "chat_deleted")
    }
    
    @MainActor
    func loadChats() async {
        dataLoading = true
        
        if let paginatedList = try? await ApiService.shared.getChatList(afterId: lastFetchedId, pageSize: pageSize, query: searchQuery) {
            totalItems = paginatedList.total
            lastFetchedId = paginatedList.items.last?.id
            
            chats.append(contentsOf: paginatedList.items)
            totalItems = paginatedList.total
            
            dataLoading = false
        } else {
            print("Couldn't load chat list")
            dataLoading = false
        }
    }
    
    // @MainActor
    public func prependNewChat(chat: Chat) {
        chats.insert(chat, at: 0)
    }
    
    @MainActor
    func loadMoreChatsIfRequired(index: Int) async throws {
        if chats.count < totalItems && chats.count == index + 1 {
            try await requestNextPage()
        }
    }
    
    @MainActor
    private func requestNextPage() async throws {
        
        print("Loading more data. After ID: ", lastFetchedId as Any)
        
        await loadChats()
    }
    
    @MainActor
    public func performSearch() async throws {
        print("Performing search for: \(searchQuery)")
        
        resetList()
        await loadChats()
    }
    
    @MainActor
    public func resetSearch() async throws {
        searchQuery = ""
        resetList()
        await loadChats()
    }
    
    @MainActor
    private func resetList() {
        chats = []
        totalItems = 0
        lastFetchedId = nil
    }
    
    init() {
        print("ChatListViewModel constructor!")
    }
    
    deinit {
        print("ChatListViewModel destructor!")
        disconnectAll()
    }
    
    private func addCreatedSubscriber(channelName: String, eventName: String) {
        if let subscriber = manager.getPublisher(channelName: channelName, eventName: eventName, as: Chat.self) {
            subscriber.sink { completion in
                //
            } receiveValue: { [weak self] value in
                // print("Chat created subscriber's value", value["data"] as Any)
                if let chat = value["data"] as? Chat {
                    // print("New chat added: ", chat)
                    self?.prependNewChat(chat: chat)
                }
            }
            .store(in: &cancellables)
        }
    }
    
    private func addUpdatedSubscriber(channelName: String, eventName: String) {
        if let subscriber = manager.getPublisher(channelName: channelName, eventName: eventName, as: Chat.self) {
            subscriber.sink { completion in
                //
            } receiveValue: { [weak self] value in
                // print("Chat updated subscriber's value", value["data"] as Any)
                if let chat = value["data"] as? Chat {
                    if let index = self?.chats.firstIndex(where: { item in
                        item.id == chat.id
                    }) {
                        self?.chats[index] = chat
                    }
                }
            }
            .store(in: &cancellables)
        }
    }
    
    private func addDeletedSubscriber(channelName: String, eventName: String) {
        if let subscriber = manager.getPublisher(channelName: channelName, eventName: eventName, as: ChatIdWrapper.self) {
            subscriber.sink { completion in
                //
            } receiveValue: { [weak self] value in
                // print("Chat deleted subscriber's value", value["data"] as Any)
                if let chatDeletedNotification = value["data"] as? ChatIdWrapper {
                    if let index = self?.chats.firstIndex(where: { item in
                        item.id == chatDeletedNotification.chatId
                    }) {
                        self?.chats.remove(at: index)
                    }
                    
                }
            }
            .store(in: &cancellables)
        }
    }
    
    func disconnectAll() {
        manager.disconnectAll()
    }
    
}
