// MobileAuthView.swift
import SwiftUI
#if os(macOS)
import AppKit
#endif

struct MobileAuthView: View {
    @Environment(\.dismiss) var dismiss
    var onComplete: () -> Void
    
    @State private var fullName: String = ""
    @State private var phoneNumber: String = ""
    @State private var callsign: String = ""
    @State private var verificationCode: String = ""
    @State private var isCodeSent: Bool = false
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    Image(systemName: "iphone.gen3") // Placeholder for phone icon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 80)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
            
            Section(header: Text("Зареєструвати на мобільний (1)")) {
                TextField("ПІП", text: $fullName)
                    .textContentType(.name)
                
                TextField("Телефон", text: $phoneNumber)
                    .textContentType(.telephoneNumber)
                    #if os(iOS)
                    .keyboardType(.phonePad)
                    #endif
                
                TextField("Позивний", text: $callsign)
            }
            
            if isCodeSent {
                Section(header: Text("Верифікація (2)")) {
                    HStack {
                        TextField("Код підтвердження", text: $verificationCode)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                        
                        Button("Надіслати") {
                            // Resend logic
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                }
            } else {
                 Section {
                    Button(action: {
                        isCodeSent = true
                    }) {
                        Text("Надіслати код")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .disabled(phoneNumber.isEmpty)
                }
            }
            
            if isCodeSent {
                Section {
                    Button(action: {
                        completeRegistration()
                    }) {
                        Text("Погодитись і продовжити")
                            .frame(maxWidth: .infinity)
                            .bold()
                            .foregroundColor(.primary)
                    }
                    .disabled(verificationCode.isEmpty)
                }
            }
        }
        #if os(iOS)
        .navigationBarTitle("Mobile Registration", displayMode: .inline)
        #else
        .navigationTitle("Mobile Registration")
        #endif
    }
    
    private func completeRegistration() {
        guard !fullName.isEmpty else { return }
        // Save user name (prioritize callsign if available)
        let displayName = callsign.isEmpty ? fullName : callsign
        UserDefaults.standard.set(displayName, forKey: "chat_display_name")
        onComplete()
    }
}
