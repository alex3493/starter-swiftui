//
//  ChatListView.swift
//  Starter
//
//  Created by Alex on 28/3/24.
//

import SwiftUI

struct ChatListView: View {
    var body: some View {
        NavigationStack {
            Text("Chat list view goes here...")
                .toolbar {
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
        }
    }
}

#Preview {
    ChatListView()
}
