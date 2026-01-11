// ChatThreadView.swift
import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ChatThreadView: View {
    let conversation: Conversation
    @EnvironmentObject var chatService: ChatService
    @State private var text: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            // Custom Header from Figma ("Left Title" style + Title)
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                    }
                    .font(.system(size: 17))
                    .foregroundColor(.black)
                }
                
                Spacer()
                
                Text(conversation.participants.first?.displayName ?? "Chat")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                // Balance layout
                Color.clear.frame(width: 80, height: 20)
            }
            .padding()
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(uiColor: .systemGray5)),
                alignment: .bottom
            )
            #endif
            
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                    // Dynamic Message Lookup
                        let peerName = conversation.participants.first?.displayName ?? ""
                        let messages = chatService.receivedMessages[peerName] ?? conversation.messages
                        
                        ForEach(messages) { message in
                            MessageBubbleMinimal(message: message, isCurrentUser: message.author.displayName == chatService.displayName)
                        }
                    }
                    .padding()
                }
                .onChange(of: chatService.receivedMessages) { _ in
                     // Auto-scroll logic if needed
                }
            }
            
            // Input Bar
            HStack(spacing: 12) {
                TextField("iMessage...", text: $text)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke({
                                #if os(iOS)
                                return Color(uiColor: .systemGray4)
                                #else
                                return Color(nsColor: .gridColor)
                                #endif
                            }(), lineWidth: 1)
                    )
                
                Button(action: {
                    guard !text.isEmpty else { return }
                    if let peerName = conversation.participants.first?.displayName {
                        chatService.send(text: text, toPeerNamed: peerName)
                        text = ""
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                }
            }
            .padding()
            .background(Color.white)
        }
        .background(Color.white)
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .navigationTitle(conversation.participants.first?.displayName ?? "Chat")
    }
}

struct MessageBubbleMinimal: View {
    let message: Message
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            Text(message.text)
                .font(.system(size: 17))
                .foregroundColor(isCurrentUser ? .white : .black)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isCurrentUser ? Color.black : {
                            #if os(iOS)
                            return Color(uiColor: .systemGray5)
                            #else
                            return Color(nsColor: .controlBackgroundColor)
                            #endif
                        }())
                )
                .frame(maxWidth: 260, alignment: isCurrentUser ? .trailing : .leading)
            
            if !isCurrentUser { Spacer() }
        }
    }
}
