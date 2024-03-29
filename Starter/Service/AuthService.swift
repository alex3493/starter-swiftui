//
//  AuthService.swift
//  Starter
//
//  Created by Alex on 28/3/24.
//

import Foundation
import UIKit

extension URLResponse {
    /// Returns casted `HTTPURLResponse`
    var http: HTTPURLResponse? {
        return self as? HTTPURLResponse
    }
}

struct RegistrationResponse: Codable {
    let token: String?
    let message: String?
}

struct LoginResponse: Codable {
    let token: String?
    let message: String?
}

struct UpdateProfileResponse: Codable {
    let password_updated: Bool?
    let message: String?
}

struct AuthToken: Codable {
    let token: String
}

enum UpdateProfileError: Error {
    case genericError
    // TODO: reserved.
    case badEmail
    case incorrectPassword
}

final class AuthService: ObservableObject {
    
    static let shared = AuthService()
    private init() {}
    
    let registerUrl = URL(string: "http://sanctum-starter.local/api/registration")!
    let loginUrl = URL(string: "http://sanctum-starter.local/api/sanctum/token")!
    let fetchUserUrl = URL(string: "http://sanctum-starter.local/api/user")!
    let logoutUrl = URL(string: "http://sanctum-starter.local/api/logout")!
    let updateProfileUrl = URL(string: "http://sanctum-starter.local/api/update-profile")!
    let deleteAccountUrl = URL(string: "http://sanctum-starter.local/api/delete-account")!
    let fetchUserDevicesUrl = URL(string: "http://sanctum-starter.local/api/registered-devices")!
    
    let pusherManager = PusherManager.shared
    
    private func setCommonHeaders(request: URLRequest) -> URLRequest {
        var updatedRequest = request
        updatedRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        updatedRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        return updatedRequest
    }
    
    func register(name: String, email: String, password: String, password_confirmation: String) async throws {
        print("Start registration...", name, email, password, password_confirmation)
        
        var request = URLRequest(url: registerUrl)
        request = setCommonHeaders(request: request)
        
        request.httpMethod = "POST"
        
        let body: [String: String] = await ["name": name, "email": email, "password": password, "password_confirmation": password_confirmation, "device_name": UIDevice.current.name]
        let finalBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: finalBody)
            
            let decoded = try JSONDecoder().decode(RegistrationResponse.self, from: data)
            
            updateTokenStorage(token: decoded.token)
            
