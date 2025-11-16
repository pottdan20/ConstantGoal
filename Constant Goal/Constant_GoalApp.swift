import SwiftUI

@main
struct Constant_GoalApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = GoalsViewModel()
    
    init() {
        GoalsDataStore.shared.viewModel = viewModel
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
