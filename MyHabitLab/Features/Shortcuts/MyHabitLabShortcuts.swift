import AppIntents

struct MyHabitLabShortcuts: AppShortcutsProvider {
    static var shortcutTileColor: ShortcutTileColor = .teal

    static var appShortcuts: [AppShortcut] {
        [
            AppShortcut(
                intent: ToggleHabitCompletionIntent(),
                phrases: [
                    "shortcut.phrase.toggle_app \(.applicationName)",
                    "shortcut.phrase.mark_in_app \(.applicationName)",
                    "shortcut.phrase.app_completion \(.applicationName)"
                ],
                shortTitle: "shortcut.toggle.short_title",
                systemImageName: "checkmark.circle"
            )
        ]
    }
}
