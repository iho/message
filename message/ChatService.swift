import Foundation
import MultipeerConnectivity
import Combine
#if os(iOS)
import UIKit
#endif

class ChatService: NSObject, ObservableObject {
    private let serviceType = "hubchat"
    @Published var peers: [MCPeerID] = []
    @Published var connectedPeerNames: Set<String> = []
    @Published var receivedMessages: [String: [Message]] = [:]
    
    // Mapping of Name -> Active PeerID to handle reconnections
    private var activePeersByName: [String: MCPeerID] = [:]
    @Published var displayName: String = "" {
        didSet {
            let sanitized = sanitize(displayName)
            if sanitized != displayName {
                displayName = sanitized
                return
            }
            if !isInitializing {
                UserDefaults.standard.set(displayName, forKey: "chat_display_name")
                setupNetworking()
            }
        }
    }
    
    private var isInitializing = true
    
    private func sanitize(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let filtered = name.components(separatedBy: allowed.inverted).joined()
        let truncated = String(filtered.prefix(15))
        return truncated.isEmpty ? "Guest" : truncated
    }
    @Published var isAdvertising: Bool = false
    @Published var isBrowsing: Bool = false
    
    @Published var isDiscoverable: Bool = true {
        didSet {
            if isDiscoverable {
                startAdvertising()
            } else {
                stopAdvertising()
            }
        }
    }
    
    private var myPeerId: MCPeerID!
    private var serviceAdvertiser: MCNearbyServiceAdvertiser?
    private var serviceBrowser: MCNearbyServiceBrowser?
    private var session: MCSession?
    private var pendingStartWorkItem: DispatchWorkItem?
    private var heartbeatTimer: Timer?
    
    override init() {
        super.init()
        let rawName = UserDefaults.standard.string(forKey: "chat_display_name") ?? defaultDeviceName()
        let finalName = sanitize(rawName)
        self.displayName = finalName
        self.isInitializing = false
        
        print("--- ChatService Starting ---")
        print("Final Peer Name: \(finalName)")
        print("Service Type: \(serviceType)")
        
        setupNetworking()
    }
    
    private func defaultDeviceName() -> String {
        let randomSuffix = String(Int.random(in: 100...999))
        #if os(iOS)
        let baseName = UIDevice.current.name
        #else
        let baseName = Host.current().localizedName ?? "Mac"
        #endif
        return sanitize("\(baseName) #\(randomSuffix)")
    }
    
    func restartDiscovery() {
        print("Manual discovery restart requested...")
        setupNetworking()
    }
    
    var localConversations: [Conversation] {
        activePeersByName.keys.sorted().map { name in
            let participant = Participant(firstName: name, lastName: "", username: name, profileImageLink: nil)
            return Conversation(
                participants: [participant],
                messages: receivedMessages[name] ?? [],
                updatedAt: Date(),
                isRead: true,
                isPinned: false,
                profileImageLink: nil
            )
        }
    }

    private func setupNetworking() {
        print("--- ChatService Setup ---")
        
        // 0. LOG INTERFACE STATE (Helps see if we actually have WiFi IP)
        #if os(iOS)
        print("Interface Log: \(UIDevice.current.name) is initializing...")
        #else
        print("Interface Log: \(Host.current().localizedName ?? "Mac") is initializing...")
        #endif

        // 1. Cancel any pending start
        pendingStartWorkItem?.cancel()
        
        // 2. Tear down old state
        stopAdvertising()
        stopBrowsing()
        session?.disconnect()
        session = nil
        serviceAdvertiser = nil
        serviceBrowser = nil
        
        DispatchQueue.main.async {
            self.peers.removeAll()
            self.connectedPeerNames.removeAll()
            self.activePeersByName.removeAll()
        }
        
        // 3. Init new networking components
        self.myPeerId = MCPeerID(displayName: displayName)
        print("Peer: \(displayName), Type: \(serviceType)")

        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .none)
        self.session?.delegate = self
        
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
        self.serviceAdvertiser?.delegate = self
        
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
        self.serviceBrowser?.delegate = self
        
