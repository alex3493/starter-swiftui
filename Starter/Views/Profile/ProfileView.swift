//
//  ProfileView.swift
//  Starter
//
//  Created by Alex on 29/3/24.
//

import SwiftUI

struct ProfileView: View {
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        List {
            if let user = authViewModel.currentUser {
                
                Section {
                    HStack {
                        Text(user.initials)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 72, height: 72)
                            .background(Color(.systemGray3))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
                                .fontWeight(.semibold)
                                .font(.subheadline)
                                .padding(.top, 4)
                            Text(user.email)
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section("General") {
                    HStack {
                        SettingsRowView(imageName: "gear", title: "Version", tintColor: Color(.systemGray))
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Section("Profile") {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.circle")
                            .imageScale(.small)
                            .font(.title)
                            .foregroundColor(Color(.systemGray))
                        NavigationLink(destination: UpdateProfileView(), label: {
                            Text("Edit profile")
                        })
                    }
                }
                
                Section("Account") {
                    if let devices = authViewModel.currentUserDevices {
                        ForEach(devices, id:\.id) { item in
                            HStack {
                                Text("\(item.name)")
                                Spacer()
                                if let date = item.lastUsedDate {
                                    Text("\(date.formatted())")
                                }
                            }
                        }
                    }
                    
                    Button {
                        Task {
                            await authViewModel.signOut()
                        }
                    } label: {
                        SettingsRowView(imageName: "arrow.left.circle.fill", title: "Sign Out", tintColor: Color(.red))
                    }

                    Button {
                        Task {
                            await authViewModel.deleteAccount()
                        }
                    } label: {
                        SettingsRowView(imageName: "xmark.circle.fill", title: "Delete Account", tintColor: Color(.red))
                    }
                }
            }
        }
        .task {
            do {
                let _ = try await authViewModel.fetchUserDevices()
                
                // print("Loaded devices:", authViewModel.currentUserDevices as Any)
                
            } catch {
                print("DEBUG :: Error loading user devices")
            }
        }
    }
}

#Preview {
    ProfileView()
}

