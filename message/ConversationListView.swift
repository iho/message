// ConversationListView.swift
import SwiftUI
import MultipeerConnectivity
#if os(macOS)
import AppKit
#endif

struct ConversationListView: View {
    @EnvironmentObject var chatService: ChatService
    @Binding var selectedConversation: Conversation?
    @State private var selectedFilter: String = "Всі"
    
    let filters = ["Всі", "Вибране", "Запити", "Топіки"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filters, id: \.self) { filter in
                        FilterChip(title: filter, isSelected: selectedFilter == filter)
                            .onTapGesture {
                                selectedFilter = filter
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color.white) // Native background
            
            List {
                if selectedFilter == "Всі" {
                    // Pinned Section
                    if !chatService.peers.isEmpty {
                        Section(header: SectionHeaderView(title: "Закріплені")) {
                            ForEach(chatService.peers.prefix(2), id: \.self) { peer in
                                PeerRow(peer: peer, isPinned: true) {
                                    startChat(with: peer)
                                }
                            }
                        }
                    }
                    
                    // Recent Section
                    if !chatService.peers.isEmpty {
                        Section(header: SectionHeaderView(title: "Недавні")) {
                            ForEach(chatService.peers.dropFirst(2), id: \.self) { peer in
                                PeerRow(peer: peer, isPinned: false) {
                                    startChat(with: peer)
                                }
                            }
                        }
                    }
                    
                    // Active Conversations
                    if !chatService.localConversations.isEmpty {
                        Section(header: SectionHeaderView(title: "Чати")) {
                            ForEach(chatService.localConversations) { conversation in
                                ConversationRow(conversation: conversation, isSelected: selectedConversation?.id == conversation.id) {
                                    selectedConversation = conversation
                                }
                            }
                        }
                    }
                } else {
                    // Filtered Sections (Mock Data)
                    Section(header: SectionHeaderView(title: selectedFilter)) {
                        ForEach(filteredConversations, id: \.id) { conversation in
                            ConversationRow(conversation: conversation, isSelected: selectedConversation?.id == conversation.id) {
                                selectedConversation = conversation
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            #if os(macOS)
            .listStyle(.sidebar)
            #endif
        }
        .navigationTitle("Чат X.509")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    chatService.isDiscoverable = true
                    chatService.restartDiscovery()
                }) {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.black)
                }
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    UserDefaults.standard.set("", forKey: "chat_display_name")
                }) {
                    Image(systemName: "person.circle")
                        .foregroundColor(.black)
                }
            }
        }
    }
    
    // Helper to start chat from peer
    private func startChat(with peer: MCPeerID) {
        let participant = Participant(
            firstName: peer.displayName,
            lastName: "",
            username: peer.displayName,
            profileImageLink: nil
        )
        
        let conversation = Conversation(
            participants: [participant],
            messages: chatService.receivedMessages[peer.displayName] ?? [],
            updatedAt: Date(),
            isRead: true,
            isPinned: false,
            profileImageLink: nil
        )
        
        selectedConversation = conversation
    }
    
    // Mock Data Logic
    private var filteredConversations: [Conversation] {
        // Create dummy participants
        let p1 = Participant(firstName: "Олена", lastName: "Петренко", username: "olena", profileImageLink: nil)
        let p2 = Participant(firstName: "Support", lastName: "Bot", username: "support", profileImageLink: nil)
        let p3 = Participant(firstName: "News", lastName: "Channel", username: "news", profileImageLink: nil)
        
        switch selectedFilter {
        case "Вибране":
            return [
                Conversation(participants: [p1], messages: [Message(text: "Привіт! Як справи?", createdAt: Date(), author: p1)], updatedAt: Date(), isRead: false, isPinned: true, profileImageLink: nil),
                Conversation(participants: [p2], messages: [Message(text: "Ваше замовлення готове", createdAt: Date().addingTimeInterval(-3600), author: p2)], updatedAt: Date(), isRead: true, isPinned: true, profileImageLink: nil)
            ]
        case "Запити":
            return [
                 Conversation(participants: [p3], messages: [Message(text: "Breaking News: Update Available", createdAt: Date(), author: p3)], updatedAt: Date(), isRead: false, isPinned: false, profileImageLink: nil)
            ]
        case "Топіки":
            return [] // Empty state demo
        default:
            return []
        }
    }
}

// MARK: - Subviews

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            #if os(iOS)
            .font(.system(size: 13, weight: .medium))
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            #else
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.vertical, 6)
            .padding(.horizontal, 16)
            #endif
            .background(isSelected ? Color.black : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
    }
}

struct SectionHeaderView: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.black)
            .padding(.vertical, 4)
    }
}

struct PeerRow: View {
    let peer: MCPeerID
    let isPinned: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .strokeBorder(Color.black, lineWidth: 1)
                        .background(Circle().fill(Color.white))
                        .frame(width: 48, height: 48)
                    
                    Text(String(peer.displayName.prefix(1)))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(peer.displayName)
                        .font(.system(size: 16, weight: .bold)) // Primary bold
                        .foregroundColor(.black)
                    
                    Text("Прошу розглянути питання") // Mock message
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Trailing Info
                VStack(alignment: .trailing, spacing: 4) {
                    if isPinned {
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 20, height: 20)
                            Text("2")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .bold()
                        }
                        Text("2:14 PM")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.black)
                        Text("10:00 AM")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .listRowSeparator(.hidden)
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    let isSelected: Bool
    let action: () -> Void
        
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Avatar
                 ZStack {
                    Circle()
                        .strokeBorder(Color.black, lineWidth: 1)
                        .background(Circle().fill(Color.white))
                        .frame(width: 48, height: 48)
                    
                     if let p = conversation.participants.first {
                         Text(String(p.displayName.prefix(1)))
                             .font(.system(size: 20, weight: .bold))
                             .foregroundColor(.black)
                     }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(conversation.participants.first?.displayName ?? "Unknown")
                         .font(.system(size: 16, weight: .bold))
                         .foregroundColor(.black)
                    
                    Text(conversation.messages.last?.text ?? "No messages")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    // Time
                    Text(timeString(date: conversation.updatedAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Checkmark mock
                    Image(systemName: "checkmark")
                         .font(.caption)
                         .foregroundColor(.black)
                         .opacity(0.8)
                }
            }
             .padding(.vertical, 4)
        }
    }
    
    private func timeString(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
