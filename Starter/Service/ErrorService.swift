//
//  ErrorService.swift
//  Starter
//
//  Created by Alex on 29/3/24.
//

import Foundation
import SwiftUI

enum AppError: LocalizedError {
    case loginError(message: String?)
    
    case registrationError(message: String?)
    
    case profileUpdateError(message: String?)
    
    case passwordUpdateError(message: String?)
    
    public var errorDescription: String? {
        switch self {
            
        case .loginError:
            return "Failed logging into account"
        case .registrationError:
            return "Failed registering new account"
        case .profileUpdateError:
            return "Failed updating user profile"
        case .passwordUpdateError:
            return "Failed updating password"
        }
    }
    
    public var failureReason: String? {
        switch self {
            
        case .loginError(let message):
            return message ?? "Entered email or password were incorrect"
        case .registrationError(let message):
            return message ?? "Email creating account"
        case .profileUpdateError(let message):
            return message ?? "Error trying to update user profile"
        case .passwordUpdateError(message: let message):
            return message ?? "Error trying to update password"
        }
    }
    
}

final class ErrorService: ObservableObject {
    static let shared = ErrorService()
    
    private init() { }
    
    @Published private(set) var activeError: AppError?
    
    var isPresentingAlert: Binding<Bool> {
        return Binding<Bool>(get: {
            return self.activeError != nil
        }, set: { newValue in
            guard !newValue else { return }
            self.activeError = nil
        })
    }
    
    func showLoginAlertView(withMessage message: String?) {
        activeError = AppError.loginError(message: message)
    }
    
    func showRegistrationAlertView(withMessage message: String?) {
        activeError = AppError.registrationError(message: message)
    }
    
    func showProfileUpdateAlertView(withMessage message: String?) {
        activeError = AppError.profileUpdateError(message: message)
    }
    
    func showPasswordUpdateAlertView(withMessage message: String?) {
        activeError = AppError.passwordUpdateError(message: message)
    }
    
}

