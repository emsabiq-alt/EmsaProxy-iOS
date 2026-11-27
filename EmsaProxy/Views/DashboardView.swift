import SwiftUI

public struct DashboardView: View {
    @ObservedObject var vpn = VPNManager.shared
    @ObservedObject var store = ModuleStore.shared
    @ObservedObject var nodeStore = NodeStore.shared
    @ObservedObject var tracker = ConnectionTracker.shared
    @State private var outboundMode: String = "Rule"

    public var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        // Main Connection Card
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(vpn.isConnected ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                                    .frame(width: 90, height: 90)

                                Image(systemName: vpn.isConnected ? "shield.fill" : "shield.slash.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(vpn.isConnected ? .green : .gray)
                            }

                            VStack(spacing: 4) {
                                Text(vpn.statusText)
                                    .font(.title2.bold())
                                    .foregroundColor(vpn.isConnected ? .green : .primary)

                                Text(vpn.isConnected ? "Virtual TUN Interface: 198.18.0.1" : "Tunnel Engine Standby")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            // Real-time Speed Meter (Active when connected)
                            if vpn.isConnected {
                                HStack(spacing: 24) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .foregroundColor(.blue)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(String(format: "%.1f KB/s", tracker.uploadSpeedKbps))
                                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            Text("Upload")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .foregroundColor(.green)
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(String(format: "%.1f KB/s", tracker.downloadSpeedKbps))
                                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                            Text("Download")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }

                            Button(action: {
                                vpn.toggleTunnel()
                            }) {
                                Text(vpn.isConnected ? "Stop Proxy" : "Start Proxy")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(vpn.isConnected ? Color.red : Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Active Proxy Node Selector Card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Active Outbound Node")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                Spacer()
                                NavigationLink(destination: NodesView()) {
                                    Text("Change")
                                        .font(.caption.bold())
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)

                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(nodeStore.selectedProxyName)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Policy: PROXY (Direct routing on bypass rules)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text("38 ms")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                                    .cornerRadius(6)
                            }
                            .padding(14)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // Outbound Mode Picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Outbound Routing Mode")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .padding(.horizontal)

                            Picker("Outbound Mode", selection: $outboundMode) {
                                Text("Rule").tag("Rule")
                                Text("Global").tag("Global")
                                Text("Direct").tag("Direct")
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                        }

                        // Statistics Cards Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            StatCard(
                                title: "Active Modules",
                                value: "\(store.modules.filter({ $0.isEnabled }).count) / \(store.modules.count)",
                                icon: "cube.box.fill",
                                color: .purple
                            )

                            StatCard(
                                title: "Routing Rules",
                                value: "\(totalActiveRules())",
                                icon: "arrow.triangle.branch",
                                color: .orange
                            )

                            StatCard(
                                title: "DNS Engine",
                                value: "Fake-IP DoH",
                                icon: "network",
                                color: .blue
                            )

                            StatCard(
                                title: "MITM Hostnames",
                                value: "\(totalMitmHosts())",
                                icon: "lock.shield.fill",
                                color: .teal
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("EmsaProxy")
        }
    }

    private func totalActiveRules() -> Int {
        return store.modules.filter({ $0.isEnabled }).reduce(0) { $0 + $1.rules.count }
    }

    private func totalMitmHosts() -> Int {
        return store.modules.filter({ $0.isEnabled }).reduce(0) { $0 + $1.mitmHostnames.count }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                Spacer()
            }

            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
