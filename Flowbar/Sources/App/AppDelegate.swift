import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var popoverManager: PopoverManager!
    var appState: AppState!
    var timerService: TimerService!

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState = AppState()
        timerService = TimerService()
        popoverManager = PopoverManager(appState: appState)

        let mainView = MainView()
            .environmentObject(appState)
            .environmentObject(timerService)
            .environmentObject(popoverManager)

        popoverManager.setContentView(mainView, timerService: timerService)
    }
}
