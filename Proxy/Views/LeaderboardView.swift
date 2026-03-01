import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var firebaseService: FirebaseService

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Podium for top 3
                    if firebaseService.leaderboard.count >= 3 {
                        PodiumView(
                            first: firebaseService.leaderboard[0],
                            second: firebaseService.leaderboard[1],
                            third: firebaseService.leaderboard[2],
                            currentUserId: firebaseService.currentUserId ?? ""
                        )
                        .padding(.top, 10)
                    } else if !firebaseService.leaderboard.isEmpty {
                        // Show what we have if less than 3
                        ForEach(Array(firebaseService.leaderboard.prefix(3).enumerated()), id: \.element.id) { index, entry in
                            LeaderboardRow(
                                rank: index + 1,
                                entry: entry,
                                isCurrentUser: entry.id == firebaseService.currentUserId
                            )
                        }
                    }

                    // Rest of the leaderboard
                    if firebaseService.leaderboard.count > 3 {
                        VStack(spacing: 0) {
                            ForEach(Array(firebaseService.leaderboard.dropFirst(3).enumerated()), id: \.element.id) { index, entry in
                                LeaderboardRow(
                                    rank: index + 4,
                                    entry: entry,
                                    isCurrentUser: entry.id == firebaseService.currentUserId
                                )
                                if index + 4 < firebaseService.leaderboard.count {
                                    Divider().padding(.leading, 60)
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    if firebaseService.leaderboard.isEmpty {
                        ContentUnavailableView(
                            "No Activity Yet",
                            systemImage: "trophy",
                            description: Text("Interact with checkpoints to earn points!")
                        )
                    }
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Leaderboard")
            .onAppear {
                firebaseService.fetchLeaderboard()
            }
            .refreshable {
                firebaseService.fetchLeaderboard()
            }
        }
    }
}

struct PodiumView: View {
    let first: LeaderboardEntry
    let second: LeaderboardEntry
    let third: LeaderboardEntry
    let currentUserId: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // 2nd place
            PodiumSlot(entry: second, rank: 2, height: 90, color: .gray, isCurrentUser: second.id == currentUserId)

            // 1st place
            PodiumSlot(entry: first, rank: 1, height: 120, color: .yellow, isCurrentUser: first.id == currentUserId)

            // 3rd place
            PodiumSlot(entry: third, rank: 3, height: 70, color: .orange, isCurrentUser: third.id == currentUserId)
        }
        .padding(.horizontal, 24)
    }
}

struct PodiumSlot: View {
    let entry: LeaderboardEntry
    let rank: Int
    let height: CGFloat
    let color: Color
    let isCurrentUser: Bool

    var body: some View {
        VStack(spacing: 6) {
            // Avatar
            Circle()
                .fill(isCurrentUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay {
                    Text(String(entry.name.prefix(1)).uppercased())
                        .font(.title2.bold())
                        .foregroundColor(isCurrentUser ? .blue : .gray)
                }

            Text(entry.name)
                .font(.caption.bold())
                .lineLimit(1)

            Text("\(entry.points) pts")
                .font(.caption2)
                .foregroundColor(.secondary)

            // Podium block
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.3))
                    .frame(height: height)

                Text("\(rank)")
                    .font(.title.bold())
                    .foregroundColor(color.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let entry: LeaderboardEntry
    let isCurrentUser: Bool

    var body: some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .center)

            Circle()
                .fill(isCurrentUser ? Color.blue.opacity(0.15) : Color.gray.opacity(0.1))
                .frame(width: 38, height: 38)
                .overlay {
                    Text(String(entry.name.prefix(1)).uppercased())
                        .font(.headline)
                        .foregroundColor(isCurrentUser ? .blue : .gray)
                }

            Text(entry.name)
                .font(.body)
                .fontWeight(isCurrentUser ? .bold : .regular)

            Spacer()

            Text("\(entry.points) pts")
                .font(.subheadline.bold())
                .foregroundColor(.blue)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(isCurrentUser ? Color.blue.opacity(0.05) : Color.clear)
    }
}
