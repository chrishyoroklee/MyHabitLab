import AppIntents
import Foundation

struct HabitEntity: AppEntity, Identifiable, Hashable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "shortcut.habit.type"
    static var defaultQuery = HabitEntityQuery()

    let id: UUID
    let name: String
    let iconName: String
    let colorName: String

    var displayRepresentation: DisplayRepresentation {
        let symbolName = iconName.isEmpty ? "checkmark.circle" : iconName
        let colorKey = HabitPalette.displayNameKey(for: colorName)
        let colorDisplay = NSLocalizedString(colorKey, comment: "")
        return DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: name),
            subtitle: LocalizedStringResource(stringLiteral: colorDisplay),
            image: .init(systemName: symbolName)
        )
    }

    static func from(_ habit: Habit) -> HabitEntity {
        HabitEntity(
            id: habit.id,
            name: habit.name,
            iconName: habit.iconName,
            colorName: habit.colorName
        )
    }
}

struct HabitEntityQuery: EntityQuery {
    func entities(for identifiers: [HabitEntity.ID]) async throws -> [HabitEntity] {
        return try await MainActor.run {
            let habits = try HabitLookup.fetchHabits(ids: identifiers)
            return habits.map(HabitEntity.from)
        }
    }

    func suggestedEntities() async throws -> [HabitEntity] {
        return try await MainActor.run {
            let habits = try HabitLookup.fetchSuggestedHabits(limit: 6)
            return habits.map(HabitEntity.from)
        }
    }

    func entities(matching query: String) async throws -> [HabitEntity] {
        return try await MainActor.run {
            let habits = try HabitLookup.searchHabits(matching: query, limit: 10)
            return habits.map(HabitEntity.from)
        }
    }
}
