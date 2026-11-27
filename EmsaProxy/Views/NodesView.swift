import SwiftUI

public struct NodesView: View {
    @ObservedObject var nodeStore = NodeStore.shared
    @State private var showingAddNodeSheet = false

    public var body: some View {
        NavigationView {
            List {
                // Policy Groups Section
                Section(header: Text("Policy Groups")) {
                    ForEach(nodeStore.policyGroups) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(group.name)
                                    .font(.headline)
                                Spacer()
                                Text(group.type.rawValue)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                            }

                            Text("Selected: \(group.selectedNode)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Proxy Nodes Section
                Section(header: HStack {
                    Text("Outbound Proxy Nodes (\(nodeStore.nodes.count))")
                    Spacer()
                    Button(action: {
                        nodeStore.testAllLatencies()
                    }) {
                        Label("Test All", systemImage: "bolt.fill")
                            .font(.caption.bold())
                    }
                }) {
                    ForEach(nodeStore.nodes) { node in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text(node.name)
                                        .font(.system(size: 15, weight: .semibold))

                                    if node.name == nodeStore.selectedProxyName {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    }
                                }

                                HStack(spacing: 6) {
                                    Text(node.type.rawValue.uppercased())
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.purple.opacity(0.15))
                                        .foregroundColor(.purple)
                                        .cornerRadius(4)

                                    Text("\(node.server):\(node.port)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            // Ping badge
                            if let ping = node.pingMs {
                                Text("\(ping) ms")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(ping < 80 ? .green : (ping < 150 ? .orange : .red))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(UIColor.tertiarySystemGroupedBackground))
                                    .cornerRadius(6)
                            } else {
                                Text("-- ms")
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            nodeStore.selectNode(node.name)
                        }
                    }
                    .onDelete(perform: nodeStore.removeNode)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Nodes & Policies")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddNodeSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddNodeSheet) {
                AddNodeSheet(nodeStore: nodeStore)
            }
        }
    }
}

struct AddNodeSheet: View {
    @ObservedObject var nodeStore: NodeStore
    @Environment(\.presentationMode) var presentationMode
    @State private var name: String = ""
    @State private var type: ProxyType = .trojan
    @State private var server: String = ""
    @State private var port: String = "443"
    @State private var password: String = ""
    @State private var sni: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Node Details")) {
                    TextField("Node Name (e.g. SG Fast)", text: $name)
                    Picker("Protocol", selection: $type) {
                        ForEach(ProxyType.allCases.filter { $0 != .direct && $0 != .reject }, id: \.self) { t in
                            Text(t.rawValue).tag(t)
                        }
                    }
                    TextField("Server Host / IP", text: $server)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }

                Section(header: Text("Security & TLS")) {
                    SecureField("Password / UUID", text: $password)
                    TextField("SNI (Server Name Indication)", text: $sni)
                }
            }
            .navigationTitle("Add Proxy Node")
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") {
                    let p = Int(port) ?? 443
                    let node = ProxyNode(
                        name: name.isEmpty ? "Proxy Node" : name,
                        type: type,
                        server: server.isEmpty ? "127.0.0.1" : server,
                        port: p,
                        password: password,
                        sni: sni.isEmpty ? server : sni,
                        pingMs: nil
                    )
                    nodeStore.addNode(node)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}
