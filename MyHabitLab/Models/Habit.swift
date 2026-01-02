import Foundation
import SwiftData

@Model
final class Habit: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorName: String
    var detail: String?
    var createdAt: Date
    var isArchived: Bool
    @Relationship(deleteRule: .cascade, inverse: \Completion.habit)
    var completions: [Completion]

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "checkmark.circle",
        colorName: String = "Blue",
        detail: String? = nil,
        createdAt: Date = Date(),
        isArchived: Bool = false,
        completions: [Completion] = []
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorName = colorName
        self.detail = detail
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.completions = completions
    }
}
