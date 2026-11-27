import Foundation
import SwiftUI

public struct ModuleRule: Identifiable, Codable {
    public var id = UUID()
    public var ruleType: String // DOMAIN, DOMAIN-SUFFIX, DOMAIN-KEYWORD, IP-CIDR, GEOIP, USER-AGENT, FINAL
    public var value: String
    public var policy: String // DIRECT, REJECT, PROXY, or PolicyGroupName

    public init(ruleType: String, value: String, policy: String) {
        self.ruleType = ruleType
        self.value = value
        self.policy = policy
    }
}

public struct ModuleScriptItem: Identifiable, Codable {
    public var id = UUID()
    public var name: String
    public var scriptType: String // http-request, http-response, cron
    public var pattern: String
    public var scriptSource: String
    public var cronInterval: String?

    public init(name: String, scriptType: String, pattern: String, scriptSource: String, cronInterval: String? = nil) {
        self.name = name
        self.scriptType = scriptType
        self.pattern = pattern
        self.scriptSource = scriptSource
        self.cronInterval = cronInterval
    }
}

public struct ProxyModule: Identifiable, Codable {
    public var id = UUID()
    public var name: String
    public var descriptionText: String
    public var remoteUrl: String?
    public var isEnabled: Bool
    public var rules: [ModuleRule]
    public var rewrites: [URLRewriteRule]
    public var hostOverrides: [String: String]
    public var mitmHostnames: [String]
    public var scripts: [ModuleScriptItem]

    public init(name: String, descriptionText: String, remoteUrl: String? = nil, isEnabled: Bool = true, rules: [ModuleRule] = [], rewrites: [URLRewriteRule] = [], hostOverrides: [String: String] = [:], mitmHostnames: [String] = [], scripts: [ModuleScriptItem] = []) {
        self.name = name
        self.descriptionText = descriptionText
        self.remoteUrl = remoteUrl
        self.isEnabled = isEnabled
        self.rules = rules
        self.rewrites = rewrites
        self.hostOverrides = hostOverrides
        self.mitmHostnames = mitmHostnames
        self.scripts = scripts
    }
}

public class ModuleStore: ObservableObject {
    public static let shared = ModuleStore()
    private let suiteName = "group.com.emsapro.EmsaProxy"
    private let storageKey = "emsa_saved_modules"

    @Published public var modules: [ProxyModule] = []

    public init() {
        loadModules()
        if modules.isEmpty {
            loadDefaultModules()
        }
    }

    public func toggleModule(_ id: UUID) {
        if let idx = modules.firstIndex(where: { $0.id == id }) {
            modules[idx].isEnabled.toggle()
            saveModules()
        }
    }

    public func addModule(_ module: ProxyModule) {
        modules.append(module)
        saveModules()
    }

    public func updateModule(_ module: ProxyModule) {
        if let idx = modules.firstIndex(where: { $0.id == module.id }) {
            modules[idx] = module
            saveModules()
        }
    }

    public func removeModule(at offsets: IndexSet) {
        modules.remove(atOffsets: offsets)
        saveModules()
    }

    public func parseModuleText(raw: String, defaultName: String = "Imported Module", sourceUrl: String? = nil) -> ProxyModule {
        var rules: [ModuleRule] = []
        var rewrites: [URLRewriteRule] = []
        var hostOverrides: [String: String] = [:]
        var mitmHosts: [String] = []
        var scripts: [ModuleScriptItem] = []
        var desc = "Custom imported module"
        var parsedName = defaultName

        var currentSection = ""
        let lines = raw.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix("//") {
                if trimmed.lowercased().contains("!name:") {
                    let parts = trimmed.split(separator: ":")
                    if parts.count > 1 { parsedName = parts[1].trimmingCharacters(in: .whitespaces) }
                } else if trimmed.lowercased().contains("!desc:") {
                    let parts = trimmed.split(separator: ":")
                    if parts.count > 1 { desc = parts[1].trimmingCharacters(in: .whitespaces) }
                }
                continue
            }

            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                currentSection = String(trimmed.dropFirst().dropLast()).uppercased()
                continue
            }

