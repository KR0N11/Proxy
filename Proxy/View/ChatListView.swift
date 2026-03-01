//
//  ChatListView.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//


import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var showAddSheet = false
    @State private var targetEmail = ""
    
    let brandOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    
    var body: some View {
        NavigationView {
            List {
                // Section 1: Friend Requests
                if let requests = viewModel.currentUser?.pendingRequests, !requests.isEmpty {
                    Section(header: Text("Friend Requests")) {
                        ForEach(requests, id: \.self) { requesterID in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.gray)
                                VStack(alignment: .leading) {
                                    Text(getUsername(for: requesterID))
                                        .font(.subheadline)
                                        .bold()
                                    Text("Wants to be your friend")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Accept") {
                                    Task { await viewModel.acceptFriendRequest(from: requesterID) }
                                }
                                .padding(8)
                                .background(brandOrange)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Section 2: My Friends
                Section(header: Text("My Friends")) {
                    if viewModel.friends.isEmpty {
                        Text("No friends yet. Swipe left to add some!")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(viewModel.friends) { friend in
                            HStack(spacing: 15) {
                                AsyncImage(url: URL(string: friend.profilePicURL)) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Circle().fill(brandOrange.opacity(0.3))
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                
                                VStack(alignment: .leading) {
                                    Text(friend.username)
                                        .font(.headline)
                                    Text("Tap to chat")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(brandOrange)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                VStack(spacing: 20) {
                    Text("Add a Friend")
                        .font(.title2)
                        .bold()
                    
                    Text("Enter the email of your friend:")
                        .font(.caption)
                        .foregroundColor(.gray)

                    TextField("Email", text: $targetEmail)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()

                    Button {
                        Task {
                            await viewModel.sendFriendRequest(to: targetEmail)
                            showAddSheet = false
                            targetEmail = ""
                        }
                    } label: {
                        Text("Send Request")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(brandOrange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .presentationDetents([.medium])
            }
        }
    }

    private func getUsername(for id: String) -> String {
        if let user = viewModel.allUsers.first(where: { $0.id == id }) {
            return user.username
        }
        if let friend = viewModel.friends.first(where: { $0.id == id }) {
            return friend.username
        }
        return "User (\(id.prefix(5)))"
    }
}
