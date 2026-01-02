import AppIntents
import Foundation

struct HabitEntity: AppEntity, Identifiable, Hashable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Habit"
    static var defaultQuery = HabitEntityQuery()

    let id: UUID
    let name: String
    let iconName: String
    let colorName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: name),
            subtitle: LocalizedStringResource(stringLiteral: colorName),
            image: .init(systemName: iconName)
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
        let habits = try await MainActor.run {
            try HabitLookup.fetchHabits(ids: identifiers)
        }
        return habits.map(HabitEntity.from)
    }

    func suggestedEntities() async throws -> [HabitEntity] {
        let habits = try await MainActor.run {
            try HabitLookup.fetchSuggestedHabits(limit: 6)
        }
        return habits.map(HabitEntity.from)
    }

    func entities(matching query: String) async throws -> [HabitEntity] {
        let habits = try await MainActor.run {
            try HabitLookup.searchHabits(matching: query, limit: 10)
        }
        return habits.map(HabitEntity.from)
    }
}
