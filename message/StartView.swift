// StartView.swift
import SwiftUI

struct StartView: View {
    var onComplete: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Anonymous Registration
                    Button(action: {
                        UserDefaults.standard.set("Anonymous User", forKey: "chat_display_name")
                        onComplete()
                    }) {
                        Label("Анонімна реєстрація", systemImage: "person.circle")
                    }
                    
                    // Mobile Registration
                    NavigationLink(destination: MobileAuthView(onComplete: onComplete)) {
                        Label("Зараєструвати на мобільний", systemImage: "phone")
                    }
                    
                    // Email Registration
                    NavigationLink(destination: EmailAuthView(onComplete: onComplete)) {
                        Label("Реєстрація через пошту", systemImage: "envelope")
                    }
                } header: {
                    Text("Вхід")
                } footer: {
                    NavigationLink(destination: TermsView()) {
                        Text("Повідомлення про конфіденційність")
                            .font(.caption)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Welcome")
            #if os(macOS)
            .padding()
            .frame(maxWidth: 400, maxHeight: 500)
            .padding()
            #endif
        }
    }
}

#Preview {
    StartView(onComplete: {})
}