        // 4. Create a single work item for startup to avoid multiple overlapping starts
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if self.isDiscoverable {
                print("Final Start: Advertising...")
                self.startAdvertising()
            }
            print("Final Start: Browsing...")
            self.startBrowsing()
        }
        
        self.pendingStartWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: workItem)
        
        startHeartbeat()
    }
    
    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.connectedPeerNames.isEmpty {
                print("--- NETWORK HEARTBEAT ---")
                print("Status: \(self.isAdvertising ? "Advertising" : "Off"), \(self.isBrowsing ? "Browsing" : "Off")")
                print("Peer Name: \(self.displayName)")
                print("Visible Peers Count: \(self.peers.count)")
            }
        }
    }
    
    private func startAdvertising() {
        print("Starting advertising...")
        serviceAdvertiser?.startAdvertisingPeer()
        isAdvertising = true
    }
    
    private func stopAdvertising() {
        print("Stopping advertising...")
        serviceAdvertiser?.stopAdvertisingPeer()
        isAdvertising = false
    }
    
    private func startBrowsing() {
        print("Starting browsing...")
        serviceBrowser?.startBrowsingForPeers()
        isBrowsing = true
    }
    
    private func stopBrowsing() {
        print("Stopping browsing...")
        serviceBrowser?.stopBrowsingForPeers()
        isBrowsing = false
    }
    
    func send(text: String, toPeerNamed name: String) {
        if let peer = activePeersByName[name] {
            send(text: text, to: peer)
        } else {
            print("⚠️ Cannot send message: No active peerID found for name '\(name)'")
        }
    }
    
    func send(text: String, to peer: MCPeerID) {
        let author = Participant(firstName: self.displayName, lastName: "", username: self.displayName, profileImageLink: nil)
        let message = Message(text: text, createdAt: Date(), author: author)
        
        guard let session = session else {
            print("⚠️ No session available to send message")
            return
        }
        
        if let data = text.data(using: .utf8) {
            do {
                try session.send(data, toPeers: [peer], with: .reliable)
                print("📤 Sent message to \(peer.displayName)")
                appendMessage(message, for: peer)
            } catch {
                print("❌ Error sending message to \(peer.displayName): \(error.localizedDescription)")
            }
        }
    }
    
    private func appendMessage(_ message: Message, for peer: MCPeerID) {
        DispatchQueue.main.async {
            self.receivedMessages[peer.displayName, default: []].append(message)
        }
    }
}

extension ChatService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("📩 Received invitation from \(peerID.displayName)")
        invitationHandler(true, self.session)
        print("✅ Accepted invitation from \(peerID.displayName)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("!!! Advertiser Error: \(error.localizedDescription) (\(error))")
        stopAdvertising()
    }
}

extension ChatService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("🔍 Browser FOUND peer: \(peerID.displayName)")
        
        DispatchQueue.main.async {
            // Remove any old MCPeerID that had this same name
            self.peers.removeAll { $0.displayName == peerID.displayName && $0 != peerID }
            
            if !self.peers.contains(peerID) {
                print("➕ ADDING \(peerID.displayName) to list")
                self.peers.append(peerID)
            }
            // Always update the mapping to the latest peerID found for this name
            self.activePeersByName[peerID.displayName] = peerID
        }
        
        guard let session = self.session else { return }
        print("🤝 INVITING \(peerID.displayName)...")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("➖ LOST peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.peers.removeAll { $0 == peerID }
            self.connectedPeerNames.remove(peerID.displayName)
            if self.activePeersByName[peerID.displayName] == peerID {
                self.activePeersByName.removeValue(forKey: peerID.displayName)
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("!!! Browser Error: \(error.localizedDescription) (\(error))")
        stopBrowsing()
    }
}

extension ChatService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        var stateString = "unknown"
        switch state {
        case .connected: stateString = "connected"
        case .connecting: stateString = "connecting"
        case .notConnected: stateString = "notConnected"
        @unknown default: stateString = "unknown"
        }
        print("🔄 Peer \(peerID.displayName) changed state to \(stateString)")
        
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.connectedPeerNames.insert(peerID.displayName)
                self.activePeersByName[peerID.displayName] = peerID
            case .notConnected:
                self.connectedPeerNames.remove(peerID.displayName)
            default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let text = String(data: data, encoding: .utf8) {
            let author = Participant(firstName: peerID.displayName, lastName: "", username: peerID.displayName, profileImageLink: nil)
            let message = Message(text: text, createdAt: Date(), author: author)
            appendMessage(message, for: peerID)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Received stream from \(peerID.displayName): \(streamName)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Starting to receive resource from \(peerID.displayName): \(resourceName)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        if let error = error {
            print("Error receiving resource from \(peerID.displayName): \(error.localizedDescription)")
        } else {
            print("Finished receiving resource from \(peerID.displayName) at \(localURL?.path ?? "unknown path")")
        }
    }
}
