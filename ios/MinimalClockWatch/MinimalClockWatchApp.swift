import SwiftUI

@main
struct MinimalClockWatchApp: App {
    init() {
        PhoneSyncManager.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
