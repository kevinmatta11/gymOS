import SwiftUI

// Shown after weight is confirmed — displays last set summary, offers next set or end.
struct BetweenSetsView: View {
    @ObservedObject var viewModel: SessionViewModel
    var unit: WeightUnit

    var body: some View {
        VStack(spacing: 12) {
            if let summary = viewModel.lastSetSummary {
                VStack(spacing: 2) {
                    HStack {
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
                Button("Next Set") {
                    viewModel.beginSet()
                }
                .buttonStyle(.bordered)
                .tint(.blue)

                Button("Change Exercise") {
                    // Pops to exercise picker
                }
                .buttonStyle(.borderless)
                .font(.caption)

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