            switch currentSection {
            case "RULE":
                let parts = trimmed.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count >= 3 {
                    rules.append(ModuleRule(ruleType: parts[0], value: parts[1], policy: parts[2]))
                } else if parts.count == 2 {
                    rules.append(ModuleRule(ruleType: parts[0], value: "", policy: parts[1]))
                }
            case "HOST":
                let parts = trimmed.split(separator: "=").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count == 2 {
                    hostOverrides[parts[0]] = parts[1]
                }
            case "URL REWRITE", "REWRITE":
                let parts = trimmed.split(separator: " ").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                if parts.count >= 3 {
                    rewrites.append(URLRewriteRule(regexPattern: parts[0], replacement: parts[1], actionType: parts[2]))
                }
            case "MITM":
                if trimmed.uppercased().hasPrefix("HOSTNAME") {
                    let parts = trimmed.split(separator: "=")
                    if parts.count > 1 {
                        let hosts = parts[1].split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                        mitmHosts.append(contentsOf: hosts)
                    }
                }
            case "SCRIPT":
                let parts = trimmed.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count >= 3 {
                    scripts.append(ModuleScriptItem(name: parts[0], scriptType: "http-response", pattern: parts[1], scriptSource: "// Custom script hook"))
                }
            default:
                break
            }
        }

        return ProxyModule(
            name: parsedName,
            descriptionText: desc,
            remoteUrl: sourceUrl,
            isEnabled: true,
            rules: rules,
            rewrites: rewrites,
            hostOverrides: hostOverrides,
            mitmHostnames: mitmHosts,
            scripts: scripts
        )
    }

    private func saveModules() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(modules) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
            if let sharedDefaults = UserDefaults(suiteName: suiteName) {
                sharedDefaults.set(encoded, forKey: storageKey)
                sharedDefaults.set(modules.filter({ $0.isEnabled }).count, forKey: "active_modules_count")
            }
        }
    }

    private func loadModules() {
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([ProxyModule].self, from: data) {
                self.modules = decoded
            }
        }
    }

    private func loadDefaultModules() {
        let adBlock = ProxyModule(
            name: "AdGuard Tracking & Telemetry Shield",
            descriptionText: "Blokir ribuan pelacak telemetri pihak ketiga, iklan analitik, dan log spyware secara real-time.",
            isEnabled: true,
            rules: [
                ModuleRule(ruleType: "DOMAIN-SUFFIX", value: "google-analytics.com", policy: "REJECT"),
                ModuleRule(ruleType: "DOMAIN-SUFFIX", value: "doubleclick.net", policy: "REJECT"),
                ModuleRule(ruleType: "DOMAIN-SUFFIX", value: "scorecardresearch.com", policy: "REJECT"),
                ModuleRule(ruleType: "DOMAIN-SUFFIX", value: "app-measurement.com", policy: "REJECT"),
                ModuleRule(ruleType: "DOMAIN-KEYWORD", value: "adservice", policy: "REJECT")
            ],
            rewrites: [],
            hostOverrides: [:],
            mitmHostnames: [],
            scripts: []
        )

        let indonesianDirect = ProxyModule(
            name: "Indonesia Direct Traffic Bypass",
            descriptionText: "Rute langsung (DIRECT) untuk domain perbankan, e-wallet, dan CDN lokal Indonesia agar tidak terkena IP luar.",
            isEnabled: true,
            rules: [
                ModuleRule(ruleType: "GEOIP", value: "ID", policy: "DIRECT"),
                ModuleRule(ruleType: "DOMAIN-SUFFIX", value: "bankbsi.co.id", policy: "DIRECT"),
                ModuleRule(ruleType: "DOMAIN-SUFFIX", value: "bca.co.id", policy: "DIRECT"),
                ModuleRule(ruleType: "DOMAIN-SUFFIX", value: "gojek.com", policy: "DIRECT"),
                ModuleRule(ruleType: "DOMAIN-SUFFIX", value: "tokopedia.com", policy: "DIRECT")
            ],
            rewrites: [],
            hostOverrides: [:],
            mitmHostnames: [],
            scripts: []
        )

        let mitmRewrite = ProxyModule(
            name: "HTTPS Header Injector & Masking",
            descriptionText: "Injeksi header khusus privasi dan masking identitas User-Agent untuk host terpilih.",
            isEnabled: false,
            rules: [
                ModuleRule(ruleType: "DOMAIN-KEYWORD", value: "emsapro", policy: "DIRECT")
            ],
            rewrites: [
                URLRewriteRule(regexPattern: "^https?://(.*)/ads/(.*)", replacement: "http://reject", actionType: "reject")
            ],
            hostOverrides: [
                "router.internal": "192.168.1.1"
            ],
            mitmHostnames: ["*.emsapro.id", "*.internal.net"],
            scripts: [
                ModuleScriptItem(
                    name: "PrivacyUserAgent",
                    scriptType: "http-request",
                    pattern: "^https?://(.*)/api/v1",
                    scriptSource: "$request.headers['X-Client-Brand'] = 'EmsaProxy'; $done({headers: $request.headers});"
                )
            ]
        )

        self.modules = [adBlock, indonesianDirect, mitmRewrite]
        saveModules()
    }
}
