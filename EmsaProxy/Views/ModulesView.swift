import SwiftUI

public struct ModulesView: View {
    @ObservedObject var store = ModuleStore.shared
    @State private var showingAddSheet = false
    @State private var selectedModule: ProxyModule?

    public var body: some View {
        NavigationView {
            List {
                Section(header: Text("Active Modules"), footer: Text("Modul memperluas kemampuan perutean EmsaProxy dengan aturan routing, URL rewrites, host mappings, MITM HTTPS, dan skrip JavaScriptCore.")) {
                    ForEach(store.modules) { module in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(module.name)
                                    .font(.headline)

                                Text(module.descriptionText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)

                                HStack(spacing: 6) {
                                    BadgeView(text: "\(module.rules.count) Rules", color: .orange)
                                    if !module.rewrites.isEmpty {
                                        BadgeView(text: "\(module.rewrites.count) Rewrites", color: .blue)
                                    }
                                    if !module.mitmHostnames.isEmpty {
                                        BadgeView(text: "\(module.mitmHostnames.count) MITM", color: .teal)
                                    }
                                    if !module.scripts.isEmpty {
                                        BadgeView(text: "\(module.scripts.count) Scripts", color: .purple)
                                    }
                                }
                                .padding(.top, 2)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { module.isEnabled },
                                set: { _ in store.toggleModule(module.id) }
                            ))
                            .labelsHidden()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedModule = module
                        }
                    }
                    .onDelete(perform: store.removeModule)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Modules")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddModuleSheet(store: store)
            }
            .sheet(item: $selectedModule) { mod in
                ModuleDetailSheet(module: mod)
            }
        }
    }
}

struct BadgeView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

struct AddModuleSheet: View {
    @ObservedObject var store: ModuleStore
    @Environment(\.presentationMode) var presentationMode
    @State private var mode = 0 // 0 = URL, 1 = Raw Text
    @State private var moduleName: String = ""
    @State private var urlString: String = ""
    @State private var moduleContent: String = ""

    var body: some View {
        NavigationView {
            Form {
                Picker("Import Mode", selection: $mode) {
                    Text("Remote URL").tag(0)
                    Text("Direct Text").tag(1)
                }
                .pickerStyle(.segmented)

                if mode == 0 {
                    Section(header: Text("Remote Module URL"), footer: Text("Mendukung tautan modul Egern (.module), Surge (.sgmodule), atau Shadowrocket (.conf).")) {
                        TextField("https://raw.githubusercontent.com/.../adblock.module", text: $urlString)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                        TextField("Display Name (Optional)", text: $moduleName)
                    }
                } else {
                    Section(header: Text("Module Specification"), footer: Text("Dukung format blok [Rule], [URL Rewrite], [Host], [MITM], dan [Script].")) {
                        TextField("Module Name (e.g. TikTok Unlock)", text: $moduleName)
                        TextEditor(text: $moduleContent)
                            .frame(minHeight: 180)
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
            .navigationTitle("Import Module")
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Save") {
                    let name = moduleName.isEmpty ? (mode == 0 ? "Remote Subscription" : "Custom Module") : moduleName
                    let mod: ProxyModule
                    if mode == 0 {
                        mod = ProxyModule(name: name, descriptionText: "Imported from \(urlString)", remoteUrl: urlString, isEnabled: true)
                    } else {
                        mod = store.parseModuleText(raw: moduleContent, defaultName: name)
                    }
                    store.addModule(mod)
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct ModuleDetailSheet: View {
    let module: ProxyModule
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Overview")) {
                    LabeledRow(label: "Status", value: module.isEnabled ? "Active (Enabled)" : "Disabled")
                    LabeledRow(label: "Description", value: module.descriptionText)
                    if let url = module.remoteUrl {
                        LabeledRow(label: "Source URL", value: url)
                    }
                }

                if !module.rules.isEmpty {
                    Section(header: Text("Routing Rules (\(module.rules.count))")) {
                        ForEach(module.rules) { rule in
                            HStack {
                                Text(rule.ruleType)
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Text(rule.value)
                                    .font(.system(size: 13, design: .monospaced))
                                Spacer()
                                Text(rule.policy)
                                    .font(.caption.bold())
                                    .foregroundColor(rule.policy == "REJECT" ? .red : (rule.policy == "DIRECT" ? .green : .blue))
                            }
                        }
                    }
                }

                if !module.rewrites.isEmpty {
                    Section(header: Text("URL Rewrites (\(module.rewrites.count))")) {
                        ForEach(module.rewrites) { rw in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(rw.actionType.uppercased())
                                        .font(.system(size: 10, weight: .bold))
                                        .padding(.horizontal, 4)
                                        .background(Color.blue.opacity(0.15))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                    Text(rw.regexPattern)
                                        .font(.system(size: 12, design: .monospaced))
                                }
                                Text("-> \(rw.replacement)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                if !module.hostOverrides.isEmpty {
                    Section(header: Text("Host Mappings (\(module.hostOverrides.count))")) {
                        ForEach(Array(module.hostOverrides.keys), id: \.self) { host in
                            HStack {
                                Text(host).font(.system(size: 13, design: .monospaced))
                                Spacer()
                                Text(module.hostOverrides[host] ?? "").font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }

                if !module.mitmHostnames.isEmpty {
                    Section(header: Text("MITM Hostnames (\(module.mitmHostnames.count))")) {
                        ForEach(module.mitmHostnames, id: \.self) { host in
                            Text(host)
                                .font(.system(size: 13, design: .monospaced))
                        }
                    }
                }

                if !module.scripts.isEmpty {
                    Section(header: Text("JavaScriptCore Scripts (\(module.scripts.count))")) {
                        ForEach(module.scripts) { script in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(script.name).font(.headline)
                                Text("Type: \(script.scriptType) | Pattern: \(script.pattern)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(module.name)
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
    }
}

struct LabeledRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value)
        }
    }
}
