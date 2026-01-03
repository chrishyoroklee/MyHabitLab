import AppIntents
import Foundation

struct WidgetHabitSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "widget.intent.select.title"
    static var description = IntentDescription("widget.intent.select.description")

    @Parameter(title: "widget.intent.select.habit")
    var habit: WidgetHabitEntity?

    init() {}
}

struct WidgetHabitEntity: AppEntity, Identifiable, Hashable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "widget.intent.habit.type"
    static var defaultQuery = WidgetHabitEntityQuery()

    let id: UUID
    let name: String
    let iconName: String
    let colorName: String

    var displayRepresentation: DisplayRepresentation {
        let symbolName = iconName.isEmpty ? "checkmark.circle" : iconName
        return DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: name),
            subtitle: LocalizedStringResource(stringLiteral: colorName),
            image: .init(systemName: symbolName)
        )
    }

    static func from(_ habit: WidgetHabitSnapshot) -> WidgetHabitEntity {
        WidgetHabitEntity(
            id: habit.id,
            name: habit.name,
            iconName: habit.iconName,
            colorName: habit.colorName
        )
    }
}

struct WidgetHabitEntityQuery: EntityQuery {
    func entities(for identifiers: [WidgetHabitEntity.ID]) async throws -> [WidgetHabitEntity] {
        let state = WidgetSharedStore.loadState()
        let set = Set(identifiers)
        return state.habits.filter { set.contains($0.id) }.map(WidgetHabitEntity.from)
    }

    func suggestedEntities() async throws -> [WidgetHabitEntity] {
        let state = WidgetSharedStore.loadState()
        return state.habits.prefix(6).map(WidgetHabitEntity.from)
    }

    func entities(matching query: String) async throws -> [WidgetHabitEntity] {
        let state = WidgetSharedStore.loadState()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            return state.habits.prefix(6).map(WidgetHabitEntity.from)
        }
        return state.habits.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }.map(WidgetHabitEntity.from)
    }
}
