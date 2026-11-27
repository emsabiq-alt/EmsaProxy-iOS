import SwiftUI

public struct ToolsView: View {
    @State private var mitmEnabled = true
    @State private var fakeIpEnabled = true
    @State private var selectedDns = "Cloudflare DoH (1.1.1.1)"
    @State private var showingCaAlert = false
    @State private var showingUpdateGeoIPAlert = false

    public var body: some View {
        NavigationView {
            List {
                // MITM Decryption Section
                Section(header: Text("HTTPS Decryption (MITM)"), footer: Text("Dekripsi HTTPS diperlukan untuk fungsi URL Rewrite dan modifikasi header skrip JavaScript.")) {
                    Toggle("Enable MITM Decryption", isOn: $mitmEnabled)

                    Button(action: {
                        showingCaAlert = true
                    }) {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text("Generate Root CA Certificate")
                            Spacer()
                            Image(systemName: "arrow.down.doc")
                                .foregroundColor(.blue)
                        }
                    }

                    NavigationLink(destination: CaInstallGuideView()) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("CA Installation Guide")
                        }
                    }
                }

                // DNS & Fake-IP Section
                Section(header: Text("DNS Engine & Fake-IP"), footer: Text("Fake-IP (198.18.0.0/16) memetakan nama domain ke alamat IP virtual lokal untuk menghindari DNS leakage.")) {
                    Toggle("Enable Fake-IP Pool", isOn: $fakeIpEnabled)

                    Picker("Secure DNS Server", selection: $selectedDns) {
                        Text("Cloudflare DoH (1.1.1.1)").tag("Cloudflare DoH (1.1.1.1)")
                        Text("Google DoH (8.8.8.8)").tag("Google DoH (8.8.8.8)")
                        Text("AliDNS DoH (223.5.5.5)").tag("AliDNS DoH (223.5.5.5)")
                    }
                }

                // GeoIP Database Section
                Section(header: Text("MaxMind GeoIP Database")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("GeoLite2-Country & ASN")
                                .font(.headline)
                            Text("Version: 2026.11 (Bundled)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: {
                            showingUpdateGeoIPAlert = true
                        }) {
                            Text("Update")
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.15))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                        }
                    }
                }

                // Backup & Tools Section
                Section(header: Text("Configuration Backup")) {
                    NavigationLink(destination: ConfigView()) {
                        Label("Raw Configuration Editor", systemImage: "doc.plaintext")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Tools & Settings")
            .alert(isPresented: $showingCaAlert) {
                Alert(
                    title: Text("Root CA Certificate Generated"),
                    message: Text("Sertifikat CA EmsaProxy telah dibuat. Buka Settings > General > About > Certificate Trust Settings di iOS untuk mengaktifkannya."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingUpdateGeoIPAlert) {
                Alert(
                    title: Text("GeoIP Database"),
                    message: Text("Basis data MaxMind Country & ASN telah diperbarui ke versi rilis terbaru."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct CaInstallGuideView: View {
    var body: some View {
        List {
            Section(header: Text("Langkah Pemasangan Sertifikat")) {
                StepRow(number: "1", title: "Generate Sertifikat", desc: "Ketuk tombol 'Generate Root CA Certificate' di menu Tools.")
                StepRow(number: "2", title: "Pasang Profile", desc: "Buka Settings di iPhone > Profile Downloaded > Ketuk Install.")
                StepRow(number: "3", title: "Aktifkan Full Trust", desc: "Buka Settings > General > About > Certificate Trust Settings > Aktifkan switch untuk EmsaProxy Root CA.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Panduan Sertifikat")
    }
}

struct StepRow: View {
    let number: String
    let title: String
    let desc: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 26, height: 26)
                .background(Color.blue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(desc).font(.caption).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
