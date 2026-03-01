//
//  LeaderboardView.swift
//  Proxy
//
//  Points leaderboard / podium view.
//

import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Podium for top 3
                if viewModel.leaderboard.count >= 3 {
                    PodiumView(
                        first: viewModel.leaderboard[0],
                        second: viewModel.leaderboard[1],
                        third: viewModel.leaderboard[2]
                    )
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                } else if !viewModel.leaderboard.isEmpty {
                    // Fewer than 3 users, show simple top list
                    VStack(spacing: 8) {
                        ForEach(Array(viewModel.leaderboard.prefix(3).enumerated()), id: \.element.id) { index, user in
                            HStack {
                                Text("#\(index + 1)")
                                    .font(.title2.bold())
                                    .foregroundColor(.orange)
                                Text(user.username)
                                    .font(.headline)
                                Spacer()
                                Text("\(user.points) pts")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.orange)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 16)
                }

                Divider()

                // Full list
                List {
                    ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.id) { index, user in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.secondary)
                                .frame(width: 28)

                            Circle()
                                .fill(medalColor(for: index).opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(user.username.prefix(1)).uppercased())
                                        .font(.headline)
                                        .foregroundColor(medalColor(for: index))
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(user.username)
                                    .font(.headline)
                                if user.id == viewModel.currentUser?.id {
                                    Text("You")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }

                            Spacer()

                            Text("\(user.points) pts")
                                .font(.subheadline.bold())
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchLeaderboard()
                }
            }
        }
    }

    func medalColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .orange
        default: return .blue
        }
    }
}

// MARK: - Podium View (Top 3)

struct PodiumView: View {
    let first: AppUser
    let second: AppUser
    let third: AppUser

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // 2nd place
            PodiumColumn(user: second, rank: 2, height: 80, color: .gray)

            // 1st place
            PodiumColumn(user: first, rank: 1, height: 110, color: .yellow)

            // 3rd place
            PodiumColumn(user: third, rank: 3, height: 60, color: .orange)
        }
        .padding(.horizontal, 24)
    }
}

struct PodiumColumn: View {
    let user: AppUser
    let rank: Int
    let height: CGFloat
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            // Avatar
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: rank == 1 ? 56 : 44, height: rank == 1 ? 56 : 44)
                .overlay(
                    Text(String(user.username.prefix(1)).uppercased())
                        .font(rank == 1 ? .title2.bold() : .headline)
                        .foregroundColor(color == .yellow ? .orange : color)
                )

            Text(user.username)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)

            Text("\(user.points) pts")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.orange)

            // Podium block
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.3))
                .frame(height: height)
                .overlay(
                    Text("#\(rank)")
                        .font(.title3.bold())
                        .foregroundColor(color == .yellow ? .orange : color)
                )
        }
        .frame(maxWidth: .infinity)
    }
}
