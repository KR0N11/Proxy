//
//  ChatView.swift
//  Proxy
//
//  Created by user285973 on 2/8/26.
//


import SwiftUI

struct ChatView: View {
    let user: AppUser // The friend you are talking to
    @EnvironmentObject var viewModel: AppViewModel
    @State private var messageText = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            // 1. The Message List Area
            ScrollViewReader { proxy in
                messageList
                    // Auto-scroll to bottom when a new message arrives
                    .onChange(of: viewModel.chatMessages.count) { _ in
                        if let lastMessage = viewModel.chatMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    // Auto-scroll when keyboard opens
                    .onChange(of: isFocused) { _ in
                        if let lastMessage = viewModel.chatMessages.last {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
            }
            
            // 2. The Input Area
            inputArea
        }
        .navigationTitle(user.username)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Start listening for messages when screen opens
            viewModel.fetchMessages(for: user)
        }
    }
    
    // MARK: - Subviews (Fixes Compiler Timeout Error)
    
    private var messageList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.chatMessages) { message in
                    MessageBubble(
                        message: message,
                        isCurrentUser: message.fromId == viewModel.currentUser?.id
                    )
                    .id(message.id) // Important for auto-scroll
                }
            }
            .padding()
        }
    }
    
    private var inputArea: some View {
        HStack(spacing: 10) {
            TextField("Message...", text: $messageText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isFocused)
                .padding(.vertical, 8)
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(messageText.isEmpty ? Color.gray : Color.blue)
                    .clipShape(Circle())
            }
            .disabled(messageText.isEmpty)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
    }
    
    // MARK: - Logic
    
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        viewModel.sendMessage(text: messageText, toUser: user)
        messageText = "" // Clear input
    }
}

// MARK: - Message Bubble Component

struct MessageBubble: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .background(isCurrentUser ? Color.blue : Color(UIColor.systemGray5))
                    .foregroundColor(isCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                    .clipShape(BubbleShape(myMessage: isCurrentUser))
            }
            
            if !isCurrentUser { Spacer() }
        }
    }
}

struct BubbleShape: Shape {
    var myMessage: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                myMessage ? .bottomLeft : .bottomRight
            ],
            cornerRadii: CGSize(width: 16, height: 16)
        )
        return Path(path.cgPath)
    }
}
