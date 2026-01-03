import SwiftUI

struct HabitCardView: View {
    let habit: Habit
    let isCompletedToday: Bool
    let toggleAction: () -> Void
    
    @State private var confettiCounter = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header: Icon, Name, Checkbox
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppColors.color(for: habit.colorName).opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: habit.iconName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppColors.color(for: habit.colorName))
                }
                
                    VStack(alignment: .leading, spacing: 4) {
                    Text(habit.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white) // Force White for readability
                        .lineLimit(1)
                    
                    Text("\(habit.targetPerWeek) times / week")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6)) // Lighter white instead of gray
                }
                
                Spacer()
                
                // Trendy Check Button
                Button {
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                    if !isCompletedToday {
                        confettiCounter += 1
                        let notification = UINotificationFeedbackGenerator()
                        notification.notificationOccurred(.success)
                    }
                    toggleAction()
                } label: {
                    ZStack {
                        if isCompletedToday {
                            Circle()
                                .fill(AppColors.color(for: habit.colorName))
                                .frame(width: 32, height: 32)
                                .shadow(color: AppColors.color(for: habit.colorName).opacity(0.5), radius: 8, x: 0, y: 0) // Glow
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Circle()
                                .stroke(AppColors.color(for: habit.colorName).opacity(0.3), lineWidth: 2) // Use habit color for ring
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
                .overlay(Color.white.opacity(0.1)) // Subtle divider
            
            // Heatmap Footer
            HStack {
                Text("Consistency")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.4))
                    .textCase(.uppercase)
                
                Spacer()
                
                // Show last 10 weeks
                ContributionGraphView(
                    completions: habit.completions.map { $0.createdAt },
                    color: AppColors.color(for: habit.colorName),
                    weeksToDisplay: 10,
                    blockSize: 10,
                    spacing: 3
                )
            }
            .padding(12)
            .background(Color.black.opacity(0.2)) // Slightly darker footer
        }
        .background(
            ZStack {
                AppColors.cardBackground // Base Dark Grey
                AppColors.color(for: habit.colorName).opacity(0.03) // Very subtle tint of habit color
            }
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.color(for: habit.colorName).opacity(0.15), lineWidth: 1) // Colored border
        )
    }
}
