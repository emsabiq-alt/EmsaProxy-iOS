import Foundation
import SwiftUI

public class NodeStore: ObservableObject {
    public static let shared = NodeStore()
    private let suiteName = "group.com.emsapro.EmsaProxy"
    private let storageKeyNodes = "emsa_saved_nodes"
    private let storageKeyPolicies = "emsa_saved_policies"

    @Published public var nodes: [ProxyNode] = []
    @Published public var policyGroups: [PolicyGroup] = []
    @Published public var selectedProxyName: String = "SG - Singapore Premium"

    public init() {
        loadData()
        if nodes.isEmpty {
            loadDefaultNodes()
        }
    }

    public func addNode(_ node: ProxyNode) {
        nodes.append(node)
        saveData()
    }

    public func removeNode(at offsets: IndexSet) {
        nodes.remove(atOffsets: offsets)
        saveData()
    }

    public func testLatency(for node: ProxyNode) {
        guard let idx = nodes.firstIndex(where: { $0.id == node.id }) else { return }
        // Simulate real latency test
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let latency = Int.random(in: 25...140)
            self.nodes[idx].pingMs = latency
            self.saveData()
        }
    }

    public func testAllLatencies() {
        for node in nodes {
            testLatency(for: node)
        }
    }

    public func selectNode(_ name: String) {
        self.selectedProxyName = name
        if let idx = policyGroups.firstIndex(where: { $0.name == "PROXY" }) {
            policyGroups[idx].selectedNode = name
        }
        saveData()
    }

    private func saveData() {
        let encoder = JSONEncoder()
        if let encodedNodes = try? encoder.encode(nodes) {
            UserDefaults.standard.set(encodedNodes, forKey: storageKeyNodes)
            UserDefaults(suiteName: suiteName)?.set(encodedNodes, forKey: storageKeyNodes)
        }
        if let encodedPolicies = try? encoder.encode(policyGroups) {
            UserDefaults.standard.set(encodedPolicies, forKey: storageKeyPolicies)
            UserDefaults(suiteName: suiteName)?.set(encodedPolicies, forKey: storageKeyPolicies)
        }
        UserDefaults(suiteName: suiteName)?.set(selectedProxyName, forKey: "active_proxy_name")
    }

    private func loadData() {
        let decoder = JSONDecoder()
        if let dataNodes = UserDefaults.standard.data(forKey: storageKeyNodes),
           let decoded = try? decoder.decode([ProxyNode].self, from: dataNodes) {
            self.nodes = decoded
        }
        if let dataPolicies = UserDefaults.standard.data(forKey: storageKeyPolicies),
           let decoded = try? decoder.decode([PolicyGroup].self, from: dataPolicies) {
            self.policyGroups = decoded
        }
        if let savedName = UserDefaults(suiteName: suiteName)?.string(forKey: "active_proxy_name") {
            self.selectedProxyName = savedName
        }
    }

    private func loadDefaultNodes() {
        let node1 = ProxyNode(name: "SG - Singapore Premium", type: .trojan, server: "sg1.emsapro.net", port: 443, password: "emsa-secure-pass", sni: "sg1.emsapro.net", pingMs: 38)
        let node2 = ProxyNode(name: "ID - Jakarta Telkom Cloud", type: .vless, server: "id-jkt.emsapro.net", port: 443, uuid: "b2184e56-91b3-46ea-bb22-834923e10811", sni: "id-jkt.emsapro.net", pingMs: 12)
        let node3 = ProxyNode(name: "JP - Tokyo Fast Stream", type: .hysteria2, server: "jp.emsapro.net", port: 8443, password: "emsa-pass-tokyo", sni: "jp.emsapro.net", pingMs: 86)
        let node4 = ProxyNode(name: "US - Silicon Valley Direct", type: .shadowsocks, server: "us-sv.emsapro.net", port: 8388, password: "aes-256-gcm:secret", pingMs: 165)

        self.nodes = [node1, node2, node3, node4]

        let group1 = PolicyGroup(name: "PROXY", type: .select, nodeNames: nodes.map { $0.name }, selectedNode: node1.name)
        let group2 = PolicyGroup(name: "AUTO", type: .autoTest, nodeNames: nodes.map { $0.name }, selectedNode: node2.name)

        self.policyGroups = [group1, group2]
        saveData()
    }
}
