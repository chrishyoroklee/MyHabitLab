import AppIntents

struct ToggleHabitCompletionIntent: AppIntent {
    static var title: LocalizedStringResource = "widget.intent.toggle.title"
    static var description = IntentDescription("widget.intent.toggle.description")

    @Parameter(title: "widget.intent.toggle.parameter")
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
