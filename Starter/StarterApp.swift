//
//  StarterApp.swift
//  Starter
//
//  Created by Alex on 26/3/24.
//

import SwiftUI

@main
struct StarterApp: App {
    
    @StateObject var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .modifier(FeedbackViewModifier())
        }
    }
}
