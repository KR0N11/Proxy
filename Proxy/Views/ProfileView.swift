import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var locationManager: LocationManager

    @State private var showAddFriend = false
    @State private var friendEmail = ""
    @State private var addFriendMessage = ""

    var body: some View {
        NavigationView {
            List {
                // Profile header
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue.opacity(0.8))

                        Text(firebaseService.currentUser?.name ?? "User")
                            .font(.title2.bold())

                        Text(firebaseService.currentUser?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            Label("\(firebaseService.currentUser?.points ?? 0) points", systemImage: "star.fill")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)

                // Add friend section
                Section {
                    Button {
                        showAddFriend = true
                    } label: {
                        HStack {
                            Label("Add Friend", systemImage: "person.badge.plus.fill")
                            Spacer()
                            Image(systemName: "plus")
                                .font(.caption.bold())
                        }
                    }
                }

                // Friends list
                Section("Friends (\(firebaseService.friends.count))") {
                    if firebaseService.friends.isEmpty {
                        Text("No friends added yet")
                            .italic()
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(firebaseService.friends) { friend in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        Text(String(friend.name.prefix(1)).uppercased())
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                    }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(friend.name)
                                        .font(.headline)
                                    Text(friend.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let friend = firebaseService.friends[index]
                                firebaseService.removeFriend(friendId: friend.id)
                            }
                        }
                    }
                }

                // Sign out
                Section {
                    Button(role: .destructive) {
                        firebaseService.signOut()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .bold()
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .onAppear {
                firebaseService.fetchFriends()
            }
            .sheet(isPresented: $showAddFriend) {
                NavigationView {
                    Form {
                        Section("Add by Email") {
                            TextField("Friend's email address", text: $friendEmail)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }

                        if !addFriendMessage.isEmpty {
                            Section {
                                Text(addFriendMessage)
                                    .foregroundColor(addFriendMessage.contains("Added") ? .green : .red)
                            }
                        }
                    }
                    .navigationTitle("Add Friend")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                friendEmail = ""
                                addFriendMessage = ""
                                showAddFriend = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                let email = friendEmail.trimmingCharacters(in: .whitespaces)
                                firebaseService.addFriend(email: email) { success in
                                    DispatchQueue.main.async {
                                        if success {
                                            addFriendMessage = "Added successfully!"
                                            friendEmail = ""
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                addFriendMessage = ""
                                                showAddFriend = false
                                            }
                                        } else {
                                            addFriendMessage = "User not found. Check the email."
                                        }
                                    }
                                }
                            }
                            .disabled(friendEmail.trimmingCharacters(in: .whitespaces).isEmpty)
                            .bold()
                        }
                    }
                }
            }
        }
    }
}
