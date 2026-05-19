import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let timerNotificationID = "timer.finished"

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func scheduleTimerNotification(after seconds: TimeInterval, title: String = "インターバル終了") {
        cancelTimerNotification()

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = "次のセットを始めましょう！"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: timerNotificationID, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    func cancelTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [timerNotificationID])
    }
}
