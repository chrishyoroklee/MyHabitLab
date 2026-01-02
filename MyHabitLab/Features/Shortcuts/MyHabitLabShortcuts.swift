import AppIntents

struct MyHabitLabShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .teal

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleHabitCompletionIntent(),
            phrases: [
                "Toggle \(.applicationName) habit",
                "Mark habit in \(.applicationName)",
                "\(.applicationName) habit completion"
            ],
            shortTitle: "shortcut.toggle.short_title",
            systemImageName: "checkmark.circle"
        )
    }
}
