import Foundation
import NetworkExtension

public class VPNManager: ObservableObject {
    public static let shared = VPNManager()

    @Published public var isConnected: Bool = false
    @Published public var statusText: String = "Disconnected"
    private var providerManager: NETunnelProviderManager?

    public init() {
        loadManager()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusDidChange),
            name: .NEVPNStatusDidChange,
            object: nil
        )
    }

    public func loadManager() {
        NETunnelProviderManager.loadAllFromPreferences { [weak self] managers, error in
            guard let self = self else { return }
            if let manager = managers?.first {
                self.providerManager = manager
                self.updateStatus(manager.connection.status)
            } else {
                self.createManager()
            }
        }
    }

    private func createManager() {
        let manager = NETunnelProviderManager()
        let proto = NETunnelProviderProtocol()
        let parentId = Bundle.main.bundleIdentifier ?? "com.emsapro.EmsaProxy"
        proto.providerBundleIdentifier = "\(parentId).Tunnel"
        proto.serverAddress = "127.0.0.1"
        manager.protocolConfiguration = proto
        manager.localizedDescription = "EmsaProxy"
        manager.isEnabled = true

        manager.saveToPreferences { [weak self] error in
            if error == nil {
                self?.providerManager = manager
            }
        }
    }

    public func toggleTunnel() {
        guard let manager = providerManager else {
            createManager()
            return
        }

        manager.loadFromPreferences { [weak self] _ in
            guard let self = self else { return }
            let status = manager.connection.status
            if status == .connected || status == .connecting {
                manager.connection.stopVPNTunnel()
            } else {
                do {
                    try manager.connection.startVPNTunnel()
                } catch {
                    NSLog("[EmsaProxy] Error starting VPN: %@", error.localizedDescription)
                }
            }
        }
    }

    @objc private func vpnStatusDidChange() {
        if let manager = providerManager {
            DispatchQueue.main.async {
                self.updateStatus(manager.connection.status)
            }
        }
    }

    private func updateStatus(_ status: NEVPNStatus) {
        switch status {
        case .connected:
            self.isConnected = true
            self.statusText = "Connected"
        case .connecting:
            self.isConnected = false
            self.statusText = "Connecting..."
        case .disconnecting:
            self.isConnected = false
            self.statusText = "Disconnecting..."
        case .disconnected, .invalid:
            self.isConnected = false
            self.statusText = "Disconnected"
        case .reasserting:
            self.isConnected = true
            self.statusText = "Reconnecting..."
        @unknown default:
            self.isConnected = false
            self.statusText = "Unknown"
        }
    }
}
