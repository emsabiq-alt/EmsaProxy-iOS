import SwiftUI

public struct ActivityView: View {
    @ObservedObject var tracker = ConnectionTracker.shared
    @State private var filterMode = 0 // 0 = All, 1 = Active, 2 = Blocked
    @State private var searchText = ""
    @State private var selectedConnection: NetworkConnectionItem?

    private var filteredConnections: [NetworkConnectionItem] {
        tracker.connections.filter { conn in
            let matchesSearch = searchText.isEmpty || conn.host.localizedCaseInsensitiveContains(searchText)
            if !matchesSearch { return false }
            if filterMode == 1 { return conn.isActive }
            if filterMode == 2 { return conn.matchedPolicy == "REJECT" }
            return true
        }
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Picker
                Picker("Filter", selection: $filterMode) {
                    Text("All").tag(0)
                    Text("Active").tag(1)
                    Text("Blocked").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                List {
                    ForEach(filteredConnections) { conn in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Circle()
                                    .fill(conn.matchedPolicy == "REJECT" ? Color.red : (conn.isActive ? Color.green : Color.gray))
                                    .frame(width: 8, height: 8)

                                Text(conn.host)
                                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                                    .lineLimit(1)

                                Spacer()

                                Text(conn.matchedPolicy)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(conn.matchedPolicy == "REJECT" ? .red : .blue)
                            }

                            HStack {
                                Text("\(conn.ip):\(conn.port)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)

                                Spacer()

                                HStack(spacing: 10) {
                                    Label(formatBytes(conn.uploadBytes), systemImage: "arrow.up")
                                    Label(formatBytes(conn.downloadBytes), systemImage: "arrow.down")
                                }
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            }

                            Text("Rule: \(conn.matchedRule)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedConnection = conn
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Network Activity")
            .searchable(text: $searchText, prompt: "Search host or domain")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { tracker.clearAll() }) {
                        Image(systemName: "trash")
                    }
                }
            }
            .sheet(item: $selectedConnection) { conn in
                ConnectionDetailSheet(conn: conn)
            }
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024.0) }
        return String(format: "%.2f MB", Double(bytes) / (1024.0 * 1024.0))
    }
}

struct ConnectionDetailSheet: View {
    let conn: NetworkConnectionItem
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Host & Endpoint")) {
                    DetailRow(label: "Host", value: conn.host)
                    DetailRow(label: "IP Address", value: "\(conn.ip):\(conn.port)")
                    DetailRow(label: "Status", value: conn.isActive ? "Active (Connected)" : "Closed")
                }

                Section(header: Text("Routing Decision")) {
                    DetailRow(label: "Matched Rule", value: conn.matchedRule)
                    DetailRow(label: "Outbound Policy", value: conn.matchedPolicy)
                }

                if let url = conn.urlString {
                    Section(header: Text("HTTP Request")) {
                        DetailRow(label: "Method", value: conn.httpMethod ?? "GET")
                        DetailRow(label: "URL", value: url)
                    }
                }

                Section(header: Text("Data Transferred")) {
                    DetailRow(label: "Upload", value: "\(conn.uploadBytes) bytes")
                    DetailRow(label: "Download", value: "\(conn.downloadBytes) bytes")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Connection Info")
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, design: .monospaced))
        }
        .padding(.vertical, 2)
    }
}
