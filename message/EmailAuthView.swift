// EmailAuthView.swift
import SwiftUI
#if os(macOS)
import AppKit
#endif

struct EmailAuthView: View {
    @Environment(\.dismiss) var dismiss
    var onComplete: () -> Void
    
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var useKeychain: Bool = true
    @State private var showVerification: Bool = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    Image(systemName: "envelope.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.accentColor)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
            
            Section(header: Text("Personal Information")) {
                TextField("Full Name", text: $fullName)
                    .textContentType(.name)
                
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    #endif
            }
            
            Section(header: Text("Security")) {
                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                
                Toggle("Save to Keychain", isOn: $useKeychain)
            }
            
            Section {
                Button(action: {
                    showVerification = true
                }) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .bold()
                }
                .disabled(fullName.isEmpty)
            }
        }
        .navigationDestination(isPresented: $showVerification) {
            EmailVerifyView(email: email) {
                UserDefaults.standard.set(fullName, forKey: "chat_display_name")
                onComplete()
            }
        }
        #if os(iOS)
        .navigationBarTitle("Sign up", displayMode: .inline)
        #else
        .navigationTitle("Sign up")
        #endif
    }
    
}

// Wrapper for color compatibility
extension Color {
    #if os(iOS)
    static let systemGray6 = Color(uiColor: .systemGray6)
    #else
    static let systemGray6 = Color(nsColor: .controlBackgroundColor)
    #endif
}
