//
//  MessageInboxView.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//

import SwiftUI

struct MessagesInboxView: View {
    @EnvironmentObject var viewModel: AppViewModel

    let brandOrange = Color(red: 1.0, green: 0.6, blue: 0.2)

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading chats...")
            } else {
                ZStack {
                    Color(.systemGroupedBackground).ignoresSafeArea()

                    ScrollView {
                        LazyVStack(spacing: 10) {
                            friendRequestsSection
                            recentChatsSection
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
        }
        .navigationTitle("Messages")
        .refreshable {
            viewModel.fetchCurrentUser()
        }
    }

    // MARK: - Friend Requests

    private var friendRequestsSection: some View {
        let pendingRequesters = viewModel.currentUser?.pendingRequests ?? []

        return Group {
            if !pendingRequesters.isEmpty {
                sectionHeader("Friend Requests", icon: "person.badge.clock.fill")

                ForEach(pendingRequesters, id: \.self) { requesterID in
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
        }
    }

    // MARK: - Recent Chats

    private var recentChatsSection: some View {
        Group {
            sectionHeader("Chats", icon: "bubble.left.and.bubble.right.fill")

            if viewModel.friends.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No friends yet. Add some in 'People'!")
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
                    NavigationLink(destination: ChatView(user: friend)) {
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
                                    .foregroundColor(.primary)
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
        }
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
        return viewModel.friends.first(where: { $0.id == id })?.username ?? "New User (\(id.prefix(4))...)"
    }
}
