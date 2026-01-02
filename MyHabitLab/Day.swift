import Foundation

struct Day: Hashable, Codable {
    let start: Date

    init(start: Date) {
        self.start = start
    }

    var displayTitle: String {
        start.formatted(.dateTime.weekday(.wide).month().day().year())
    }
}
