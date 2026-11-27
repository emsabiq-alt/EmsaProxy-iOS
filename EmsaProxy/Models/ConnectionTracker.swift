import Foundation
import SwiftUI

public class ConnectionTracker: ObservableObject {
    public static let shared = ConnectionTracker()

    @Published public var connections: [NetworkConnectionItem] = []
    @Published public var uploadSpeedKbps: Double = 0.0
    @Published public var downloadSpeedKbps: Double = 0.0
    private var timer: Timer?

    public init() {
        generateInitialMockTraffic()
        startTrafficSimulation()
    }

    public func clearAll() {
        connections.removeAll()
    }

    private func generateInitialMockTraffic() {
        let conn1 = NetworkConnectionItem(
            host: "api.github.com",
            ip: "140.82.121.4",
            port: 443,
            matchedRule: "DOMAIN-SUFFIX, github.com, PROXY",
            matchedPolicy: "PROXY (SG - Singapore Premium)",
            uploadBytes: 12480,
            downloadBytes: 98450,
            startTime: Date().addingTimeInterval(-35),
            isActive: true,
            httpMethod: "POST",
            urlString: "https://api.github.com/graphql"
        )

        let conn2 = NetworkConnectionItem(
            host: "www.google-analytics.com",
            ip: "142.250.190.46",
            port: 443,
            matchedRule: "DOMAIN-SUFFIX, google-analytics.com, REJECT",
            matchedPolicy: "REJECT",
            uploadBytes: 0,
            downloadBytes: 0,
            startTime: Date().addingTimeInterval(-120),
            isActive: false,
            httpMethod: "GET",
            urlString: "https://www.google-analytics.com/g/collect"
        )

        let conn3 = NetworkConnectionItem(
            host: "api-internal.emsapro.id",
            ip: "103.144.112.2",
            port: 443,
            matchedRule: "DOMAIN-SUFFIX, emsapro.id, DIRECT",
            matchedPolicy: "DIRECT",
            uploadBytes: 4210,
            downloadBytes: 15400,
            startTime: Date().addingTimeInterval(-6),
            isActive: true,
            httpMethod: "GET",
            urlString: "https://api-internal.emsapro.id/v1/auth/session"
        )

        connections = [conn1, conn2, conn3]
    }

    private func startTrafficSimulation() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.uploadSpeedKbps = Double.random(in: 12.4...450.8)
            self.downloadSpeedKbps = Double.random(in: 88.5...2450.2)
        }
    }
}