            if response.http?.statusCode == 200 {
                // Success.
                print("Registration successful!")
                // Looks like there is nothing to do here.
            } else {
                // Error.
                print("Error occurred during registration: couldn't create new user.", decoded.message ?? "Registration error.")
                
                throw AppError.registrationError(message: decoded.message ?? "Registration error.")
            }
        } catch {
            // Re-throw error to calling script.
            throw error
        }
        
    }
    
    func login(email: String, password: String) async throws {
        print("Start login...", email, password)
        
        var request = URLRequest(url: loginUrl)
        request = setCommonHeaders(request: request)
        
        request.httpMethod = "POST"
        
        let body: [String: String] = await ["email": email, "password": password, "device_name": UIDevice.current.name]
        let finalBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: finalBody)
            
            let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
            
            updateTokenStorage(token: decoded.token)
            
            if response.http?.statusCode == 200 {
                // Success.
                print("Login successful!")
                // Looks like there is nothing to do here.
            } else {
                // Error.
                print("Error logging in.", decoded.message ?? "Login error.")
                
                throw AppError.loginError(message: decoded.message ?? "Login error.")
            }
        } catch {
            // Re-throw error to calling script.
            throw error
        }
        
    }
    
    func logout() async throws {
        print("Start logout...")
        
        guard let authToken = KeychainService.shared.read(service: "access-token", account: "org.smartcalc.starter", type: AuthToken.self) else { return }
        
        var request = URLRequest(url: logoutUrl)
        request = setCommonHeaders(request: request)
        request.setValue("Bearer \(authToken.token)", forHTTPHeaderField: "Authorization")
        
        request.httpMethod = "POST"
        
        let body: [String: String] = ["token": authToken.token]
        let finalBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.upload(for: request, from: finalBody)
            
            if response.http?.statusCode != 200 {
                print("Error occurred during logout.")
            } else {
                print("Logged out successfully!")
                
                updateTokenStorage(token: nil)
            }
        } catch {
            // Re-throw error to calling script.
            throw error
        }
    }
    
    func updateProfile(name: String, email: String, currentPassword: String, newPassword: String) async throws {
        print("Start update profile...")
        
        guard let authToken = KeychainService.shared.read(service: "access-token", account: "org.smartcalc.starter", type: AuthToken.self) else { return }
        
        var request = URLRequest(url: updateProfileUrl)
        request = setCommonHeaders(request: request)
        request.setValue("Bearer \(authToken.token)", forHTTPHeaderField: "Authorization")
        
        request.httpMethod = "PATCH"
        
        let body: [String: String] = [
            "name": name,
            "email": email,
            "current_password": currentPassword,
            "new_password": newPassword
        ]
        let finalBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: finalBody)
            
            let decoded = try JSONDecoder().decode(UpdateProfileResponse.self, from: data)
            
            print("***** Update profile response", decoded)
            
            if response.http?.statusCode != 200 {
                // Error.
                print("Error updating profile.", decoded.message ?? "Server error.")
                // TODO: send error to shared error store.
                
                throw AppError.profileUpdateError(message: decoded.message ?? "Error updating profile.")
            } else {
                print("Profile updated successfully!")
                
                if decoded.password_updated ?? false {
                    updateTokenStorage(token: nil)
                }
            }
        } catch {
            // Re-throw error to calling script.
            throw error
        }
    }
    
    func deleteAccount() async throws {
        print("Start delete account...")
        
        guard let authToken = KeychainService.shared.read(service: "access-token", account: "org.smartcalc.starter", type: AuthToken.self) else { return }
        
        var request = URLRequest(url: deleteAccountUrl)
        request = setCommonHeaders(request: request)
        request.setValue("Bearer \(authToken.token)", forHTTPHeaderField: "Authorization")
        
        request.httpMethod = "POST"
        
        let body: [String: String] = ["token": authToken.token]
        let finalBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.upload(for: request, from: finalBody)
            
            if response.http?.statusCode != 200 {
                print("Error occurred while deleting account.")
            } else {
                print("Account deleted successfully!")
                
                updateTokenStorage(token: nil)
            }
        } catch {
            // Re-throw error to calling script.
            throw error
        }
    }
    
    func fetchUser() async throws -> User? {
        guard let authToken = KeychainService.shared.read(service: "access-token", account: "org.smartcalc.starter", type: AuthToken.self) else { return nil }
        
        var request = URLRequest(url: fetchUserUrl)
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(authToken.token)", forHTTPHeaderField: "Authorization")
        
        request.httpMethod = "GET"
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        do {
            let user = try JSONDecoder().decode(User.self, from: data)
            
            print("User:", user)
            
            return user
        } catch {
            print("DEBUG :: User profile error", error.localizedDescription)
            
            return nil
        }
    }
    
    func fetchUserDevices() async throws -> [UserDevice]? {
        guard let authToken = KeychainService.shared.read(service: "access-token", account: "org.smartcalc.starter", type: AuthToken.self) else { return nil }
        
        var request = URLRequest(url: fetchUserDevicesUrl)
        
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(authToken.token)", forHTTPHeaderField: "Authorization")
        
        request.httpMethod = "GET"
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        do {
            let devices = try JSONDecoder().decode([UserDevice].self, from: data)
            
            // print("Devices:", devices)
            
            return devices
        } catch {
            print("DEBUG :: User profile error", error.localizedDescription)
            
            return nil
        }
    }
    
    private func updateTokenStorage(token: String?) {
        if let token = token {
            print("***** Saving token in keychain:", token)
            KeychainService.shared.save(AuthToken(token: token), service: "access-token", account: "org.smartcalc.starter")
        } else {
            print("***** Deleting token from keychain")
            KeychainService.shared.delete(service: "access-token", account: "org.smartcalc.starter")
        }
        
        pusherManager.configure()
    }
    
}
