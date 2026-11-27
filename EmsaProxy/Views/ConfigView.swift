import SwiftUI

public struct ConfigView: View {
    @ObservedObject var store = ModuleStore.shared
    @State private var copiedAlert = false

    private var activeConfigYAML: String {
        var text = """
        # EmsaProxy Configuration
        # Generated for personal use

        [General]
        ipv4-address = 198.18.0.1
        dns-servers = 1.1.1.1, 8.8.8.8
        routing-mode = rule

        [Rule]
        """
        for mod in store.modules where mod.isEnabled {
            text += "\n# Module: \(mod.name)\n"
            for r in mod.rules {
                text += "\(r.ruleType),\(r.value),\(r.policy)\n"
            }
        }

        text += "\n[MITM]\n"
        var allMitm: [String] = []
        for mod in store.modules where mod.isEnabled {
            allMitm.append(contentsOf: mod.mitmHostnames)
        }
        text += "hostname = \(allMitm.joined(separator: ", "))\n"

        return text
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    Text(activeConfigYAML)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                        .padding()
                }

                HStack {
                    Button(action: {
                        UIPasteboard.general.string = activeConfigYAML
                        copiedAlert = true
                    }) {
                        Label("Copy Config", systemImage: "doc.on.doc")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("Configuration")
            .alert(isPresented: $copiedAlert) {
                Alert(title: Text("Copied"), message: Text("Configuration copied to clipboard."), dismissButton: .default(Text("OK")))
            }
        }
    }
}
