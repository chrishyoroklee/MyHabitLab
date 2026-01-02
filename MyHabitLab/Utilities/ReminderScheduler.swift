import Foundation
import UserNotifications

enum ReminderScheduler {
    static func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func update(for habit: Habit) async {
        let status = await authorizationStatus()
        let isAuthorized = status == .authorized || status == .provisional || status == .ephemeral
        guard habit.isArchived == false, habit.reminderEnabled, isAuthorized else {
            cancel(for: habit)
            return
        }
        await schedule(for: habit)
    }

    static func syncAll(habits: [Habit]) async {
        for habit in habits {
            await update(for: habit)
        }
    }

    private static func schedule(for habit: Habit) async {
        let content = UNMutableNotificationContent()
        content.title = habit.name
        if let detail = habit.detail, detail.isEmpty == false {
            content.body = detail
        } else {
            content.body = String(localized: "notification.reminder_body")
        }

        var components = DateComponents()
        components.hour = habit.reminderHour
        components.minute = habit.reminderMinute
        components.timeZone = Calendar.current.timeZone

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: identifier(for: habit),
            content: content,
            trigger: trigger
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            assertionFailure("Failed to schedule reminder: \(error)")
        }
    }

    private static func cancel(for habit: Habit) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(for: habit)])
    }

    private static func identifier(for habit: Habit) -> String {
        "habit-reminder-\(habit.id.uuidString)"
    }
}
