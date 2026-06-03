import SwiftUI
import SwiftData

// Root Watch view — routes to the correct screen based on SessionViewModel.phase.
struct WatchContentView: View {
    @StateObject private var viewModel: SessionViewModel
    @Query private var allSettings: [UserSettings]

    private var unit: WeightUnit { allSettings.first?.weightUnit ?? .lbs }

    init(repository: WorkoutRepository) {
        _viewModel = StateObject(wrappedValue: SessionViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            switch viewModel.phase {
            case .idle, .ready:
                ExercisePickerView(viewModel: viewModel)

            case .detecting:
                ActiveSetView(viewModel: viewModel)

            case .confirming:
                WeightConfirmView(viewModel: viewModel, unit: unit)

            case .summary:
                BetweenSetsView(viewModel: viewModel, unit: unit)

            case .finished:
                SessionFinishedView()
            }
        }
        // Inject settings whenever they load so beginSet() can read calibrated thresholds
        .onChange(of: allSettings.first?.calibratedThresholds) { _, _ in
            viewModel.userSettings = allSettings.first
        }
        .onAppear {
            viewModel.userSettings = allSettings.first
        }
    }
}

private struct SessionFinishedView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            Text("Session saved")
                .font(.headline)
            Text("Open iPhone for summary")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
