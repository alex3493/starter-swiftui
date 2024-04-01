//
//  ChatListView.swift
//  Starter
//
//  Created by Alex on 28/3/24.
//

import SwiftUI

struct ChatListView: View {
    @StateObject var vm = ChatListViewModel()
    
    @State private var scrolledID: String? = nil
    
    @State private var searchIsActive = false
    
    func resetScroll() {
        scrolledID = vm.chats.first?.id
    }
    
    var body: some View {
        NavigationStack {
            let items = vm.chats.enumerated().map({ $0 })
            ScrollView {
                // TODO: in lazy-loading views we shouldn't use navigationDestination.
                // LazyVStack {
                VStack {
                    ForEach(items, id: \.element.id) { index, item in
                        ChatListRowView(item: item)
                            .id(item.id)
                            .task {
                                do {
                                    try await vm.loadMoreChatsIfRequired(index: index)
                                } catch {
                                    print("DEBUG :: Error loading more chats: ", error.localizedDescription)
                                }
                            }
                    }
                }
                // TODO: this modifier doesn't work.
                // We had to change LazyVStack to VStack in order to avoid compiler warnings...
                // Check modifier version below...
//                .navigationDestination(for: Chat.self) { chat in
//                    ChatEditView(topic: chat.topic, chatId: chat.id)
//                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrolledID)
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading, content: {
                    NavigationLink {
                        ChatCreateView()
                            .navigationTitle("New chat")
                            .navigationBarBackButtonHidden()
                    } label: {
                        HStack {
                            Text("Create chat")
                            Spacer()
                            Image(systemName: "plus")
                                .font(.headline)
                        }
                    }
                })
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        ProfileView()
                            .navigationTitle("Profile")
                    } label: {
                        Image(systemName: "gear")
                            .font(.headline)
                    }
                }
            }
            .searchable(text: $vm.searchQuery, isPresented: $searchIsActive, prompt: "Search...")
            .onChange(of: searchIsActive) {
                if !searchIsActive {
                    Task {
                        try await vm.resetSearch()
                    }
                }
            }
            .onSubmit(of: .search) {
                Task {
                    try await vm.performSearch()
                }
            }
        }
        .overlay(content: {
            if vm.dataLoading {
                ProgressView()
            }
        })
        .task {
            print("Home view appeared!")
            await vm.loadChats()
            
            vm.addSubscribers()
        }
        .onDisappear {
            print("Home view disappeared!")
        }
    }
}

#Preview {
    ChatListView()
}
