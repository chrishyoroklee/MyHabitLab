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
        guard habit.isArchived == false, isAuthorized else {
            await cancel(for: habit)
            return
        }

        let reminders = normalizedReminders(for: habit)
        let hasEnabled = reminders.contains(where: { $0.isEnabled })
        guard hasEnabled else {
            await cancel(for: habit)
            return
        }

        await cancel(for: habit)
        await schedule(for: habit, reminders: reminders)
    }

    static func syncAll(habits: [Habit]) async {
        for habit in habits {
            await update(for: habit)
        }
    }

    private static func normalizedReminders(for habit: Habit) -> [HabitReminder] {
        if habit.reminders.isEmpty, habit.reminderEnabled {
            return [HabitReminder(
                type: .timeOfDay,
                isEnabled: true,
                hour: habit.reminderHour,
                minute: habit.reminderMinute,
                daysMask: nil
            )]
        }
        return habit.reminders
    }

    private static func schedule(for habit: Habit, reminders: [HabitReminder]) async {
        let center = UNUserNotificationCenter.current()
        var scheduledCount = 0

        for reminder in reminders where reminder.isEnabled {
            let componentsList = scheduleComponents(for: reminder, habitScheduleMask: habit.scheduleMask)
            for var components in componentsList {
                guard scheduledCount < 60 else {
                    assertionFailure("Exceeded local notification limit for habit \(habit.id)")
                    return
                }
                components.timeZone = Calendar.current.timeZone
                let identifier = identifier(for: habit, reminder: reminder, components: components)
                let content = notificationContent(for: habit, reminder: reminder)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                do {
                    try await center.add(request)
                    scheduledCount += 1
                } catch {
                    assertionFailure("Failed to schedule reminder: \(error)")
                }
            }
        }
    }

    private static func scheduleComponents(for reminder: HabitReminder, habitScheduleMask: Int) -> [DateComponents] {
        let scheduleMask = reminder.daysMask ?? habitScheduleMask
        switch reminder.type {
        case .timeOfDay:
            let hour = reminder.hour ?? 9
            let minute = reminder.minute ?? 0
            return ReminderScheduleCalculator.timeOfDayComponents(
                hour: hour,
                minute: minute,
                daysMask: scheduleMask
            )
        case .interval:
            // Interval reminders are expanded into repeating calendar triggers within a daily window.
            let interval = reminder.intervalMinutes ?? 60
            let startMinute = reminder.startMinute ?? 9 * 60
            let endMinute = reminder.endMinute ?? 17 * 60
            return ReminderScheduleCalculator.intervalComponents(
                intervalMinutes: interval,
                startMinute: startMinute,
                endMinute: endMinute,
                daysMask: scheduleMask
            )
        }
    }

    private static func notificationContent(for habit: Habit, reminder: HabitReminder) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = habit.name
        if let detail = habit.detail, detail.isEmpty == false {
            content.body = detail
        } else {
            content.body = String(localized: "notification.reminder_body")
        }
        content.userInfo = [
            "habitId": habit.id.uuidString,
            "reminderId": reminder.id.uuidString
        ]
        return content
    }

    private static func cancel(for habit: Habit) async {
        let requests = await pendingRequests()
        let prefix = identifierPrefix(for: habit)
        let identifiers = requests
            .filter { $0.identifier.hasPrefix(prefix) }
            .map { $0.identifier }
        guard !identifiers.isEmpty else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private static func pendingRequests() async -> [UNNotificationRequest] {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    private static func identifierPrefix(for habit: Habit) -> String {
        "habit-reminder-\(habit.id.uuidString)"
    }

    private static func identifier(for habit: Habit, reminder: HabitReminder, components: DateComponents) -> String {
        let weekday = components.weekday ?? 0
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        return "\(identifierPrefix(for: habit))-\(reminder.id.uuidString)-\(weekday)-\(hour)-\(minute)"
    }
}
