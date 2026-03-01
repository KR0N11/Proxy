import SwiftUI

struct FriendsFilterView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss

    @Binding var hiddenFriendIds: Set<String>
    @Binding var maxDistance: Double
    let distanceOptions: [(String, Double)]

    var body: some View {
        NavigationView {
            List {
                // Distance filter section
                Section("Filter by Distance") {
                    Picker("Max Distance", selection: $maxDistance) {
                        ForEach(distanceOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Friends toggle section
                Section("Friends (\(firebaseService.friends.count))") {
                    if firebaseService.friends.isEmpty {
                        Text("No friends added yet")
                            .italic()
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(firebaseService.friends) { friend in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
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

                                Spacer()

                                Toggle("", isOn: Binding(
                                    get: { !hiddenFriendIds.contains(friend.id) },
                                    set: { visible in
                                        if visible {
                                            hiddenFriendIds.remove(friend.id)
                                        } else {
                                            hiddenFriendIds.insert(friend.id)
                                        }
                                    }
                                ))
                                .labelsHidden()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Friends on Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .bold()
                }
            }
        }
    }
}
