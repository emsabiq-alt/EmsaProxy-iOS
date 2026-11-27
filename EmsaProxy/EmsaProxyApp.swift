import SwiftUI

@main
public struct EmsaProxyApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Dashboard", systemImage: "shield.fill")
                    }

                NodesView()
                    .tabItem {
                        Label("Nodes", systemImage: "antenna.radiowaves.left.and.right")
                    }

                ModulesView()
                    .tabItem {
                        Label("Modules", systemImage: "cube.box.fill")
                    }

                ActivityView()
                    .tabItem {
                        Label("Activity", systemImage: "waveform.path.ecg")
                    }

                ToolsView()
                    .tabItem {
                        Label("Tools", systemImage: "wrench.and.screwdriver.fill")
                    }
            }
        }
    }
}
