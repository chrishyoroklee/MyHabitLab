import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let isCompletedToday: Bool
    let isScheduledToday: Bool
    let progressText: String?
    let completedDayKeys: Set<Int>
    let toggleAction: () -> Bool

    @State private var confettiCounter = 0

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
                            .foregroundColor(.white)
                            .lineLimit(1)

                        if !isScheduledToday {
                            Text("Off day")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.cardBackground)
                                .clipShape(Capsule())
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }

                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
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
                                .foregroundColor(.white)
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
                .overlay(Color.white.opacity(0.1))

            ContributionGraphView(
                completedDayKeys: completedDayKeys,
                color: AppColors.color(for: habit.colorName),
                weeksToDisplay: 14,
                blockSize: 8,
                spacing: 2
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.2))
        }
        .background(
            ZStack {
                AppColors.cardBackground
                AppColors.color(for: habit.colorName).opacity(0.03)
            }
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.color(for: habit.colorName).opacity(0.15), lineWidth: 1)
        )
    }
}
