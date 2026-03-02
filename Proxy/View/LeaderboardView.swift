//
//  LeaderboardView.swift
//  Proxy
//
//  Points leaderboard with glass UI.
//

import SwiftUI

struct LeaderboardView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    let brandOrange = Color(red: 1.0, green: 0.6, blue: 0.2)

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Podium for top 3
                        if viewModel.leaderboard.count >= 3 {
                            podiumView(
                                first: viewModel.leaderboard[0],
                                second: viewModel.leaderboard[1],
                                third: viewModel.leaderboard[2]
                            )
                            .padding(.top, 8)
                        } else if !viewModel.leaderboard.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(Array(viewModel.leaderboard.prefix(3).enumerated()), id: \.element.id) { index, user in
                                    HStack {
                                        Text("#\(index + 1)")
                                            .font(.title2.bold())
                                            .foregroundColor(brandOrange)
                                        Text(user.username)
                                            .font(.headline)
                                        Spacer()
                                        Text("\(user.points) pts")
                                            .font(.subheadline.bold())
                                            .foregroundColor(brandOrange)
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
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }

                        // Divider
                        if !viewModel.leaderboard.isEmpty {
                            HStack(spacing: 6) {
                                Image(systemName: "list.number")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(brandOrange)
                                Text("Full Rankings")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                        }

                        // Full ranked list
                        LazyVStack(spacing: 10) {
                            if viewModel.leaderboard.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "trophy")
                                        .font(.system(size: 40))
                                        .foregroundColor(.secondary)
                                    Text("No rankings yet")
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                            } else {
                                ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.id) { index, user in
                                    let isMe = user.id == viewModel.currentUser?.id
                                    HStack(spacing: 12) {
                                        // Rank number
                                        Text("\(index + 1)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(medalColor(for: index))
                                            .frame(width: 28)

                                        // Avatar
                                        Circle()
                                            .fill(medalColor(for: index).opacity(0.15))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                Text(String(user.username.prefix(1)).uppercased())
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(medalColor(for: index))
                                            )

                                        // Name
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(user.username)
                                                .font(.system(size: 16, weight: .semibold))
                                            if isMe {
                                                Text("You")
                                                    .font(.system(size: 11, weight: .semibold))
                                                    .foregroundColor(brandOrange)
                                            }
                                        }

                                        Spacer()

                                        // Points
                                        Text("\(user.points) pts")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(brandOrange)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .background(
                                        Group {
                                            if isMe {
                                                brandOrange.opacity(0.08)
                                            } else {
                                                Color.clear
                                            }
                                        }
                                    )
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(isMe ? brandOrange.opacity(0.4) : Color.white.opacity(0.2), lineWidth: isMe ? 2 : 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(brandOrange)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                Task { await viewModel.fetchLeaderboard() }
            }
        }
    }

    // MARK: - Podium

    @ViewBuilder
    func podiumView(first: AppUser, second: AppUser, third: AppUser) -> some View {
        HStack(alignment: .bottom, spacing: 10) {
            podiumColumn(user: second, rank: 2, height: 80, color: Color.gray)
            podiumColumn(user: first, rank: 1, height: 110, color: Color.yellow)
            podiumColumn(user: third, rank: 3, height: 60, color: brandOrange)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    func podiumColumn(user: AppUser, rank: Int, height: CGFloat, color: Color) -> some View {
        let isMe = user.id == viewModel.currentUser?.id

        VStack(spacing: 4) {
            // Crown for 1st
            if rank == 1 {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
            }

            // Avatar
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: rank == 1 ? 56 : 44, height: rank == 1 ? 56 : 44)
                .overlay(
                    Text(String(user.username.prefix(1)).uppercased())
                        .font(rank == 1 ? .title2.bold() : .headline)
                        .foregroundColor(color == .yellow ? brandOrange : color)
                )
                .overlay(
                    Circle()
                        .stroke(isMe ? brandOrange : Color.clear, lineWidth: 3)
                )

            Text(isMe ? "You" : user.username)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)

            Text("\(user.points) pts")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(brandOrange)

            // Podium block — glass style
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
                .frame(height: height)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    Text("#\(rank)")
                        .font(.title3.bold())
                        .foregroundColor(color == .yellow ? brandOrange : color)
                )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Medal Colors

    func medalColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return brandOrange
        default: return .blue
        }
    }
}
