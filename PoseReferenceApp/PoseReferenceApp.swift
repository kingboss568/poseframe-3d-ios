import SwiftUI

@main
struct PoseReferenceApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var premiumStore = PremiumStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(premiumStore)
                .task {
                    await premiumStore.configure()
                }
        }
    }
}
