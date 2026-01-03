import Foundation

struct IconAsset: Identifiable {
    let id = UUID()
    let name: String
    let systemName: String
}

enum IconCategory: String, CaseIterable, Identifiable {
    case health = "Health"
    case fitness = "Fitness"
    case productivity = "Productivity"
    case mindfulness = "Mindfulness"
    case household = "Household"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icons: [String] {
        switch self {
        case .health:
            return ["heart.fill", "pills.fill", "cross.case.fill", "medical.thermometer.fill", "bed.double.fill", "drop.fill"]
        case .fitness:
            return ["figure.run", "dumbbell.fill", "figure.walk", "figure.yoga", "figure.pool.swim", "bicycle", "tennis.racket"]
        case .productivity:
            return ["book.fill", "laptopcomputer", "pencil", "list.bullet.clipboard.fill", "briefcase.fill", "folder.fill", "calendar"]
        case .mindfulness:
            return ["leaf.fill", "brain.head.profile", "lightbulb.fill", "sun.max.fill", "moon.stars.fill", "headphones"]
        case .household:
            return ["house.fill", "cart.fill", "trash.fill", "carrot.fill", "cup.and.saucer.fill", "frying.pan.fill"]
        case .other:
            return ["star.fill", "flag.fill", "location.fill", "airplane", "gift.fill", "creditcard.fill", "gamecontroller.fill"]
        }
    }
}
