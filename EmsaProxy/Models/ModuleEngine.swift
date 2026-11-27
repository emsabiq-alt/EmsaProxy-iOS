import Foundation
import SwiftUI

public struct ModuleRule: Identifiable, Codable {
    public var id = UUID()
    public var ruleType: String // DOMAIN-SUFFIX, IP-CIDR, GEOIP, USER-AGENT, etc.
    public var value: String
    public var policy: String // DIRECT, REJECT, PROXY

    public init(ruleType: String, value: String, policy: String) {
        self.ruleType = ruleType
        self.value = value
        self.policy = policy
    }
}

public struct ModuleScriptItem: Identifiable, Codable {
    public var id = UUID()
    public var name: String
    public var scriptType: String // http-request, http-response
    public var pattern: String
    public var scriptSource: String

    public init(name: String, scriptType: String, pattern: String, scriptSource: String) {
        self.name = name
        self.scriptType = scriptType
        self.pattern = pattern
        self.scriptSource = scriptSource
    }
}

public struct ProxyModule: Identifiable, Codable {
    public var id = UUID()
    public var name: String
    public var descriptionText: String
    public var isEnabled: Bool
    public var rules: [ModuleRule]
    public var mitmHostnames: [String]
    public var scripts: [ModuleScriptItem]

    public init(name: String, descriptionText: String, isEnabled: Bool = true, rules: [ModuleRule] = [], mitmHostnames: [String] = [], scripts: [ModuleScriptItem] = []) {
        self.name = name
        self.descriptionText = descriptionText
        self.isEnabled = isEnabled
        self.rules = rules
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

    public func removeModule(at offsets: IndexSet) {
        modules.remove(atOffsets: offsets)
        saveModules()
    }

    public func parseModuleText(raw: String, defaultName: String = "Imported Module") -> ProxyModule {
        var rules: [ModuleRule] = []
        var mitmHosts: [String] = []
        var scripts: [ModuleScriptItem] = []
        var desc = "Custom imported module"

        var currentSection = ""
        let lines = raw.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix("//") {
                if trimmed.lowercased().contains("desc:") || trimmed.lowercased().contains("name:") {
                    desc = trimmed
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
                if parts.count >= 2 {
                    scripts.append(ModuleScriptItem(name: parts[0], scriptType: "http-response", pattern: parts[1], scriptSource: "// Custom script"))
                }
            default:
                break
            }
        }

        return ProxyModule(name: defaultName, descriptionText: desc, isEnabled: true, rules: rules, mitmHostnames: mitmHosts, scripts: scripts)
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
            name: "AdGuard Tracking Shield",
            descriptionText: "Blokir pelacak telemetri dan analitik pihak ketiga secara otomatis.",
            isEnabled: true,
            rules: [
                ModuleRule(ruleType: "DOMAIN-SUFFIX", value: "google-analytics.com", policy: "REJECT"),
                ModuleRule(ruleType: "DOMAIN-SUFFIX", value: "doubleclick.net", policy: "REJECT"),
                ModuleRule(ruleType: "DOMAIN-SUFFIX", value: "scorecardresearch.com", policy: "REJECT")
            ],
            mitmHostnames: [],
            scripts: []
        )

        let mitmRewrite = ProxyModule(
            name: "HTTPS Header Modifier",
            descriptionText: "Injeksi custom User-Agent dan header HTTP request untuk privasi.",
            isEnabled: true,
            rules: [
                ModuleRule(ruleType: "DOMAIN-KEYWORD", value: "api-internal", policy: "DIRECT")
            ],
            mitmHostnames: ["*.emsapro.id", "*.internal.net"],
            scripts: [
                ModuleScriptItem(
                    name: "UserAgentMask",
                    scriptType: "http-request",
                    pattern: "^https?://api-internal",
                    scriptSource: "$request.headers['X-Client-Brand'] = 'EmsaProxy'; $done({headers: $request.headers});"
                )
            ]
        )

        self.modules = [adBlock, mitmRewrite]
        saveModules()
    }
}
