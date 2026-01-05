import SwiftUI

enum Tab: String, CaseIterable {
    case dashboard = "Dashboard"
    case stats = "Stats"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .stats: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    let onAddTapped: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            tabButton(for: .dashboard)
            Spacer()
            addButton()
            Spacer()
            tabButton(for: .stats)
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background {
            Capsule()
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.primaryBackground.opacity(0.2), radius: 10, x: 0, y: 5)
                .overlay(
                    Capsule()
                        .stroke(AppColors.primaryBackground.opacity(0.1), lineWidth: 0.5)
                )
        }
        .padding(.horizontal, 40)
    }

    private func tabButton(for tab: Tab) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22))
                    .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
            }
            .foregroundColor(selectedTab == tab ? AppColors.textPrimary : AppColors.textSecondary)
            .frame(height: 50)
        }
    }

    private func addButton() -> some View {
        Button {
            onAddTapped()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
            }
            .foregroundColor(AppColors.textPrimary)
            .frame(height: 50)
        }
        .accessibilityLabel(Text("dashboard.action.new_habit"))
    }
}
