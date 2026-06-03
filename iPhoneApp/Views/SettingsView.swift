import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var allSettings: [UserSettings]
    @Environment(\.modelContext) private var context

    private var settings: UserSettings {
        allSettings.first ?? UserSettings()
    }

    var body: some View {
        Form {
            Section("Units") {
                Picker("Weight Unit", selection: Binding(
                    get: { settings.weightUnit },
                    set: { newValue in
                        settings.weightUnit = newValue
                        try? context.save()
                    }
                )) {
                    ForEach(WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue.uppercased()).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Storage", value: "Local only — no account required")
            }
        }
        .navigationTitle("Settings")
    }
}
