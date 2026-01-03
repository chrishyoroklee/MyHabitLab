import SwiftUI
import SwiftData

struct HabitCalendarEditorView: View {
    let habit: Habit
    let dateProvider: DateProvider

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("calendar.last_90_days")
                        .font(.headline)
                        .foregroundStyle(.white)

                    LazyVGrid(columns: gridColumns, spacing: 8) {
                        ForEach(dayCells) { cell in
                            Button {
                                toggleCompletion(for: cell)
                            } label: {
                                DayCellView(
                                    cell: cell,
                                    isCompleted: isCompleted(cell),
                                    color: AppColors.color(for: habit.colorName)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(accessibilityLabel(for: cell))
                            .accessibilityValue(Text(isCompleted(cell) ? "calendar.accessibility.completed" : "calendar.accessibility.not_completed"))
                        }
                    }
                }
                .padding()
            }
            .background(AppColors.primaryBackground)
            .navigationTitle(habit.name)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("calendar.done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    }

    private var dayCells: [DayCell] {
        let calendar = dateProvider.calendar
        let today = calendar.startOfDay(for: dateProvider.now())
        guard let start = calendar.date(byAdding: .day, value: -89, to: today) else {
            return []
        }

        return (0..<90).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }
            let dayKey = DayKey.from(date, calendar: calendar, timeZone: calendar.timeZone)
            return DayCell(date: date, dayKey: dayKey)
        }
    }

    private var completionDayKeys: Set<Int> {
        Set(habit.completions.map { $0.dayKey })
    }

    private func isCompleted(_ cell: DayCell) -> Bool {
        completionDayKeys.contains(cell.dayKey)
    }

    private func toggleCompletion(for cell: DayCell) {
        if let completion = habit.completions.first(where: { $0.dayKey == cell.dayKey }) {
            modelContext.delete(completion)
        } else {
            let completion = Completion(habit: habit, dayKey: cell.dayKey, value: 1)
            modelContext.insert(completion)
        }

        do {
            try modelContext.save()
            WidgetStoreSync.updateSnapshot(
                context: modelContext,
                dayKey: dateProvider.dayKey()
            )
        } catch {
            assertionFailure("Failed to toggle completion: \(error)")
        }
    }

    private func accessibilityLabel(for cell: DayCell) -> String {
        let formatted = cell.date.formatted(.dateTime.weekday(.abbreviated).month().day().year())
        return formatted
    }
}

private struct DayCell: Identifiable {
    let date: Date
    let dayKey: Int

    var id: Int { dayKey }
}

private struct DayCellView: View {
    let cell: DayCell
    let isCompleted: Bool
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isCompleted ? color.opacity(0.8) : AppColors.cardBackground)
            Text(dayNumber)
                .font(.caption2)
                .minimumScaleFactor(0.6)
                .foregroundStyle(isCompleted ? .white : .white.opacity(0.7))
        }
        .frame(height: 32)
    }

    private var dayNumber: String {
        cell.date.formatted(.dateTime.day())
    }
}

#Preview("Calendar Editor") {
    let container = ModelContainerFactory.makePreviewContainer()
    let context = container.mainContext
    let habit = Habit(name: "Read", iconName: "book", colorName: "Indigo")
    context.insert(habit)
    let dayKey = DayKey.from(Date())
    context.insert(Completion(habit: habit, dayKey: dayKey, value: 1))
    return HabitCalendarEditorView(habit: habit, dateProvider: .live)
        .modelContainer(container)
}
