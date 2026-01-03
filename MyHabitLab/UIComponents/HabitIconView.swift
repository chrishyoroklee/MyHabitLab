import SwiftUI

struct HabitIconView: View {
    let name: String
    let iconName: String
    let colorName: String

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
            if iconName.isEmpty {
                Text(initial)
                    .font(.headline)
                    .foregroundStyle(color)
            } else {
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundStyle(color)
            }
        }
        .frame(width: 36, height: 36)
    }

    private var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "H" : String(trimmed.prefix(1)).uppercased()
    }

    private var color: Color {
        AppColors.color(for: colorName)
    }
}
