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
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 10) {
                        // Friend Requests
                        if let requests = viewModel.currentUser?.pendingRequests, !requests.isEmpty {
                            sectionHeader("Friend Requests", icon: "person.badge.clock.fill")

                            ForEach(requests, id: \.self) { requesterID in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(brandOrange.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Text(String(getUsername(for: requesterID).prefix(1)).uppercased())
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(brandOrange)
                                        )

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(getUsername(for: requesterID))
                                            .font(.system(size: 15, weight: .semibold))
                                        Text("Wants to be your friend")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Button {
                                        Task { await viewModel.acceptFriendRequest(from: requesterID) }
                                    } label: {
                                        Text("Accept")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(brandOrange)
                                            .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }

                        // My Friends
                        sectionHeader("My Friends", icon: "person.2.fill")

                        if viewModel.friends.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 36))
                                    .foregroundColor(.secondary)
                                Text("No friends yet. Add some!")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        } else {
                            ForEach(viewModel.friends) { friend in
                                HStack(spacing: 14) {
                                    AsyncImage(url: URL(string: friend.profilePicURL)) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Circle()
                                            .fill(brandOrange.opacity(0.15))
                                            .overlay(
                                                Text(String(friend.username.prefix(1)).uppercased())
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(brandOrange)
                                            )
                                    }
                                    .frame(width: 48, height: 48)
                                    .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(friend.username)
                                            .font(.system(size: 16, weight: .semibold))
                                        Text("Tap to chat")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(brandOrange)
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                addFriendSheet
            }
        }
    }

    // MARK: - Add Friend Sheet

    private var addFriendSheet: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)

            Image(systemName: "person.badge.plus")
                .font(.system(size: 36))
                .foregroundColor(brandOrange)

            Text("Add a Friend")
                .font(.system(size: 20, weight: .bold))

            Text("Enter your friend's email address")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            TextField("Email", text: $targetEmail)
                .textFieldStyle(.plain)
                .padding(14)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(.horizontal)

            Button {
                Task {
                    await viewModel.sendFriendRequest(to: targetEmail)
                    showAddSheet = false
                    targetEmail = ""
                }
            } label: {
                Text("Send Request")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(brandOrange)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal)

            Spacer()
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(brandOrange)
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.top, 8)
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
