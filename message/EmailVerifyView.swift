// EmailVerifyView.swift
import SwiftUI
#if os(macOS)
import AppKit
#endif

struct EmailVerifyView: View {
    let email: String
    var onComplete: () -> Void
    
    @State private var code: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Verify Email")) {
                HStack {
                    Text("Email")
                        .bold()
                    Spacer()
                    Text(email)
                        .foregroundColor(.gray)
                }
                
                HStack {
                    TextField("enter code", text: $code)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    
                    Button("Send Code") {
                        // Resend logic
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            Section {
                Button(action: {
                    onComplete()
                }) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .bold()
                        .foregroundColor(.primary)
                }
                .disabled(code.isEmpty)
            }
        }
        #if os(iOS)
        .navigationBarTitle("Verify Email", displayMode: .inline)
        #else
        .navigationTitle("Verify Email")
        .frame(minWidth: 300, minHeight: 200)
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}
