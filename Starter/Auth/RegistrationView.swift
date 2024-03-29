//
//  RegistrationView.swift
//  Starter
//
//  Created by Alex on 28/3/24.
//

import SwiftUI

struct RegistrationView: View {
    
    @State var email: String = ""
    @State var password: String = ""
    @State var confirmPassword: String = ""
    @State var name: String = ""
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        VStack {
            Image(systemName: "swift")
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .padding(.vertical, 32)
                .foregroundStyle(.cyan)
            VStack(spacing: 12) {
                TextInputView(text: $email, title: "Email", placeholder: "name@example.com")
                    .autocapitalization(.none)
                TextInputView(text: $name, title: "Name", placeholder: "Enter your name...", isSecureField: false)
                TextInputView(text: $password, title: "Password", placeholder: "Enter your password...", isSecureField: true)
                TextInputView(text: $confirmPassword, title: "Confirm Password", placeholder: "Confirm password...", isSecureField: true)
            }
            .padding(.top, 20)
            .padding(.horizontal)
            
            Button {
                Task {
                    do {
                        try await authViewModel.register(name: name, email: email, password: password, passwordConfirmation: confirmPassword)
                    } catch {
                        print("DEBUG :: Error creating account: \(error.localizedDescription)")
                    }
                }
            } label: {
                HStack {
                    Text("SIGN UP")
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(width: UIScreen.main.bounds.width - 32, height: 48)
            }
            .background(Color(.systemBlue))
            .cornerRadius(10)
            .padding(.top, 24)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                HStack(spacing: 3) {
                    Text("Already have an account?")
                    Text("Sign in")
                        .fontWeight(.bold)
                }
                .font(.system(size: 14))
            }
        }
    }
}

#Preview {
    RegistrationView()
}

