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
    
    var body: some View {
        HStack {
            ForEach(Tab.allCases, id: \.self) { tab in
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 22))
                            .scaleEffect(selectedTab == tab ? 1.1 : 1.0)
                        
                        // Optional Label? User said "trendy", maybe just icons or small labels.
                        // Let's stick to icons for ultra-minimalism or small text.
                    }
                    .foregroundColor(selectedTab == tab ? AppColors.textPrimary : AppColors.textSecondary)
                    .frame(height: 50)
                }
                Spacer()
            }
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
}
