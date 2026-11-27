import Foundation
import NetworkExtension

public class PacketTunnelProvider: NEPacketTunnelProvider {
    private let scriptEngine = ScriptRuntime()
    private var isRunning = false
    private let suiteName = "group.com.emsapro.EmsaProxy"

    public override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        NSLog("[EmsaProxyTunnel] Starting tunnel provider...")

        let tunnelSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")

        // Configure Virtual Interface IPv4
        let ipv4 = NEIPv4Settings(addresses: ["198.18.0.1"], subnetMasks: ["255.255.0.0"])
        ipv4.includedRoutes = [NEIPv4Route.default()]
        tunnelSettings.ipv4Settings = ipv4

        // DNS Configuration
        let dns = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        dns.matchDomains = [""]
        tunnelSettings.dnsSettings = dns

        setTunnelNetworkSettings(tunnelSettings) { [weak self] error in
            if let error = error {
                NSLog("[EmsaProxyTunnel] Failed to apply network settings: %@", error.localizedDescription)
                completionHandler(error)
                return
            }

            self?.isRunning = true
            self?.loadSharedModules()
            self?.startPacketProcessing()
            NSLog("[EmsaProxyTunnel] Tunnel successfully active on 198.18.0.1.")
            completionHandler(nil)
        }
    }

    private func loadSharedModules() {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        let activeCount = defaults.integer(forKey: "active_modules_count")
        NSLog("[EmsaProxyTunnel] Loaded %d active modules from shared container.", activeCount)
    }

    private func startPacketProcessing() {
        guard isRunning else { return }

        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self, self.isRunning else { return }

            // Packet dispatcher: process Layer 3 IP packets
            // Forward/inspect according to active Module Rules
            for packet in packets {
                self.processIPPacket(packet)
            }

            self.startPacketProcessing()
        }
    }

    private func processIPPacket(_ packet: Data) {
        // Minimal IP header inspection (IPv4 version = 4)
        guard packet.count >= 20 else { return }
        let version = (packet[0] >> 4) & 0x0F
        if version == 4 {
            let protocolNum = packet[9]
            _ = protocolNum // 6 for TCP, 17 for UDP
        }
    }

    public override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        NSLog("[EmsaProxyTunnel] Stopping tunnel (reason: %ld)...", reason.rawValue)
        isRunning = false
        completionHandler()
    }
}
