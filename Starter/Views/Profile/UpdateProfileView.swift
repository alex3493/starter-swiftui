//
//  UpdateProfileView.swift
//  Starter
//
//  Created by Alex on 29/3/24.
//

import SwiftUI

struct UpdateProfileView: View {
    
    @State var name: String = ""
    @State var email: String = ""
    @State var password: String = ""
    @State var newPassword: String = ""
    @State var newPasswordConfirmation: String = ""
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            // if let user = authViewModel.currentUser {
            Section("Profile") {
                VStack(spacing: 16) {
                    TextInputView(text: $name, title: "Name", placeholder: "Name...", isSecureField: false)
                    TextInputView(text: $email, title: "Email", placeholder: "Email...", isSecureField: false)
                    
                    ActionButton(label: "UPDATE PROFILE", action: {
                        do {
                            try await authViewModel.updateProfile(name: name, email: email)
                            
                            dismiss()
                        } catch {
                            print("DEBUG :: Update profile error in view", error.localizedDescription)
                        }
                    }, buttonSystemImage: "person.crop.circle", backGroundColor: Color(.systemBlue), maxWidth: true)
                }
            }
            
            Section("Password") {
                VStack(spacing: 16) {
                    TextInputView(text: $password, title: "Password", placeholder: "Current password...", isSecureField: true)
                    TextInputView(text: $newPassword, title: "New Password", placeholder: "Enter new password...", isSecureField: true)
                    TextInputView(text: $newPasswordConfirmation, title: "Confirm New Password", placeholder: "Confirm new password...", isSecureField: true)
                    
                    ActionButton(label: "UPDATE PASSWORD", action: {
                        do {
                            try await authViewModel.updatePassword(currentPassword: password, newPassword: newPassword, newPasswordConfirmation: newPasswordConfirmation)
                        } catch {
                            print("DEBUG :: Update password error in view", error.localizedDescription)
                        }
                    }, buttonSystemImage: "lock.fill", backGroundColor: Color(.systemBlue), maxWidth: true)
                }
            }
            // }
        }
        .onAppear {
            name = authViewModel.currentUser?.name ?? ""
            email = authViewModel.currentUser?.email ?? ""
        }
    }
}

#Preview {
    UpdateProfileView()
}
