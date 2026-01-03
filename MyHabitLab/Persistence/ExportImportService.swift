import Foundation
import SwiftData

struct ExportPayload: Codable, Hashable {
    let habits: [ExportHabit]
    let completions: [ExportCompletion]
    let reminders: [ExportReminder]
    let exportedAt: Date

    init(
        habits: [ExportHabit],
        completions: [ExportCompletion],
        reminders: [ExportReminder],
        exportedAt: Date
    ) {
        self.habits = habits
        self.completions = completions
        self.reminders = reminders
        self.exportedAt = exportedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        habits = try container.decode([ExportHabit].self, forKey: .habits)
        completions = try container.decode([ExportCompletion].self, forKey: .completions)
        reminders = try container.decodeIfPresent([ExportReminder].self, forKey: .reminders) ?? []
        exportedAt = try container.decode(Date.self, forKey: .exportedAt)
    }
}

struct ExportHabit: Codable, Hashable {
    let id: UUID
    let name: String
    let iconName: String
    let colorName: String
    let detail: String?
    let reminderEnabled: Bool
    let reminderHour: Int
    let reminderMinute: Int
    let trackingModeRaw: String?
    let scheduleMask: Int?
    let extraCompletionPolicyRaw: String?
    let unitDisplayName: String?
    let unitBaseName: String?
    let unitBaseScale: Int?
    let unitDisplayPrecision: Int?
    let unitGoalBaseValue: Int?
    let unitDefaultIncrementBaseValue: Int?
    let targetPerWeek: Int?
    let createdAt: Date
    let isArchived: Bool
}

struct ExportCompletion: Codable, Hashable {
    let id: UUID
    let habitId: UUID
    let dayKey: Int
    let value: Int
    let createdAt: Date
}

struct ExportReminder: Codable, Hashable {
    let id: UUID
    let habitId: UUID
    let typeRaw: String
    let isEnabled: Bool
    let hour: Int?
    let minute: Int?
    let intervalMinutes: Int?
    let startMinute: Int?
    let endMinute: Int?
    let daysMask: Int?
    let createdAt: Date
}

enum ExportImportService {
    @MainActor
    static func exportData(context: ModelContext) async throws -> Data {
        let payload = try buildPayload(context: context)
        return try await Task.detached {
            try encode(payload)
        }.value
    }

    @MainActor
    static func importData(_ data: Data, context: ModelContext) async throws {
        let payload = try await Task.detached {
            try decode(data)
        }.value
        try apply(payload, context: context)
    }

    static func readData(from url: URL) async throws -> Data {
        return try await Task.detached {
            try Data(contentsOf: url)
        }.value
    }

    @MainActor
    private static func buildPayload(context: ModelContext) throws -> ExportPayload {
        let habits = try context.fetch(FetchDescriptor<Habit>())
        let completions = try context.fetch(FetchDescriptor<Completion>())
        let reminders = try context.fetch(FetchDescriptor<HabitReminder>())

        let exportHabits = habits.map {
            ExportHabit(
                id: $0.id,
                name: $0.name,
                iconName: $0.iconName,
                colorName: $0.colorName,
                detail: $0.detail,
                reminderEnabled: $0.reminderEnabled,
                reminderHour: $0.reminderHour,
                reminderMinute: $0.reminderMinute,
                trackingModeRaw: $0.trackingModeRaw,
                scheduleMask: $0.scheduleMask,
                extraCompletionPolicyRaw: $0.extraCompletionPolicyRaw,
                unitDisplayName: $0.unitDisplayName,
                unitBaseName: $0.unitBaseName,
                unitBaseScale: $0.unitBaseScale,
                unitDisplayPrecision: $0.unitDisplayPrecision,
                unitGoalBaseValue: $0.unitGoalBaseValue,
                unitDefaultIncrementBaseValue: $0.unitDefaultIncrementBaseValue,
                targetPerWeek: $0.targetPerWeek,
                createdAt: $0.createdAt,
                isArchived: $0.isArchived
            )
        }

        let exportCompletions = completions.compactMap { completion -> ExportCompletion? in
            guard let habitId = completion.habit?.id else { return nil }
            return ExportCompletion(
                id: completion.id,
                habitId: habitId,
                dayKey: completion.dayKey,
                value: completion.value,
                createdAt: completion.createdAt
            )
        }

        let exportReminders = reminders.compactMap { reminder -> ExportReminder? in
            guard let habitId = reminder.habit?.id else { return nil }
            return ExportReminder(
                id: reminder.id,
                habitId: habitId,
                typeRaw: reminder.typeRaw,
                isEnabled: reminder.isEnabled,
                hour: reminder.hour,
                minute: reminder.minute,
                intervalMinutes: reminder.intervalMinutes,
                startMinute: reminder.startMinute,
                endMinute: reminder.endMinute,
                daysMask: reminder.daysMask,
                createdAt: reminder.createdAt
            )
        }

        return ExportPayload(
            habits: exportHabits,
            completions: exportCompletions,
            reminders: exportReminders,
            exportedAt: Date()
        )
    }

