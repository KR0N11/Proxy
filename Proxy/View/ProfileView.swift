//
//  ProfileView.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var newPhotoURL: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            
            // --- UPDATED IMAGE LOGIC ---
            // 1. Check if we have a valid URL string
            if let urlString = viewModel.currentUser?.profilePicURL,
               let url = URL(string: urlString), !urlString.isEmpty {
                
                // 2. Load the image
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        // Success: Show the downloaded image
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.orange, lineWidth: 3))
                        
                    case .failure:
                        // Failure: URL is bad -> Show Generic Icon
                        genericProfileImage
                        
                    case .empty:
                        // Loading: Show Generic Icon (Instead of Spinner)
                        genericProfileImage
                        
                    @unknown default:
                        genericProfileImage
                    }
                }
            } else {
                // 3. No URL set -> Show Generic Icon immediately
                genericProfileImage
            }
            // ---------------------------
            
            // User Info
            Text(viewModel.currentUser?.username ?? "Loading...")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(viewModel.currentUser?.email ?? "")
                .foregroundColor(.gray)
            
            Divider()
            
            // Update Photo Section
            VStack(alignment: .leading) {
                Text("Update Profile Photo")
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                
                HStack {
                    TextField("Paste Image URL here...", text: $newPhotoURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                    
                    Button(action: {
                        Task {
                            await viewModel.updateProfilePic(url: newPhotoURL)
                            newPhotoURL = ""
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.orange)
                    }
                    .disabled(newPhotoURL.isEmpty)
                }
            }
            .padding()
            
            Spacer()
            
            // Sign Out
            Button(action: {
                viewModel.signOut()
            }) {
                Text("Sign Out")
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
        .navigationTitle("Profile")
    }
    
    // --- REUSABLE GENERIC ICON ---
    // This is used for: 1. No URL, 2. Bad URL, 3. While Loading
    var genericProfileImage: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFill()
            .frame(width: 120, height: 120)
            .foregroundColor(.gray.opacity(0.5)) // Light gray looks better for placeholders
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.orange, lineWidth: 3))
    }
}
