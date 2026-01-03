import Foundation
import SwiftData

enum HabitReminderType: String, Codable, CaseIterable {
    case timeOfDay
    case interval
}

@Model
final class HabitReminder: Identifiable {
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    var isEnabled: Bool
    var hour: Int?
    var minute: Int?
    var intervalMinutes: Int?
    var startMinute: Int?
    var endMinute: Int?
    var daysMask: Int?
    var createdAt: Date
    var habit: Habit?

    var type: HabitReminderType {
        get { HabitReminderType(rawValue: typeRaw) ?? .timeOfDay }
        set { typeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        type: HabitReminderType = .timeOfDay,
        isEnabled: Bool = true,
        hour: Int? = nil,
        minute: Int? = nil,
        intervalMinutes: Int? = nil,
        startMinute: Int? = nil,
        endMinute: Int? = nil,
        daysMask: Int? = nil,
        createdAt: Date = Date(),
        habit: Habit? = nil
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.isEnabled = isEnabled
        self.hour = hour
        self.minute = minute
        self.intervalMinutes = intervalMinutes
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.daysMask = daysMask
        self.createdAt = createdAt
        self.habit = habit
    }
}
