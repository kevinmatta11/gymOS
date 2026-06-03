import SwiftUI

// Shown after weight is confirmed — last set summary, next-set or change-exercise options.
struct BetweenSetsView: View {
    @ObservedObject var viewModel: SessionViewModel
    var unit: WeightUnit

    var body: some View {
        VStack(spacing: 12) {
            // Last set summary
            if let summary = viewModel.lastSetSummary {
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Set \(summary.setNumber)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if summary.autoSaved {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                    Text("\(summary.reps) × \(unit.label(for: summary.weightLbs))")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                }
            }

            VStack(spacing: 6) {
                // Next set — same exercise
                Button("Next Set") {
                    viewModel.beginSet()
                }
                .buttonStyle(.bordered)
                .tint(.blue)

                // Change exercise — pops back to picker via phase reset
                Button("Change Exercise") {
                    viewModel.returnToExercisePicker()
                }
                .buttonStyle(.borderless)
                .font(.caption)

                // End session
                Button("End Session", role: .destructive) {
                    viewModel.endSession()
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
        .padding()
    }
}
