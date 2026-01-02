import AppIntents

struct ToggleHabitCompletionIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Habit Completion"
    static var description = IntentDescription("Toggle today's completion for a habit.")

    @Parameter(title: "Habit ID")
    var habitId: String

    init() {
        habitId = ""
    }

    init(habitId: String) {
        self.habitId = habitId
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: habitId) else {
            return .result()
        }

        let dayKey = DayKey.from(Date())
        WidgetSharedStore.toggleHabit(id: uuid, dayKey: dayKey)
        return .result()
    }
}
