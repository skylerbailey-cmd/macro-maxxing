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

    // MARK: - Streak Warning Notification

    private let streakWarningNotificationID = "com.sbailey.Wellness.streakWarning"

    /// Schedules a one-shot notification at 10 PM tonight warning the user their streak is at risk.
    /// Safe to call repeatedly — replaces any existing pending notification.
    /// Does nothing if 10 PM has already passed today or streak is 0.
    func scheduleStreakWarningIfNeeded(streak: Int) {
        guard streak > 0 else {
            cancelStreakWarningNotification()
            return
        }
        let cal = Calendar.current
        var components = cal.dateComponents([.year, .month, .day], from: Date())
        components.hour = 22
        components.minute = 0
        components.second = 0
        guard let fireDate = cal.date(from: components), fireDate > Date() else {
            // 10 PM already passed — nothing to schedule for tonight
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Streak at Risk 🔥"
        content.body  = "2 hours left to hit your macros and keep your \(streak)-day streak alive."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request  = UNNotificationRequest(
            identifier: streakWarningNotificationID,
            content:    content,
            trigger:    trigger
        )
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [streakWarningNotificationID])
        center.add(request)
    }

    func cancelStreakWarningNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [streakWarningNotificationID]
        )
    }

    // MARK: - New Post Local Notification

    /// Fires an immediate local notification when a subscribed user posts.
    /// Works in foreground and background; does NOT work when app is fully terminated
    /// (server-side FCM would be required for that).
    func fireLocalNewPostNotification(fromDisplayName: String, postTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(fromDisplayName) just posted"
        content.body  = postTitle.isEmpty ? "Check it out on the feed." : postTitle
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content:    content,
            trigger:    nil   // deliver immediately
        )
        UNUserNotificationCenter.current().add(request)
    }
}
