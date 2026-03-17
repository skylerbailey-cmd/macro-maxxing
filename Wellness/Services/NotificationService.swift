//
//  NotificationService.swift
//  Wellness
//

import UserNotifications
import Foundation

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let fastingWindowNotificationID = "com.sbailey.Wellness.fastingWindowEnd"

    // MARK: - Authorization

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: - Fasting Window Notification

    /// Schedules a repeating daily notification 90 minutes before the eating window starts
    /// (i.e. 90 minutes before the fasting window ends).
    func scheduleFastingWindowNotification(windowStartHour: Int, windowStartMinute: Int) {
        var totalMinutes = windowStartHour * 60 + windowStartMinute - 90
        if totalMinutes < 0 { totalMinutes += 24 * 60 } // handle midnight rollover
        let notifyHour   = totalMinutes / 60
        let notifyMinute = totalMinutes % 60

        let content = UNMutableNotificationContent()
        content.title = "Fast Ending Soon"
        content.body  = "Your fasting window ends in 90 minutes. Start prepping your last meal! 🍳"
        content.sound = .default

        var components    = DateComponents()
        components.hour   = notifyHour
        components.minute = notifyMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: fastingWindowNotificationID,
            content: content,
            trigger: trigger
        )

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [fastingWindowNotificationID])
        center.add(request)
    }

    func cancelFastingWindowNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [fastingWindowNotificationID]
        )
    }
}
