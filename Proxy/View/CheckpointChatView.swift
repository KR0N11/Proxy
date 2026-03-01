//
//  CheckpointChatView.swift
//  Proxy
//
//  Community chat at map checkpoints (like Pokestops).
//  First person sets a question/topic, others join in.
//

import SwiftUI

struct CheckpointChatView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    let checkpoint: Checkpoint
    @State private var messageText = ""
    @State private var questionText = ""
    @State private var showSetQuestion = false

    var hasQuestion: Bool {
        !checkpoint.question.isEmpty
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Checkpoint header
                VStack(spacing: 6) {
                    Image(systemName: checkpoint.type == "school" ? "building.columns.fill" : "leaf.fill")
                        .font(.system(size: 28))
                        .foregroundColor(checkpoint.type == "school" ? .purple : .green)

                    Text(checkpoint.name)
                        .font(.headline)

                    if hasQuestion {
                        VStack(spacing: 4) {
                            Text("Topic:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(checkpoint.question)
                                .font(.subheadline.bold())
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            Text("Started by \(checkpoint.questionByUsername)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    } else {
                        Text("No topic yet - be the first to start one!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))

                Divider()

                // Show "Set Question" if no question set yet
                if !hasQuestion {
                    VStack(spacing: 8) {
                        Text("Start the conversation!")
                            .font(.subheadline.bold())

                        HStack {
                            TextField("Type a question or idea...", text: $questionText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Button {
                                Task {
                                    await viewModel.setCheckpointQuestion(
                                        checkpointId: checkpoint.id,
                                        question: questionText
                                    )
                                    questionText = ""
                                    // Refresh checkpoints to get updated question
                                    await viewModel.fetchNearbyCheckpoints(latitude: 0, longitude: 0)
                                }
                            } label: {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                            }
                            .disabled(questionText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(.systemGroupedBackground))
                    Divider()
                }

                // Messages list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(viewModel.checkpointMessages) { msg in
                                CheckpointMessageBubble(
                                    message: msg,
                                    isMe: msg.userId == viewModel.currentUser?.id
                                )
                                .id(msg.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.checkpointMessages.count) { _ in
                        if let last = viewModel.checkpointMessages.last {
                            withAnimation {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Message input (only if question is set)
                if hasQuestion {
                    Divider()
                    HStack(spacing: 8) {
                        TextField("Share your thoughts...", text: $messageText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Button {
                            let text = messageText.trimmingCharacters(in: .whitespaces)
                            guard !text.isEmpty else { return }
                            Task {
                                await viewModel.sendCheckpointMessage(
                                    checkpointId: checkpoint.id,
                                    text: text
                                )
                            }
                            messageText = ""
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.orange)
                                .clipShape(Circle())
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Community Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                viewModel.fetchCheckpointMessages(checkpointId: checkpoint.id)
            }
        }
    }
}

// MARK: - Message Bubble

struct CheckpointMessageBubble: View {
    let message: CheckpointMessage
    let isMe: Bool

    var body: some View {
        HStack {
            if isMe { Spacer() }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                if !isMe {
                    Text(message.username)
                        .font(.caption2.bold())
                        .foregroundColor(.orange)
                }
                Text(message.text)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isMe ? Color.orange : Color(.systemGray5))
                    .foregroundColor(isMe ? .white : .primary)
                    .cornerRadius(16)

                Text(message.timestamp, style: .time)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }

            if !isMe { Spacer() }
        }
    }
}
