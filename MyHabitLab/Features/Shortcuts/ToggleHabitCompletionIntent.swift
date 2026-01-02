import AppIntents

struct ToggleHabitCompletionIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Habit Completion"
    static var description = IntentDescription("Toggle today's completion for a habit.")

    @Parameter(title: "Habit")
    var habit: HabitEntity

    init() {}

    init(habit: HabitEntity) {
        self.habit = habit
    }

    func perform() async throws -> some IntentResult {
        let didComplete = try await MainActor.run {
            try HabitToggleService.toggleCompletion(habitId: habit.id)
        }

        let message = didComplete ? "Marked completed." : "Marked not completed."
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
