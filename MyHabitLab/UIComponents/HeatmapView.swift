import SwiftUI

struct ContributionGraphView: View {
    let completions: [Date]
    let color: Color
    var weeksToDisplay: Int = 10
    var blockSize: CGFloat = 8
    var spacing: CGFloat = 2
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<weeksToDisplay, id: \.self) { weekIndex in
                VStack(spacing: spacing) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        // Calculate Date
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
        let today = Date()
        let calendar = Calendar.current
        
        let totalWeeks = weeksToDisplay
        let weeksAgo = totalWeeks - 1 - weekIndex
        
        // End date (approx)
        let endWeekDate = calendar.date(byAdding: .weekOfYear, value: -weeksAgo, to: today)!
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: endWeekDate))!
        
        return calendar.date(byAdding: .day, value: dayIndex, to: startOfWeek)!
    }
    
    private func fillColor(for date: Date) -> Color {
        let isCompleted = completions.contains {
            Calendar.current.isDate($0, inSameDayAs: date)
        }
        
        // Don't show future days
        if date > Date() {
             return Color.secondary.opacity(0.05) // Placeholder for future
        }

        return isCompleted ? color : Color.secondary.opacity(0.1)
    }
}
