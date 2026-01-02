import AppIntents
import Foundation

struct ToggleHabitCompletionIntent: AppIntent {
    static var title: LocalizedStringResource = "shortcut.toggle.title"
    static var description = IntentDescription("shortcut.toggle.description")

    @Parameter(title: "shortcut.toggle.parameter")
    var habit: HabitEntity

    init() {}

    init(habit: HabitEntity) {
        self.habit = habit
    }

    func perform() async throws -> some IntentResult {
        let didComplete = try await MainActor.run {
            try HabitToggleService.toggleCompletion(habitId: habit.id)
        }

        let message = didComplete
            ? String(localized: "shortcut.toggle.completed")
            : String(localized: "shortcut.toggle.not_completed")
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
