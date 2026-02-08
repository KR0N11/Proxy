//
//  UserListView.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//
import SwiftUI
import FirebaseFirestore

struct UserListView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var allUsers: [AppUser] = []
    @State private var searchText = ""
    @State private var zoomedID: String? = nil
    
    var filteredUsers: [AppUser] {
        if searchText.isEmpty { return allUsers }
        return allUsers.filter { $0.username.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List(filteredUsers) { user in
            HStack(spacing: 12) {
                // Profile Image
                AsyncImage(url: URL(string: user.profilePicURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill").resizable().foregroundColor(.gray)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(user.username).font(.headline)
                    Text(user.email).font(.caption).foregroundColor(.gray)
                }
                
                Spacer()
                
                // --- ICON SWITCHING LOGIC ---
                let isFriend = viewModel.currentUser?.friendIDs.contains(user.id) ?? false
                let hasSentRequest = user.pendingRequests.contains(viewModel.currentUser?.id ?? "")
                
                Button(action: {
                    if !isFriend && !hasSentRequest {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            zoomedID = user.id
                        }
                        Task {
                            await viewModel.sendFriendRequest(to: user.email)
                            try? await Task.sleep(nanoseconds: 200_000_000)
                            withAnimation { zoomedID = nil }
                        }
                    }
                }) {
                    Image(systemName: isFriend ? "person.fill.checkmark" : (hasSentRequest ? "paperplane.fill" : "person.badge.plus"))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(isFriend ? .green : (hasSentRequest ? .blue : .orange))
                        .padding(8)
                        .background(isFriend ? Color.green.opacity(0.1) : (hasSentRequest ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1)))
                        .clipShape(Circle())
                        .scaleEffect(zoomedID == user.id ? 1.5 : 1.0)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isFriend || hasSentRequest)
            }
            .padding(.vertical, 4)
        }
        .listStyle(PlainListStyle())
        .searchable(text: $searchText, prompt: "Search users")
        .navigationTitle("People")
        .onAppear { fetchAllUsers() }
    }
    
    func fetchAllUsers() {
        let db = Firestore.firestore()
        db.collection("users").getDocuments { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            self.allUsers = documents.compactMap { AppUser(id: $0.documentID, dict: $0.data()) }
            if let myID = viewModel.currentUser?.id {
                self.allUsers.removeAll { $0.id == myID }
            }
        }
    }
}
