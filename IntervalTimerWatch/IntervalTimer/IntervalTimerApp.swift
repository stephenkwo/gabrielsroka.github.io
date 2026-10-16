import SwiftUI

@main
struct IntervalTimerApp: App {
    @StateObject private var timer = IntervalTimer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(timer)
        }
    }
}
