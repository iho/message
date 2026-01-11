//  MessageApp.swift

import SwiftUI
import CoreData

@main
struct MessageApp: App {
    @StateObject var chatService = ChatService()
    @State var selectedConversation: Conversation?
    
    @AppStorage("chat_display_name") var chatDisplayName: String = ""
    
    var body: some Scene {
        WindowGroup {
            if chatDisplayName.isEmpty {
                StartView {
                    // Refresh view state or rely on AppStorage to trigger update
                }
            } else {
                NavigationSplitView {
                    ConversationListView(
                        selectedConversation: $selectedConversation
                    )
                    .environmentObject(chatService)
                } detail: {
                    if let conversation = selectedConversation {
                        ChatThreadView(conversation: conversation)
                            .environmentObject(chatService)
                    } else {
                        ContentUnavailableView("Select a Conversation", systemImage: "bubble.left.and.bubble.right")
                    }
                }
            }
        }
    }
    
}
