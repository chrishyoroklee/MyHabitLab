import Foundation
import SwiftData

@Model
final class Habit {
    @Attribute(.unique) var id: UUID
    var name: String
    var detail: String?
    var createdAt: Date
    var isArchived: Bool
    @Relationship(deleteRule: .cascade, inverse: \Completion.habit)
    var completions: [Completion]

    init(
        id: UUID = UUID(),
        name: String,
        detail: String? = nil,
        createdAt: Date = Date(),
        isArchived: Bool = false,
        completions: [Completion] = []
    ) {
        self.id = id
        self.name = name
        self.detail = detail
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.completions = completions
    }
}
