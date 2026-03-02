//
//  FriendRequestView.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//

import SwiftUI

struct FriendRequestView: View {
    @EnvironmentObject var viewModel: AppViewModel

    let brandOrange = Color(red: 1.0, green: 0.6, blue: 0.2)

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: 10) {
                    if let requests = viewModel.currentUser?.pendingRequests, !requests.isEmpty {
                        ForEach(requests, id: \.self) { requesterID in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(brandOrange.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Text(String(getUsername(for: requesterID).prefix(1)).uppercased())
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(brandOrange)
                                    )

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(getUsername(for: requesterID))
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Wants to be your friend")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Button {
                                    Task { await viewModel.rejectFriendRequest(from: requesterID) }
                                } label: {
                                    Text("Reject")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(Color.red.opacity(0.1))
                                        .cornerRadius(12)
                                }

                                Button {
                                    Task { await viewModel.acceptFriendRequest(from: requesterID) }
                                } label: {
                                    Text("Accept")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(brandOrange)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No pending requests")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .navigationTitle("Requests")
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
