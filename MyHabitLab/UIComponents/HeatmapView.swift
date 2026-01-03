import SwiftUI

struct ContributionGraphView: View {
    let completedDayKeys: Set<Int>
    let color: Color
    var weeksToDisplay: Int = 10
    var blockSize: CGFloat = 8
    var spacing: CGFloat = 2
    var calendar: Calendar = .current

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<weeksToDisplay, id: \.self) { weekIndex in
                VStack(spacing: spacing) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        let date = dateFor(weekIndex: weekIndex, dayIndex: dayIndex)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(fillColor(for: date))
                            .frame(width: blockSize, height: blockSize)
                    }
                }
            }
        }
    }

    private func dateFor(weekIndex: Int, dayIndex: Int) -> Date {
        let totalWeeks = weeksToDisplay
        let weeksAgo = totalWeeks - 1 - weekIndex

        let endWeekDate = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: Date()) ?? Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: endWeekDate)) ?? endWeekDate

        return calendar.date(byAdding: .day, value: dayIndex, to: startOfWeek) ?? startOfWeek
    }

    private func fillColor(for date: Date) -> Color {
        let dayKey = DayKey.from(date, calendar: calendar, timeZone: calendar.timeZone)
        let isCompleted = completedDayKeys.contains(dayKey)

        if date > Date() {
            return Color.secondary.opacity(0.05)
        }

        return isCompleted ? color : Color.secondary.opacity(0.1)
    }
}
