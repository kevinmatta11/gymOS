import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @ObservedObject var viewModel: SessionViewModel
    @Query(sort: \Exercise.name) var exercises: [Exercise]

    var body: some View {
        List(exercises) { exercise in
            Button(action: { viewModel.selectExercise(exercise) }) {
                HStack {
                    Text(exercise.shortName)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                    Spacer()
                    Image(systemName: muscleGroupIcon(exercise.muscleGroup))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Select Exercise")
    }

    private func muscleGroupIcon(_ group: MuscleGroup) -> String {
        switch group {
        case .chest:     return "figure.strengthtraining.traditional"
        case .legs:      return "figure.squat"
        case .back:      return "figure.pull.up"
        case .shoulders: return "figure.arms.open"
        }
    }
}
