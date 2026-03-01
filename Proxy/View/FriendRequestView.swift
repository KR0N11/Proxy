//
//  FriendRequestView.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//
import SwiftUI

struct FriendRequestView: View {
    @EnvironmentObject var viewModel: AppViewModel
    
    var body: some View {
        List {
            if let requests = viewModel.currentUser?.pendingRequests, !requests.isEmpty {
                ForEach(requests, id: \.self) { requesterID in
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                        
                        VStack(alignment: .leading) {
                            Text(getUsername(for: requesterID))
                                .font(.headline)
                            Text("Wants to be your friend")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Reject") {
                            Task {
                                await viewModel.rejectFriendRequest(from: requesterID)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                        
                        Button("Accept") {
                            Task {
                                await viewModel.acceptFriendRequest(from: requesterID)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("No pending requests")
                    .foregroundColor(.gray)
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