    private static func encode(_ payload: ExportPayload) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    private static func decode(_ data: Data) throws -> ExportPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ExportPayload.self, from: data)
    }

    @MainActor
    private static func apply(_ payload: ExportPayload, context: ModelContext) throws {
        let existingHabits = try context.fetch(FetchDescriptor<Habit>())
        let existingCompletions = try context.fetch(FetchDescriptor<Completion>())
        let existingReminders = try context.fetch(FetchDescriptor<HabitReminder>())

        var habitsById: [UUID: Habit] = Dictionary(uniqueKeysWithValues: existingHabits.map { ($0.id, $0) })
        let completionsById: [UUID: Completion] = Dictionary(uniqueKeysWithValues: existingCompletions.map { ($0.id, $0) })
        let remindersById: [UUID: HabitReminder] = Dictionary(uniqueKeysWithValues: existingReminders.map { ($0.id, $0) })

        for habit in payload.habits {
            if let existing = habitsById[habit.id] {
                existing.name = habit.name
                existing.iconName = habit.iconName
                existing.colorName = habit.colorName
                existing.detail = habit.detail
                existing.reminderEnabled = habit.reminderEnabled
                existing.reminderHour = habit.reminderHour
                existing.reminderMinute = habit.reminderMinute
                existing.trackingModeRaw = habit.trackingModeRaw ?? existing.trackingModeRaw
                existing.scheduleMask = habit.scheduleMask ?? existing.scheduleMask
                existing.extraCompletionPolicyRaw = habit.extraCompletionPolicyRaw ?? existing.extraCompletionPolicyRaw
                existing.unitDisplayName = habit.unitDisplayName ?? existing.unitDisplayName
                existing.unitBaseName = habit.unitBaseName ?? existing.unitBaseName
                existing.unitBaseScale = max(1, habit.unitBaseScale ?? existing.unitBaseScale)
                existing.unitDisplayPrecision = max(0, habit.unitDisplayPrecision ?? existing.unitDisplayPrecision)
                existing.unitGoalBaseValue = habit.unitGoalBaseValue ?? existing.unitGoalBaseValue
                existing.unitDefaultIncrementBaseValue = habit.unitDefaultIncrementBaseValue ?? existing.unitDefaultIncrementBaseValue
                if let targetPerWeek = habit.targetPerWeek {
                    existing.targetPerWeek = targetPerWeek
                }
                existing.createdAt = habit.createdAt
                existing.isArchived = habit.isArchived
            } else {
                let trackingMode = HabitTrackingMode(rawValue: habit.trackingModeRaw ?? "") ?? .checkmark
                let extraPolicy = ExtraCompletionPolicy(rawValue: habit.extraCompletionPolicyRaw ?? "") ?? .totalsOnly
                let newHabit = Habit(
                    id: habit.id,
                    name: habit.name,
                    iconName: habit.iconName,
                    colorName: habit.colorName,
                    detail: habit.detail,
                    trackingMode: trackingMode,
                    scheduleMask: habit.scheduleMask ?? WeekdaySet.all.rawValue,
                    extraCompletionPolicy: extraPolicy,
                    unitDisplayName: habit.unitDisplayName,
                    unitBaseName: habit.unitBaseName,
                    unitBaseScale: max(1, habit.unitBaseScale ?? 1),
                    unitDisplayPrecision: max(0, habit.unitDisplayPrecision ?? 0),
                    unitGoalBaseValue: habit.unitGoalBaseValue,
                    unitDefaultIncrementBaseValue: habit.unitDefaultIncrementBaseValue,
                    targetPerWeek: habit.targetPerWeek ?? 7,
                    reminderEnabled: habit.reminderEnabled,
                    reminderHour: habit.reminderHour,
                    reminderMinute: habit.reminderMinute,
                    createdAt: habit.createdAt,
                    isArchived: habit.isArchived
                )
                context.insert(newHabit)
                habitsById[habit.id] = newHabit
            }
        }

        for completion in payload.completions {
            guard let habit = habitsById[completion.habitId] else { continue }

            if let existing = completionsById[completion.id] {
                existing.dayKey = completion.dayKey
                existing.value = completion.value
                existing.createdAt = completion.createdAt
                existing.habit = habit
            } else {
                let newCompletion = Completion(
                    id: completion.id,
                    habit: habit,
                    dayKey: completion.dayKey,
                    value: completion.value,
                    createdAt: completion.createdAt
                )
                context.insert(newCompletion)
            }
        }

        for reminder in payload.reminders {
            guard let habit = habitsById[reminder.habitId] else { continue }

            if let existing = remindersById[reminder.id] {
                existing.typeRaw = reminder.typeRaw
                existing.isEnabled = reminder.isEnabled
                existing.hour = reminder.hour
                existing.minute = reminder.minute
                existing.intervalMinutes = reminder.intervalMinutes
                existing.startMinute = reminder.startMinute
                existing.endMinute = reminder.endMinute
                existing.daysMask = reminder.daysMask
                existing.createdAt = reminder.createdAt
                existing.habit = habit
            } else {
                let reminderType = HabitReminderType(rawValue: reminder.typeRaw) ?? .timeOfDay
                let newReminder = HabitReminder(
                    id: reminder.id,
                    type: reminderType,
                    isEnabled: reminder.isEnabled,
                    hour: reminder.hour,
                    minute: reminder.minute,
                    intervalMinutes: reminder.intervalMinutes,
                    startMinute: reminder.startMinute,
                    endMinute: reminder.endMinute,
                    daysMask: reminder.daysMask,
                    createdAt: reminder.createdAt,
                    habit: habit
                )
                context.insert(newReminder)
            }
        }

        try context.save()
    }
}
