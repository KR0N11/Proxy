//
//  MessageInboxView.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//
import SwiftUI

struct MessagesInboxView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading chats...")
            } else {
                List {
                    // 1. Friend Requests Section (Fixed to show username)
                    friendRequestsSection
                    
                    // 2. My Friends / Recent Chats Section
                    recentChatsSection
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Messages")
        .refreshable {
            await viewModel.fetchCurrentUser()
        }
    }
    
    // MARK: - Subviews
    
    private var friendRequestsSection: some View {
        // Logic: Filter 'allUsers' to find the people who sent requests to you
        let pendingRequesters = viewModel.currentUser?.pendingRequests ?? []
        
        return Group {
            if !pendingRequesters.isEmpty {
                Section(header: Text("Friend Requests")) {
                    ForEach(pendingRequesters, id: \.self) { requesterID in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                            
                            VStack(alignment: .leading) {
                                // FIXED: Displaying Username instead of ID
                                Text(getUsername(for: requesterID))
                                    .font(.headline)
                                Text("Wants to be your friend")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Accept") {
                                Task { await viewModel.acceptFriendRequest(from: requesterID) }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    private var recentChatsSection: some View {
        Section(header: Text("Chats")) {
            if viewModel.friends.isEmpty {
                Text("No friends yet. Add some in 'People'!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                ForEach(viewModel.friends) { friend in
                    // FIXED: Redirection to actual ChatView instead of Text placeholder
                    NavigationLink(destination: ChatView(user: friend)) {
                        HStack(spacing: 12) {
                            AsyncImage(url: URL(string: friend.profilePicURL)) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(friend.username)
                                    .font(.headline)
                                Text("Tap to chat")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // This looks up the username from the list of all users we fetched earlier
    private func getUsername(for id: String) -> String {
        // This relies on you having a list of all users available (e.g. from UserListView)
        // If the requester isn't in your local list, it defaults to the ID
        return viewModel.friends.first(where: { $0.id == id })?.username ?? "New User (\(id.prefix(4))...)"
    }
}
