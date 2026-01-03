import SwiftUI
import SwiftData
import Foundation

struct StatsView: View {
    let dateProvider: DateProvider
    @Query(
        filter: #Predicate<Habit> { habit in
            habit.isArchived == false
        },
        sort: \Habit.createdAt
    )
    private var habits: [Habit]

    var body: some View {
        NavigationStack {
            Group {
                if habits.isEmpty {
                    ContentUnavailableView(
                        "stats.empty.title",
                        systemImage: "chart.bar",
                        description: Text("stats.empty.message")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            WeeklySummaryCard(count: completionsThisWeek)
                            ForEach(habits) { habit in
                                HabitStatsCard(habit: habit, stats: stats(for: habit))
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(AppColors.primaryBackground) // Force dark background
        }
    }

    private func stats(for habit: Habit) -> StreakStats {
        StreakCalculator.calculate(
            completedDayKeys: Set(habit.completions.map { $0.dayKey }),
            today: dateProvider.now(),
            calendar: dateProvider.calendar,
            timeZone: dateProvider.calendar.timeZone
        )
    }

    private var completionsThisWeek: Int {
        let calendar = dateProvider.calendar
        let timeZone = calendar.timeZone
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: dateProvider.now()) else {
            return 0
        }

        return habits.reduce(0) { total, habit in
            let count = habit.completions.reduce(0) { partial, completion in
                guard let date = DayKey.toDate(completion.dayKey, calendar: calendar, timeZone: timeZone) else {
                    return partial
                }
                return interval.contains(date) ? partial + 1 : partial
            }
            return total + count
        }
    }
}

private struct WeeklySummaryCard: View {
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("stats.summary.week")
                .font(.headline)
            Text(String(format: String(localized: "stats.summary.completions"), count))
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 12)) // Dark card
    }
}

private struct HabitStatsCard: View {
    let habit: Habit
    let stats: StreakStats

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                HabitIconView(
                    name: habit.name,
                    iconName: habit.iconName,
                    colorName: habit.colorName
                )
                Text(habit.name)
                    .font(.headline)
                    .lineLimit(2)
                    .layoutPriority(1)
            }

            LazyVGrid(columns: statColumns, alignment: .leading, spacing: 8) {
                StatChip(label: "stats.card.current", value: "\(stats.currentStreak)")
                StatChip(label: "stats.card.longest", value: "\(stats.longestStreak)")
                StatChip(label: "stats.card.thirty_days", value: percentString(stats.completionRateLast30Days))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 12)) // Dark card
    }

    private func percentString(_ value: Double) -> String {
        let percentage = Int((value * 100.0).rounded())
        return String(format: String(localized: "stats.rate.format"), percentage)
    }

    private var statColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 90), spacing: 8, alignment: .leading)]
    }
}

private struct StatChip: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(label))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(8)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8)) // Subtle chip background
    }
}
