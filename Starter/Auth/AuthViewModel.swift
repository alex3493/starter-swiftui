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
    
    let feedbackService = FeedbackAlertService.shared
    
    @Published var currentUser: User?
    
    @Published var currentUserDevices: [UserDevice]?
    
    init() {
        Task {
            await fetchUser()
        }
    }
    
    func register(name: String, email: String, password: String, passwordConfirmation: String) async {
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
        
        feedbackService.showConfirmationView(withTitle: nil, confirmButtonText: "Sign Out", dismissButtonText: "Stay Connected", callback: {
            Task {
                do {
                    try await self.authManager.logout()
                    
                    self.currentUser = nil
                } catch {
                    print("DEBUG :: Logout error", error.localizedDescription)
                }
            }

        })
        
//        do {
//            // try await authManager.logout()
//            
//            // self.currentUser = nil
//        } catch {
//            print("DEBUG :: Logout error", error.localizedDescription)
//        }
    }
    
    func deleteAccount() async {
        guard currentUser != nil else { return }
        
        feedbackService.showConfirmationView(withTitle: "This action cannot be undone", confirmButtonText: "Delete Account", dismissButtonText: "Keep Account", callback: {
            Task {
                do {
                    try await self.authManager.deleteAccount()
                    
                    self.currentUser = nil
                } catch {
                    print("DEBUG :: Delete account error", error.localizedDescription)
                }
            }

        })
        
//        do {
//            try await authManager.deleteAccount()
//            
//            self.currentUser = nil
//        } catch {
//            print("DEBUG :: Delete account error", error.localizedDescription)
//        }
    }
    
    // TODO: make profile and password update function return a "success" boolean.
    func updateProfile(name: String, email: String) async throws {
        do {
            try await authManager.updateProfile(name: name, email: email)
            
            await fetchUser()
        } catch AppError.profileUpdateError(let message) {
            print("DEBUG :: Update profile error", message ?? "")
            
            errorService.showProfileUpdateAlertView(withMessage: message)
            
            throw AppError.profileUpdateError(message: message)
        } catch {
            print("DEBUG :: Update profile error", error.localizedDescription)
            
            throw error
        }
    }
    
    func updatePassword(currentPassword: String, newPassword: String, newPasswordConfirmation: String) async throws {
        do {
            try await authManager.updatePassword(currentPassword: currentPassword, newPassword: newPassword, newPasswordConfirmation: newPasswordConfirmation)
            
            await fetchUser()
        } catch AppError.passwordUpdateError(let message) {
            print("DEBUG :: Update password error", message ?? "")
            
            errorService.showPasswordUpdateAlertView(withMessage: message)
            
            throw AppError.passwordUpdateError(message: message)
        } catch {
            print("DEBUG :: Update password error", error.localizedDescription)

            throw error
        }
    }
    
    func fetchUser() async {
        currentUser = try? await authManager.fetchUser()
    }
    
    func fetchUserDevices() async throws {
        currentUserDevices = try await authManager.fetchUserDevices()
    }
}
