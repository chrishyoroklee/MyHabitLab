import SwiftUI

enum AppColors {
    // MARK: - Premium Palette
    
    // Vibrant, neon-like colors for dark mode pop
    // Vibrant, neon-like colors for dark mode pop
    static let electricBlue = Color(hex: "3B82F6") // Brighter Blue
    static let neonPurple = Color(hex: "D946EF") // Brighter Purple
    static let sunsetOrange = Color(hex: "F97316") // Brighter Orange
    static let hotPink = Color(hex: "EC4899") // Brighter Pink
    static let limeGreen = Color(hex: "22C55E") // Matrix Green
    static let tealBlue = Color(hex: "06B6D4") // Cyan
    static let goldenYellow = Color(hex: "EAB308") // Gold
    static let scarletRed = Color(hex: "EF4444") // Red
    
    // Backgrounds
    // Backgrounds
    // Navy + white theme
    static let primaryBackground = Color(hex: "2B4D7A") // Lighter navy
    static let cardBackground = Color(hex: "F8FAFC") // Soft white
    static let textPrimary = Color(hex: "0B1F3B") // Navy for light surfaces
    static let textSecondary = Color(hex: "475569") // Slate
    static let textOnPrimary = Color.white
    static let primaryBackgroundGradient = LinearGradient(
        colors: [
            primaryBackground.opacity(0.9),
            primaryBackground.opacity(0.75)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Helper
    
    static func color(for name: String) -> Color {
        switch name {
        case "Electric Blue": return electricBlue
        case "Neon Purple": return neonPurple
        case "Sunset Orange": return sunsetOrange
        case "Hot Pink": return hotPink
        case "Lime Green": return limeGreen
        case "Teal Blue": return tealBlue
        case "Golden Yellow": return goldenYellow
        case "Scarlet Red": return scarletRed
        default: return electricBlue
        }
    }
    
    static let allColorNames = [
        "Electric Blue", "Neon Purple", "Sunset Orange", "Hot Pink",
        "Lime Green", "Teal Blue", "Golden Yellow", "Scarlet Red"
    ]
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
