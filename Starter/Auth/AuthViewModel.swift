//
//  AuthViewModel.swift
//  Starter
//
//  Created by Alex on 28/3/24.
//

import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    
    let authManager = AuthService.shared
    
    let errorService = ErrorService.shared
    
    @Published var currentUser: User?
    
    @Published var currentUserDevices: [UserDevice]?
    
    init() {
        Task {
            await fetchUser()
        }
    }
    
    func register(name: String, email: String, password: String, passwordConfirmation: String) async throws {
        do {
            try await authManager.register(name: name, email: email, password: password, password_confirmation: passwordConfirmation)
            
            currentUser = try await authManager.fetchUser()
        } catch AppError.registrationError(let message) {
            print("DEBUG :: Registration error", message ?? "")
            
            errorService.showRegistrationAlertView(withMessage: message)
        } catch {
            print("DEBUG :: Registration error", error.localizedDescription)
        }
    }
    
    func signIn(email: String, password: String) async {
        do {
            try await authManager.login(email: email, password: password)
            
            currentUser = try await authManager.fetchUser()
        } catch AppError.loginError(let message) {
            print("DEBUG :: Login error", message ?? "")
            
            errorService.showLoginAlertView(withMessage: message)
        } catch {
            print("DEBUG :: Login error", error.localizedDescription)
        }
        
    }
    
    func signOut() async {
        guard currentUser != nil else { return }
        
        do {
            try await authManager.logout()
            
            self.currentUser = nil
        } catch {
            print("DEBUG :: Logout error", error.localizedDescription)
        }
    }
    
    func deleteAccount() async {
        guard currentUser != nil else { return }
        
        do {
            try await authManager.deleteAccount()
            
            self.currentUser = nil
        } catch {
            print("DEBUG :: Logout error", error.localizedDescription)
        }
    }
    
    func updateProfile(name: String, email: String, newPassword: String, currentPassword: String) async -> Bool {
        do {
            try await authManager.updateProfile(name: name, email: email, currentPassword: currentPassword, newPassword: newPassword)
            
            await fetchUser()
        } catch {
            print("DEBUG :: Update profile error", error.localizedDescription)
            return false
        }
        
        return true
    }
    
    func fetchUser() async {
        currentUser = try? await authManager.fetchUser()
    }
    
    func fetchUserDevices() async throws {
        currentUserDevices = try await authManager.fetchUserDevices()
    }
}
