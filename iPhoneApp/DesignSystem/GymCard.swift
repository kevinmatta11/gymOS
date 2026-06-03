import SwiftUI

// Primary card modifier — dark surface, border, no shadow.
struct GymCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.border, lineWidth: 0.5)
            )
    }
}

extension View {
    func gymCard() -> some View {
        modifier(GymCard())
    }
}

// Full-width card container with label header
struct LabeledCard<Content: View>: View {
    let label: String
    let content: Content

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardLabel(text: label)
            content
        }
        .gymCard()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
