import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let isCompletedToday: Bool
    let isScheduledToday: Bool
    let progressText: String?
    let completedDayKeys: Set<Int>
    let toggleAction: () -> Bool

    @State private var confettiCounter = 0
    @State private var heatmapWidth: CGFloat = 0

    private var statusText: String {
        progressText ?? (isScheduledToday ? "Due today" : "Not scheduled")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppColors.color(for: habit.colorName).opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: habit.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.color(for: habit.colorName))
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(habit.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(1)

                        if !isScheduledToday {
                            Text("Off day")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.cardBackground)
                                .clipShape(Capsule())
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }

                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Button {
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                    let nowComplete = toggleAction()
                    if !isCompletedToday && nowComplete {
                        confettiCounter += 1
                        let notification = UINotificationFeedbackGenerator()
                        notification.notificationOccurred(.success)
                    }
                } label: {
                    ZStack {
                        if isCompletedToday {
                            Circle()
                                .fill(AppColors.color(for: habit.colorName))
                                .frame(width: 32, height: 32)
                                .shadow(color: AppColors.color(for: habit.colorName).opacity(0.5), radius: 8, x: 0, y: 0)

                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppColors.textOnPrimary)
                        } else {
                            Circle()
                                .stroke(AppColors.color(for: habit.colorName).opacity(0.3), lineWidth: 2)
                                .frame(width: 32, height: 32)
                        }
                    }
                    .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .confetti(counter: $confettiCounter)
            }
            .padding(16)

            Divider()
                .overlay(AppColors.textSecondary.opacity(0.15))

            let weeksToDisplay = 52
            let spacing: CGFloat = 1
            let availableWidth = heatmapWidth > 0 ? heatmapWidth : 280
            let blockSize = max(1, floor((availableWidth - CGFloat(weeksToDisplay - 1) * spacing) / CGFloat(weeksToDisplay)))
            let graphHeight = blockSize * 7 + spacing * 6

            ZStack(alignment: .leading) {
                Color.clear
                ContributionGraphView(
                    completedDayKeys: completedDayKeys,
                    color: AppColors.color(for: habit.colorName),
                    weeksToDisplay: weeksToDisplay,
                    blockSize: blockSize,
                    spacing: spacing
                )
                .frame(height: graphHeight, alignment: .leading)
            }
            .frame(maxWidth: .infinity, minHeight: graphHeight, alignment: .leading)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { heatmapWidth = proxy.size.width }
                        .onChange(of: proxy.size.width) { _, newValue in
                            heatmapWidth = newValue
                        }
                }
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppColors.primaryBackground.opacity(0.08))
        }
        .background(
            ZStack {
                AppColors.cardBackground
                AppColors.color(for: habit.colorName).opacity(0.03)
            }
        )
        .cornerRadius(16)
        .shadow(color: AppColors.primaryBackground.opacity(0.15), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.color(for: habit.colorName).opacity(0.15), lineWidth: 1)
        )
    }
}
