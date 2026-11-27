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

                ModulesView()
                    .tabItem {
                        Label("Modules", systemImage: "cube.box.fill")
                    }

                ConfigView()
                    .tabItem {
                        Label("Config", systemImage: "slider.horizontal.3")
                    }
            }
        }
    }
}
