import SwiftUI

extension Color {
    // Backgrounds
    static let bgBase      = Color(hex: "#0A0A0A")
    static let bgCard      = Color(hex: "#111111")
    static let bgElevated  = Color(hex: "#1C1C1E")

    // Borders
    static let border      = Color(hex: "#2C2C2E")

    // Text
    static let textPrimary   = Color(hex: "#FFFFFF")
    static let textSecondary = Color(hex: "#A1A1AA")
    static let textMuted     = Color(hex: "#52525B")

    // Semantic
    static let accentGreen  = Color(hex: "#22C55E")
    static let accentOrange = Color(hex: "#F97316")
    static let accentRed    = Color(hex: "#EF4444")

    // Muscle group chart
    static let chartChest     = Color(hex: "#3B82F6")
    static let chartLegs      = Color(hex: "#22C55E")
    static let chartBack      = Color(hex: "#F59E0B")
    static let chartShoulders = Color(hex: "#A855F7")

    static func chartColor(for group: MuscleGroup) -> Color {
        switch group {
        case .chest:     return .chartChest
        case .legs:      return .chartLegs
        case .back:      return .chartBack
        case .shoulders: return .chartShoulders
        }
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
