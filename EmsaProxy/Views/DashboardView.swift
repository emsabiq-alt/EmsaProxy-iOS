import SwiftUI

public struct DashboardView: View {
    @ObservedObject var vpn = VPNManager.shared
    @ObservedObject var store = ModuleStore.shared
    @State private var outboundMode: String = "Rule"

    public var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Connection Status Card
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(vpn.isConnected ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                                    .frame(width: 100, height: 100)

                                Image(systemName: vpn.isConnected ? "shield.fill" : "shield.slash.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 48, height: 48)
                                    .foregroundColor(vpn.isConnected ? .green : .gray)
                            }

                            VStack(spacing: 4) {
                                Text(vpn.statusText)
                                    .font(.title2.bold())
                                    .foregroundColor(vpn.isConnected ? .green : .primary)

                                Text(vpn.isConnected ? "TUN Interface: 198.18.0.1" : "Proxy Engine Idle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Button(action: {
                                vpn.toggleTunnel()
                            }) {
                                Text(vpn.isConnected ? "Disconnect" : "Connect")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(vpn.isConnected ? Color.red : Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 24)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)

                        // Outbound Mode Picker
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Outbound Routing Mode")
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .padding(.horizontal)

                            Picker("Outbound Mode", selection: $outboundMode) {
                                Text("Rule").tag("Rule")
                                Text("Global Proxy").tag("Global")
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
                                title: "DNS Servers",
                                value: "1.1.1.1, 8.8.8.8",
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
