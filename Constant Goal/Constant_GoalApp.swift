import SwiftUI

@main
struct Constant_GoalApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel: GoalsViewModel

    init() {
        let vm = GoalsViewModel()
        _viewModel = StateObject(wrappedValue: vm)
        // 🔗 Wire the shared view model into the data store ONCE
        GoalsDataStore.shared.viewModel = vm
        print("✅ Wired GoalsDataStore.viewModel in App init")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)  // same instance everywhere
        }
    }
}
