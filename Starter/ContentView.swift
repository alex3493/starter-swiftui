//
//  ContentView.swift
//  Starter
//
//  Created by Alex on 26/3/24.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State var userLoaded: Bool = false
    
    let pusherManager = PusherManager.shared
    
    var body: some View {
        
        Group {
            if authViewModel.currentUser != nil {
                ChatListView()
                    .task {
                        print("***** Configure pusher in content view ChatListView task")
                        pusherManager.configure()
                    }
            } else if userLoaded {
                LoginView()
            } else {
                ProgressView()
            }
            
            ZStack {
                Text("").modifier(ErrorAlertViewModifier())
                Text("").modifier(FeedbackAlertViewModifier())
                Text("").modifier(FeedbackConfirmationViewModifier())
            }.frame(width: 0, height: 0).opacity(0)
        }
        .task {
            do {
                let _ = try await authViewModel.authManager.fetchUser()
                userLoaded = true
            } catch {
                print("DEBUG :: Error loading user")
            }
        }
    }
}

#Preview {
    ContentView()
}
