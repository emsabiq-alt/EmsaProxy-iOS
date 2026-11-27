import Foundation
import SwiftUI

public enum ProxyType: String, Codable, CaseIterable {
    case shadowsocks = "Shadowsocks"
    case trojan = "Trojan"
    case vless = "VLESS"
    case vmess = "VMess"
    case hysteria2 = "Hysteria2"
    case socks5 = "SOCKS5"
    case http = "HTTP"
    case direct = "DIRECT"
    case reject = "REJECT"
}

public struct ProxyNode: Identifiable, Codable {
    public var id = UUID()
    public var name: String
    public var type: ProxyType
    public var server: String
    public var port: Int
    public var password: String
    public var uuid: String
    public var sni: String
    public var pingMs: Int? // nil = not tested, -1 = timeout

    public init(name: String, type: ProxyType, server: String, port: Int, password: String = "", uuid: String = "", sni: String = "", pingMs: Int? = nil) {
        self.name = name
        self.type = type
        self.server = server
        self.port = port
        self.password = password
        self.uuid = uuid
        self.sni = sni
        self.pingMs = pingMs
    }
}

public enum PolicyGroupType: String, Codable, CaseIterable {
    case select = "Select"
    case autoTest = "Auto-Test (Latency)"
    case fallback = "Fallback"
    case loadBalance = "Load-Balance"
}

public struct PolicyGroup: Identifiable, Codable {
    public var id = UUID()
    public var name: String
    public var type: PolicyGroupType
    public var nodeNames: [String]
    public var selectedNode: String

    public init(name: String, type: PolicyGroupType, nodeNames: [String], selectedNode: String) {
        self.name = name
        self.type = type
        self.nodeNames = nodeNames
        self.selectedNode = selectedNode
    }
}

public struct URLRewriteRule: Identifiable, Codable {
    public var id = UUID()
    public var regexPattern: String
    public var replacement: String
    public var actionType: String // 302, 307, reject, header

    public init(regexPattern: String, replacement: String, actionType: String = "302") {
        self.regexPattern = regexPattern
        self.replacement = replacement
        self.actionType = actionType
    }
}

public struct NetworkConnectionItem: Identifiable, Codable {
    public var id = UUID()
    public var host: String
    public var ip: String
    public var port: Int
    public var matchedRule: String
    public var matchedPolicy: String
    public var uploadBytes: Int
    public var downloadBytes: Int
    public var startTime: Date
    public var isActive: Bool
    public var httpMethod: String?
    public var urlString: String?

    public init(host: String, ip: String, port: Int, matchedRule: String, matchedPolicy: String, uploadBytes: Int = 0, downloadBytes: Int = 0, startTime: Date = Date(), isActive: Bool = true, httpMethod: String? = nil, urlString: String? = nil) {
        self.host = host
        self.ip = ip
        self.port = port
        self.matchedRule = matchedRule
        self.matchedPolicy = matchedPolicy
        self.uploadBytes = uploadBytes
        self.downloadBytes = downloadBytes
        self.startTime = startTime
        self.isActive = isActive
        self.httpMethod = httpMethod
        self.urlString = urlString
    }
}
