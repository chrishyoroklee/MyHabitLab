import SwiftUI
import SwiftData
import UserNotifications

struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var habit: Habit
    let dateProvider: DateProvider
    
    @State private var isShowingEditSheet = false
    
    // Stats
    private var currentStreak: Int {
        // Simple logic for now
        return calculateStreak()
    }
    
    private var completionRate: String {
        let total = habit.completions.count
        guard total > 0 else { return "0%" }
        // Simple rate: Completions / Days since creation (approx)
        let days = Calendar.current.dateComponents([.day], from: habit.createdAt, to: Date()).day ?? 1
        let rate = Double(total) / Double(max(days, 1)) * 100
        return String(format: "%.0f%%", rate)
    }

    var body: some View {
        NavigationStack { // Wrap in stack for toolbar items if pushed
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppColors.color(for: habit.colorName).opacity(0.1))
                                .frame(width: 80, height: 80)
                                .shadow(color: AppColors.color(for: habit.colorName).opacity(0.3), radius: 20, x: 0, y: 0) // Glow
                            
                            Image(systemName: habit.iconName)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(AppColors.color(for: habit.colorName))
                        }
                        
                        Text(habit.name)
                            .font(.title)
                            .fontWeight(.black) // Trendy bold
                            .foregroundStyle(.white)
                        
                        if let detail = habit.detail {
                            Text(detail)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(title: "Current Streak", value: "\(currentStreak) Days", icon: "flame.fill", color: .orange)
                        StatCard(title: "Total Done", value: "\(habit.completions.count)", icon: "checkmark.circle.fill", color: .green)
                        StatCard(title: "Consistency", value: completionRate, icon: "chart.pie.fill", color: .blue)
                        StatCard(title: "Target", value: "\(habit.targetPerWeek)/week", icon: "target", color: .purple)
                    }
                    .padding(.horizontal)
                    
                    // Heatmap
                    VStack(alignment: .leading, spacing: 8) {
                        Text("History")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.leading)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            ContributionGraphView(
                                completions: habit.completions.map { $0.createdAt },
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
                    AppColors.color(for: habit.colorName).opacity(0.05).ignoresSafeArea() // Global Tint
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
        }
    }
    
    private func calculateStreak() -> Int {
        // Placeholder for real algorithm
        // Sort completions, check consecutive days
        return 0 
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
