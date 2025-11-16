import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}
    func scheduleNotification(for goal: Goal) {
        let content = UNMutableNotificationContent()
        content.title = goal.title
        content.body = "Time to check in on this goal."
        content.sound = .default
        content.categoryIdentifier = "YES_NO_CATEGORY"
        content.userInfo = ["goalId": goal.id.uuidString]
        let seconds = max(goal.intervalMinutes * 60, 60)
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(seconds),
            repeats: true
        )

        let request = UNNotificationRequest(
            identifier: goal.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("✅ Notification scheduled for goal \(goal.title)")
            }
        }
    }


//    func scheduleNotification(for goal: Goal) {
//        let content = UNMutableNotificationContent()
//        content.title = goal.title
//        content.body = "Time to check in on this goal."
//        content.sound = .default
//        content.categoryIdentifier = "YES_NO_CATEGORY"
//        content.userInfo = ["goalId": goal.id.uuidString]
//        
//        let seconds = max(goal.intervalMinutes * 60, 60)
//        let trigger = UNTimeIntervalNotificationTrigger(
//            timeInterval: TimeInterval(seconds),
//            repeats: true
//        )
//        
//        let request = UNNotificationRequest(
//            identifier: goal.id.uuidString,
//            content: content,
//            trigger: trigger
//        )
//        
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error = error {
//                print("Error scheduling notification: \(error)")
//            }
//        }
//    }
//    
    func cancelGoalNotification(goal: Goal) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [goal.id.uuidString])
    }
}
