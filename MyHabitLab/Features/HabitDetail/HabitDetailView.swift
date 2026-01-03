import SwiftUI
import SwiftData

struct HabitDetailView: View {
    @Bindable var habit: Habit
    let dateProvider: DateProvider

    @State private var isShowingEditSheet = false
    @State private var isShowingHistory = false

    private var completionValues: [Int: Int] {
        HabitCompletionService.completionValueByDayKey(for: habit)
    }

    private var completedDayKeys: Set<Int> {
        HabitCompletionService.completedDayKeys(for: habit)
    }

    private var streakStats: StreakStats {
        StreakCalculator.calculate(
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

    private var totalCompletions: Int {
        completionValues.reduce(0) { partial, entry in
            HabitCompletionService.isComplete(habit: habit, completionValue: entry.value) ? partial + 1 : partial
        }
    }

    private var completionRateText: String {
        percentString(streakStats.completionRateLast30Days)
    }

    private var isScheduledToday: Bool {
        HabitSchedule.isScheduled(
            on: dateProvider.today().start,
            scheduleMask: habit.scheduleMask,
            calendar: dateProvider.calendar
        )
    }

    private var todayProgressText: String? {
        HabitCompletionService.progressText(
            habit: habit,
            completionValue: completionValues[dateProvider.dayKey()]
        )
    }

    private var targetLabel: String {
        habit.trackingMode == .unit ? "Goal" : "Schedule"
    }

    private var targetSummary: String {
        if habit.trackingMode == .unit, let unit = habit.unitConfiguration {
            let goalBase = HabitCompletionService.goalBaseValue(for: habit)
            return HabitProgress.formattedDisplay(baseValue: goalBase, unit: unit)
        }
        let schedule = WeekdaySet(rawValue: habit.scheduleMask)
        return "\(schedule.count)/week"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppColors.color(for: habit.colorName).opacity(0.1))
                                .frame(width: 80, height: 80)
                                .shadow(color: AppColors.color(for: habit.colorName).opacity(0.3), radius: 20, x: 0, y: 0)

                            Image(systemName: habit.iconName)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(AppColors.color(for: habit.colorName))
                        }

                        Text(habit.name)
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundStyle(.white)

                        if let progress = todayProgressText {
                            Text(progress)
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.85))
                        }

                        if !isScheduledToday {
                            Text("Off day")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppColors.cardBackground)
                                .clipShape(Capsule())
                                .foregroundStyle(.white.opacity(0.8))
                        }

                        if let detail = habit.detail {
                            Text(detail)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(title: "Current Streak", value: "\(streakStats.currentStreak) Days", icon: "flame.fill", color: .orange)
                        StatCard(title: "Total Done", value: "\(totalCompletions)", icon: "checkmark.circle.fill", color: .green)
                        StatCard(title: "Consistency", value: completionRateText, icon: "chart.pie.fill", color: .blue)
                        StatCard(title: targetLabel, value: targetSummary, icon: "target", color: .purple)
                    }
                    .padding(.horizontal)

                    Button {
                        isShowingHistory = true
                    } label: {
                        Label("dashboard.action.edit_history", systemImage: "calendar")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppColors.color(for: habit.colorName).opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("History")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.leading)

                        ScrollView(.horizontal, showsIndicators: false) {
                            ContributionGraphView(
                                completedDayKeys: completedDayKeys,
                                color: AppColors.color(for: habit.colorName),
                                weeksToDisplay: 20
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppColors.color(for: habit.colorName).opacity(0.2), lineWidth: 1)
                            .padding(.horizontal)
                    )

                    Spacer()
                }
            }
            .background(
                ZStack {
                    AppColors.primaryBackground
                    AppColors.color(for: habit.colorName).opacity(0.05).ignoresSafeArea()
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") {
                        isShowingEditSheet = true
                    }
                }
            }
            .sheet(isPresented: $isShowingEditSheet) {
                HabitFormView(habit: habit)
            }
            .sheet(isPresented: $isShowingHistory) {
                HabitCalendarEditorView(habit: habit, dateProvider: dateProvider)
            }
        }
    }

    private func percentString(_ value: Double) -> String {
        let percentage = Int((value * 100.0).rounded())
        return "\(percentage)%"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 20))
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
