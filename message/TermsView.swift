// TermsView.swift
import SwiftUI
#if os(macOS)
import AppKit
#endif

struct TermsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("1. Загальні положення")
                    .font(.headline)
                Text("Ця політика конфіденційності описує, як ми збираємо, використовуємо та захищаємо ваші дані.")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("2. Збір даних")
                    .font(.headline)
                Text("Ми збираємо мінімальну кількість даних, необхідних для функціонування сервісу.")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                // Add more placeholder text as needed
            }
            .padding()
        }
        #if os(iOS)
        .navigationBarTitle("Confidentiality", displayMode: .inline)
        #else
        .navigationTitle("Confidentiality")
        #endif
    }
}

#Preview {
    TermsView()
}
