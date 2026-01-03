import Foundation
import SwiftData

struct ExportPayload: Codable, Hashable {
    let habits: [ExportHabit]
    let completions: [ExportCompletion]
    let exportedAt: Date
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

        return ExportPayload(
            habits: exportHabits,
            completions: exportCompletions,
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

        var habitsById: [UUID: Habit] = Dictionary(uniqueKeysWithValues: existingHabits.map { ($0.id, $0) })
        let completionsById: [UUID: Completion] = Dictionary(uniqueKeysWithValues: existingCompletions.map { ($0.id, $0) })

        for habit in payload.habits {
            if let existing = habitsById[habit.id] {
                existing.name = habit.name
                existing.iconName = habit.iconName
                existing.colorName = habit.colorName
                existing.detail = habit.detail
                existing.reminderEnabled = habit.reminderEnabled
                existing.reminderHour = habit.reminderHour
                existing.reminderMinute = habit.reminderMinute
                existing.createdAt = habit.createdAt
                existing.isArchived = habit.isArchived
            } else {
                let newHabit = Habit(
                    id: habit.id,
                    name: habit.name,
                    iconName: habit.iconName,
                    colorName: habit.colorName,
                    detail: habit.detail,
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

        try context.save()
    }
}
