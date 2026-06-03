import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var allSettings: [UserSettings]
    @Environment(\.modelContext) private var context

    private var settings: UserSettings {
        if let s = allSettings.first { return s }
        let s = UserSettings()
        context.insert(s)
        return s
    }

    var body: some View {
        ZStack {
            Color.bgBase.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {

                    // Units
                    LabeledCard("Units") {
                        HStack {
                            Text("Weight")
                                .font(.body14)
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            WeightUnitPicker(
                                selection: Binding(
                                    get: { settings.weightUnit },
                                    set: { settings.weightUnit = $0; try? context.save() }
                                )
                            )
                        }
                    }
                    .padding(.horizontal, 16)

                    // About
                    LabeledCard("About") {
                        VStack(spacing: 12) {
                            InfoRow(label: "Version", value: "1.0.0")
                            Rectangle().fill(Color.border).frame(height: 0.5)
                            InfoRow(label: "Storage", value: "Local only")
                            Rectangle().fill(Color.border).frame(height: 0.5)
                            InfoRow(label: "Network", value: "None")
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer().frame(height: 32)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.bgBase, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: — Sub-components

private struct WeightUnitPicker: View {
    @Binding var selection: WeightUnit

    var body: some View {
        HStack(spacing: 2) {
            ForEach(WeightUnit.allCases, id: \.self) { unit in
                Button(action: { withAnimation(.easeInOut(duration: 0.15)) { selection = unit } }) {
                    Text(unit.rawValue.uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(0.5)
                        .foregroundStyle(selection == unit ? Color.bgBase : Color.textSecondary)
                        .frame(width: 44, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selection == unit ? Color.textPrimary : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 9))
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.body14)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Text(value)
                .font(.body14)
                .foregroundStyle(Color.textMuted)
        }
    }
}
