import SwiftUI

extension Font {
    // 64pt — the dominant number on each screen
    static let hero = Font.system(size: 64, weight: .bold, design: .rounded)

    // 40pt — secondary metric numbers inside cards
    static let sectionNumber = Font.system(size: 40, weight: .bold, design: .rounded)

    // 28pt — session list volume
    static let cardNumber = Font.system(size: 28, weight: .bold, design: .rounded)

    // 18pt — exercise name in detail view
    static let cardTitle = Font.system(size: 18, weight: .semibold, design: .default)

    // 14pt body
    static let body14 = Font.system(size: 14, weight: .regular)

    // 14pt monospaced — set table columns
    static let mono = Font.system(size: 14, weight: .medium, design: .monospaced)

    // 13pt — small labels
    static let label13 = Font.system(size: 13, weight: .medium)

    // 11pt uppercase label — card section titles
    static let cardLabel = Font.system(size: 11, weight: .semibold)
}

// Card section label: 11pt uppercase secondary
struct CardLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.cardLabel)
            .tracking(1.5)
            .foregroundStyle(Color.textSecondary)
    }
}
