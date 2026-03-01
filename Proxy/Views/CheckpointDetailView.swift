import SwiftUI
import FirebaseFirestore

struct CheckpointDetailView: View {
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss

    let checkpoint: Checkpoint

    @State private var messages: [ChatMessage] = []
    @State private var newMessage = ""
    @State private var newQuestion = ""
    @State private var currentQuestion: String?
    @State private var createdByName: String?
    @State private var listener: ListenerRegistration?

    var hasQuestion: Bool {
        currentQuestion != nil && !(currentQuestion?.isEmpty ?? true)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Checkpoint header
                VStack(spacing: 6) {
                    Image(systemName: checkpoint.type == "school" ? "building.columns.fill" : "leaf.fill")
                        .font(.title)
                        .foregroundColor(checkpoint.type == "school" ? .orange : .green)

                    Text(checkpoint.name)
                        .font(.headline)

                    if hasQuestion {
                        VStack(spacing: 4) {
                            Text("Topic")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(currentQuestion ?? "")
                                .font(.subheadline.bold())
                                .multilineTextAlignment(.center)
                            if let name = createdByName {
                                Text("Started by \(name)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(10)
                    }
                }
                .padding()

                Divider()

                if hasQuestion {
                    // Chat messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 10) {
                                ForEach(messages) { message in
                                    ChatBubble(
                                        message: message,
                                        isOwn: message.userId == firebaseService.currentUserId
                                    )
                                    .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) {
                            if let last = messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Message input
                    HStack(spacing: 10) {
                        TextField("Type a message...", text: $newMessage)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            sendMessage()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        .disabled(newMessage.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                } else {
                    // No question yet - prompt to set one
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.text.bubble.right")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)

                        Text("Be the first to start a conversation!")
                            .font(.headline)

                        Text("Set a question or topic for others to discuss")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        VStack(spacing: 10) {
                            TextField("Enter a question or idea...", text: $newQuestion)
                                .textFieldStyle(.roundedBorder)

                            Button {
                                setQuestion()
                            } label: {
                                Text("Start Topic")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .disabled(newQuestion.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .padding(.horizontal, 32)
                    }
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        listener?.remove()
                        dismiss()
                    }
                }
            }
            .onAppear {
                currentQuestion = checkpoint.question
                createdByName = checkpoint.createdByName
                if hasQuestion {
                    startListening()
                }
            }
            .onDisappear {
                listener?.remove()
            }
        }
    }

    private func setQuestion() {
        let question = newQuestion.trimmingCharacters(in: .whitespaces)
        guard !question.isEmpty else { return }

        firebaseService.setCheckpointQuestion(checkpointId: checkpoint.id, question: question)
        currentQuestion = question
        createdByName = firebaseService.currentUser?.name
        newQuestion = ""
        startListening()
    }

    private func sendMessage() {
        let text = newMessage.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        firebaseService.sendMessage(checkpointId: checkpoint.id, text: text)
        newMessage = ""
    }

    private func startListening() {
        listener = firebaseService.listenForMessages(checkpointId: checkpoint.id) { msgs in
            self.messages = msgs
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    let isOwn: Bool

    var body: some View {
        HStack {
            if isOwn { Spacer(minLength: 50) }

            VStack(alignment: isOwn ? .trailing : .leading, spacing: 3) {
                if !isOwn {
                    Text(message.userName)
                        .font(.caption2.bold())
                        .foregroundColor(.blue)
                }

                Text(message.text)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isOwn ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isOwn ? .white : .primary)
                    .cornerRadius(16)

                Text(message.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            if !isOwn { Spacer(minLength: 50) }
        }
    }
}
