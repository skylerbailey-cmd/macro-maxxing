//
//  NotificationService.swift
//  Wellness
//

import UserNotifications
import Foundation

final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    /// Category identifier for weigh-in reminders. Used by the notification
    /// delegate to detect taps and open the weigh-in popup.
    static let weighReminderCategory = "WEIGH_IN_REMINDER"

    private let fastingWindowNotificationID = "com.sbailey.Wellness.fastingWindowEnd"

    // MARK: - Authorization

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: - Fasting Window Notification

    /// Schedules a repeating daily notification 90 minutes before the eating window closes
    /// so the user can get their last meal in before the fasting period begins.
    func scheduleFastingWindowNotification(windowStartHour: Int, windowStartMinute: Int) {
        let durationHours = UserDefaults.standard.integer(forKey: "windowDurationHours")
        let duration = durationHours > 0 ? durationHours : 8

        // Eating window end = start + duration; notify 90 min before close
        var notifyMinutes = windowStartHour * 60 + windowStartMinute + duration * 60 - 90
        if notifyMinutes < 0 { notifyMinutes += 24 * 60 }
        notifyMinutes = notifyMinutes % (24 * 60)
        let notifyHour   = notifyMinutes / 60
        let notifyMinute = notifyMinutes % 60

        let content = UNMutableNotificationContent()
        content.title = "Eating Window Closing Soon"
        content.body  = "Your eating window closes in 90 minutes. Get your last meal in! 🍽️"
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

    /// Schedules a one-shot notification at 8 PM tonight warning the user their streak is at risk.
    /// Safe to call repeatedly — replaces any existing pending notification.
    /// Does nothing if 8 PM has already passed today or streak is 0.
    func scheduleStreakWarningIfNeeded(streak: Int) {
        guard streak > 0 else {
            cancelStreakWarningNotification()
            return
        }
        let cal = Calendar.current
        var components = cal.dateComponents([.year, .month, .day], from: Date())
        components.hour = 20
        components.minute = 0
        components.second = 0
        guard let fireDate = cal.date(from: components), fireDate > Date() else {
            // 8 PM already passed — nothing to schedule for tonight
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Streak at Risk 🔥"
        content.body  = "4 hours left to hit your macros and keep your \(streak)-day streak alive."
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

    // MARK: - Meal Logging Reminder

    private let mealReminderNotificationID = "com.sbailey.Wellness.mealReminder"

    /// Schedules a daily notification at the given hour/minute reminding the user
    /// to log a meal if they haven't hit their macro goals yet.
    /// The notification fires every day; the app cancels it for the current day
    /// once goals are met or a meal is logged.
    func scheduleMealReminder(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Don't Forget to Log Your Meals"
        content.body  = "You haven't hit your macro goals yet today. Open the app to log a meal!"
        content.sound = .default

        var components    = DateComponents()
        components.hour   = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: mealReminderNotificationID,
            content: content,
            trigger: trigger
        )

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [mealReminderNotificationID])
        center.add(request)
    }

    func cancelMealReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [mealReminderNotificationID]
        )
    }

    // MARK: - Weigh-In Reminder

    private let weighReminderIDPrefix = "com.sbailey.Wellness.weighReminder"

    /// Schedules a recurring weigh-in reminder on the specified weekdays at the
    /// given hour/minute. Each day gets its own notification request so the user
    /// can pick any combination of days (e.g. Mon + Thu).
    func scheduleWeighInReminder(hour: Int, minute: Int, weekdays: Set<Int>) {
        cancelWeighInReminder()

        let content = UNMutableNotificationContent()
        content.title = "Ready to weigh in?"
        content.body  = "Step on the scale and log your weight to track your progress."
        content.sound = .default
        content.categoryIdentifier = Self.weighReminderCategory

        let center = UNUserNotificationCenter.current()
        for weekday in weekdays {
            var components    = DateComponents()
            components.hour   = hour
            components.minute = minute
            components.weekday = weekday   // 1 = Sunday, 2 = Monday, … 7 = Saturday

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(weighReminderIDPrefix).\(weekday)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    func cancelWeighInReminder() {
        let ids = (1...7).map { "\(weighReminderIDPrefix).\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Streak Extension Expiry Notification

    private let streakExtensionExpiryID = "com.sbailey.Wellness.streakExtensionExpiry"

    /// Schedules a notification for the day a streak extension expires,
    /// reminding the user to start logging again.
    func scheduleStreakExtensionExpiry(daysFromNow: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Streak Extension Expiring"
        content.body  = "Your 7-day streak extension expires today. Start logging your meals to keep your streak alive!"
        content.sound = .default

        // Fire at 9 AM on the expiry day
        guard let fireDate = Calendar.current.date(byAdding: .day, value: daysFromNow, to: Date()) else { return }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: streakExtensionExpiryID,
            content: content,
            trigger: trigger
        )

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [streakExtensionExpiryID])
        center.add(request)
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
