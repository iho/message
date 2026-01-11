// ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var chatService: ChatService
    @Binding var isPresented: Bool
    
    @State private var firstName = CurrentUser.shared.firstName
    @State private var lastName = CurrentUser.shared.lastName
    @State private var username = CurrentUser.shared.username
    @State private var isDiscoverable = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("My Identity") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Display Name (Visible to others)", text: $username)
                }
                
                Section("Discovery") {
                    Toggle("Always Discoverable on WiFi", isOn: $chatService.isDiscoverable)
                    Text("When on, others on the same WiFi can see you and start a chat.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Troubleshooting") {
                    Button(role: .destructive) {
                        UserDefaults.standard.removeObject(forKey: "chat_display_name")
                        chatService.restartDiscovery()
                        isPresented = false
                    } label: {
                        Text("Reset My Identity")
                    }
                    Text("Use this if you can't find others. It will clear your saved name and restart discovery.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        CurrentUser.shared.firstName = firstName
        CurrentUser.shared.lastName = lastName
        CurrentUser.shared.username = username
        
        UserDefaults.standard.set(firstName, forKey: "user_first_name")
        UserDefaults.standard.set(lastName, forKey: "user_last_name")
        
        // This triggers ChatService networking restart
        chatService.displayName = username
    }
}
