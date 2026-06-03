import SwiftUI
import SwiftData

// Watch settings — weight unit + calibration entry per exercise.
struct WatchSettingsView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query private var allSettings: [UserSettings]
    @Environment(\.modelContext) private var context

    private var settings: UserSettings {
        if let s = allSettings.first { return s }
        let s = UserSettings()
        context.insert(s)
        return s
    }

    var body: some View {
        List {
            Section("Units") {
                Picker("Weight", selection: Binding(
                    get: { settings.weightUnit },
                    set: { settings.weightUnit = $0; try? context.save() }
                )) {
                    Text("lbs").tag(WeightUnit.lbs)
                    Text("kg").tag(WeightUnit.kg)
                }
            }

            Section("Calibration") {
                ForEach(exercises) { exercise in
                    NavigationLink(destination: CalibrationView(exercise: exercise)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.shortName)
                                    .font(.system(.body, design: .rounded, weight: .medium))

                                if settings.isCalibrated(for: exercise.id) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.green)
                                        Text(calibrationLabel(for: exercise))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    Text("Default threshold")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }

    private func calibrationLabel(for exercise: Exercise) -> String {
        guard let date = settings.calibrationDate(for: exercise.id) else { return "Calibrated" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
