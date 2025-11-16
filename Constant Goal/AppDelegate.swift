import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification auth error: \(error)")
            } else {
                print("Notifications granted: \(granted)")
            }
        }
        
        registerNotificationCategories()
        return true
    }
    
    private func registerNotificationCategories() {
        let yesAction = UNNotificationAction(
            identifier: "YES_ACTION",
            title: "Yes",
            options: []
        )
        
        let noAction = UNNotificationAction(
            identifier: "NO_ACTION",
            title: "No",
            options: [.destructive]
        )
        
        let category = UNNotificationCategory(
            identifier: "YES_NO_CATEGORY",
            actions: [yesAction, noAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
    
    // Show notification while app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("👀 willPresent fired for id: \(notification.request.identifier)")
        let userInfo = notification.request.content.userInfo
        print("   userInfo in willPresent: \(userInfo)")
        
        if let goalIdString = userInfo["goalId"] as? String,
           let goalId = UUID(uuidString: goalIdString) {
            GoalsDataStore.shared.handleNotificationFired(for: goalId)
        }
        
        completionHandler([.banner, .sound, .badge])
    }

    // Handle user tapping Yes / No
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("🎯 didReceive response: \(response.actionIdentifier)")
        
        let userInfo = response.notification.request.content.userInfo
        print("   userInfo in didReceive: \(userInfo)")
        
        guard let goalIdString = userInfo["goalId"] as? String,
              let goalId = UUID(uuidString: goalIdString) else {
            print("⚠️ Could not parse goalId in didReceive")
            completionHandler()
            return
        }

        let answer: GoalAnswer = {
            switch response.actionIdentifier {
            case "YES_ACTION": return .yes
            case "NO_ACTION":  return .no
            default:           return .none
            }
        }()
        
        print("   → mapping to answer: \(answer) for goal \(goalId)")
        
        GoalsDataStore.shared.recordResponse(
            goalId: goalId,
            answer: answer,
            timestamp: Date()
        )

        completionHandler()
    }
}
