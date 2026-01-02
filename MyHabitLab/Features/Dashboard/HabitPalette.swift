import SwiftUI

struct HabitColorOption: Identifiable, Hashable {
    let name: String
    let color: Color

    var id: String { name }
}

enum HabitPalette {
    static let options: [HabitColorOption] = [
        HabitColorOption(name: "Blue", color: .blue),
        HabitColorOption(name: "Green", color: .green),
        HabitColorOption(name: "Orange", color: .orange),
        HabitColorOption(name: "Pink", color: .pink),
        HabitColorOption(name: "Teal", color: .teal),
        HabitColorOption(name: "Indigo", color: .indigo)
    ]

    static func color(for name: String) -> Color {
        options.first(where: { $0.name == name })?.color ?? .blue
    }

    static func defaultName() -> String {
        options.first?.name ?? "Blue"
    }
}

enum HabitIconOptions {
    static let names: [String] = [
        "checkmark.circle",
        "drop",
        "book",
        "flame",
        "leaf",
        "heart",
        "figure.walk",
        "bolt",
        "music.note"
    ]

    static func defaultName() -> String {
        names.first ?? "checkmark.circle"
    }
}
