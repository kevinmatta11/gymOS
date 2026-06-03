import SwiftUI

// Large dominant number with a small unit label beneath.
// The central element on every screen — one idea, one number.
struct HeroNumber: View {
    let value: String
    let unit: String
    var size: CGFloat = 64

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: size, weight: .bold, design: .rounded))
                .tracking(-2)
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())

            Text(unit)
                .font(.label13)
                .foregroundStyle(Color.textSecondary)
        }
    }
}

// Inline delta badge: ↑ +7.5 lbs  or  ↓ -2.1 lbs
struct DeltaBadge: View {
    let delta: Double
    let unit: String
    var decimalPlaces: Int = 1

    private var isPositive: Bool { delta >= 0 }
    private var color: Color { isPositive ? .accentGreen : .accentRed }
    private var arrow: String { isPositive ? "↑" : "↓" }
    private var formatted: String {
        String(format: "%.\(decimalPlaces)f", abs(delta))
    }

    var body: some View {
        HStack(spacing: 3) {
            Text(arrow)
            Text("\(formatted) \(unit)")
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(color)
    }
}
