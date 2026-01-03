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
                    .foregroundStyle(.white)
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
        let completionValues = HabitCompletionService.completionValueByDayKey(for: habit)
        return StreakCalculator.calculate(
            completionValuesByDayKey: completionValues,
            trackingMode: habit.trackingMode,
            goalBaseValue: habit.unitGoalBaseValue,
            scheduleMask: habit.scheduleMask,
            extraCompletionPolicy: habit.extraCompletionPolicy,
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
            let values = HabitCompletionService.completionValueByDayKey(for: habit)
            let count = values.reduce(0) { partial, entry in
                guard let date = DayKey.toDate(entry.key, calendar: calendar, timeZone: timeZone) else {
                    return partial
                }
                guard interval.contains(date) else { return partial }
                return HabitCompletionService.isComplete(habit: habit, completionValue: entry.value) ? partial + 1 : partial
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
                .foregroundStyle(.white.opacity(0.7))
            Text(String(format: String(localized: "stats.summary.completions"), count))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
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
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .layoutPriority(1)
            }

            LazyVGrid(columns: statColumns, alignment: .leading, spacing: 8) {
                StatChip(label: "stats.card.current", value: "\(stats.currentStreak)", colorName: habit.colorName)
                StatChip(label: "stats.card.longest", value: "\(stats.longestStreak)", colorName: habit.colorName)
                StatChip(label: "stats.card.thirty_days", value: percentString(stats.completionRateLast30Days), colorName: habit.colorName)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            ZStack {
                AppColors.cardBackground
                AppColors.color(for: habit.colorName).opacity(0.05) // Subtle tint
            }
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.color(for: habit.colorName).opacity(0.2), lineWidth: 1)
        )
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
    let colorName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(LocalizedStringKey(label))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .padding(8)
        .background(AppColors.cardBackground.opacity(0.5)) // Darken slightly
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                 .stroke(AppColors.color(for: colorName).opacity(0.3), lineWidth: 1)
        )
    }
}
