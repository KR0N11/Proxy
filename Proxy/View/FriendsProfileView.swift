//
//  FriendsProfileView.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//
//
//  FriendProfileView.swift
//  Created by user285973 on 2/8/26.
//

import SwiftUI

struct FriendProfileView: View {
    let user: AppUser
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        VStack(spacing: 25) {
            Spacer().frame(height: 20)

            AsyncImage(url: URL(string: user.profilePicURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundColor(.gray)
            }
            .frame(width: 150, height: 150)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.orange, lineWidth: 4))
            .shadow(radius: 5)

            VStack(spacing: 8) {
                Text(user.username)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(user.email)
                    .font(.body)
                    .foregroundColor(.gray)
            }

            if isFriend(user) {
                Text("Friends")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .cornerRadius(20)
            }
            
            Spacer().frame(height: 20)
        }
        .padding()

        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Helper to check friend status
    func isFriend(_ user: AppUser) -> Bool {
        return viewModel.friends.contains(where: { $0.id == user.id })
    }
}
