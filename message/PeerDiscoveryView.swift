import SwiftUI
import MultipeerConnectivity

struct PeerDiscoveryView: View {
    @EnvironmentObject var chatService: ChatService
    @Binding var isPresented: Bool
    @Binding var selectedTo: String
    @Binding var selectedPeer: MCPeerID?
    
    @State private var isAnimating = false
    @State private var isShowingMyProfile = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text(chatService.isBrowsing ? "Scanning WiFi..." : "Paused")
                        .font(.headline)
                    
                    if chatService.isBrowsing {
                        ProgressView()
                            .padding(.leading, 8)
                    }
                }
                .padding(.top)
                
                Button {
                    chatService.restartDiscovery()
                } label: {
                    Label("Refresh Scan", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .padding(.bottom)
                
                ZStack {
                    // Radar Animation
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        .frame(width: 300, height: 300)
                        .scaleEffect(isAnimating ? 1.5 : 0.1)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
                    
                    Circle()
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        .frame(width: 200, height: 200)
                        .scaleEffect(isAnimating ? 1.5 : 0.1)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(Animation.linear(duration: 2).delay(0.5).repeatForever(autoreverses: false), value: isAnimating)
                    
                    Circle()
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                        .frame(width: 100, height: 100)
                        .scaleEffect(isAnimating ? 1.5 : 0.1)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(Animation.linear(duration: 2).delay(1.0).repeatForever(autoreverses: false), value: isAnimating)
                    
                    // Central Icon
                    Image(systemName: "wifi")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                        .shadow(radius: 5)
                    
                    // Discovered Peers
                    ForEach(Array(chatService.peers.enumerated()), id: \.offset) { index, peer in
                        PeerIcon(peer: peer) {
                            selectedTo = peer.displayName
                            selectedPeer = peer
                            isPresented = false
                        }
                        .offset(peerOffset(index: index, count: chatService.peers.count))
                    }
                }
                .frame(maxHeight: .infinity)
                .onAppear {
                    isAnimating = true
                }
                
                if chatService.peers.isEmpty {
                    VStack(spacing: 16) {
                        Text("No one found yet. Make sure others are on the same WiFi!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Edit My Profile") {
                            isShowingMyProfile = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List(chatService.peers, id: \.self) { peer in
                        Button {
                            selectedTo = peer.displayName
                            selectedPeer = peer
                            isPresented = false
                        } label: {
                            HStack {
                                AvatarView(participant: Participant(firstName: peer.displayName, lastName: "", username: peer.displayName, profileImageLink: nil), size: 40)
                                Text(peer.displayName)
                                    .font(.body)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(height: 200)
                }
            }
            .navigationTitle("Find People")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .sheet(isPresented: $isShowingMyProfile) {
                ProfileView(isPresented: $isShowingMyProfile)
                    .environmentObject(chatService)
            }
        }
    }
    
    private func peerOffset(index: Int, count: Int) -> CGSize {
        let radius: CGFloat = 120
        let angle = Double(index) * (2.0 * .pi / Double(max(1, count)))
        return CGSize(
            width: radius * CGFloat(cos(angle)),
            height: radius * CGFloat(sin(angle))
        )
    }
}

struct PeerIcon: View {
    let peer: MCPeerID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                AvatarView(participant: Participant(firstName: peer.displayName, lastName: "", username: peer.displayName, profileImageLink: nil), size: 50)
                    .shadow(radius: 5)
                Text(peer.displayName)
                    .font(.caption2)
                    .lineLimit(1)
                    .frame(width: 60)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
}
