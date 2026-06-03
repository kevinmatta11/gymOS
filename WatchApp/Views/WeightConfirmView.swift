import SwiftUI

// Shown after a set ends — user adjusts weight via Digital Crown, then confirms.
struct WeightConfirmView: View {
    @ObservedObject var viewModel: SessionViewModel
    var unit: WeightUnit

    @State private var crownValue: Double = 0

    var body: some View {
        VStack(spacing: 8) {
            Text("SET COMPLETE")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text("\(viewModel.activeExercise?.shortName ?? "") · \(viewModel.liveRepCount) reps")
                .font(.caption)

            Text(unit.label(for: viewModel.currentWeightLbs))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .focusable()
                .digitalCrownRotation(
                    $crownValue,
                    from: 0,
                    through: 999,
                    by: unit.step,
                    sensitivity: .medium,
                    isContinuous: false,
                    isHapticFeedbackEnabled: true
                )
                .onChange(of: crownValue) { _, newValue in
                    viewModel.adjustWeight(by: crownValue - viewModel.currentWeightLbs)
                }

            HStack(spacing: 8) {
                Button("Cancel", role: .cancel) { viewModel.cancelSet() }
                    .buttonStyle(.bordered)
                    .tint(.gray)

                Button("Save") { viewModel.confirmWeight() }
                    .buttonStyle(.bordered)
                    .tint(.green)
            }

            CountdownBar(seconds: viewModel.confirmCountdown, total: 30)
                .frame(height: 3)
                .padding(.top, 4)
        }
        .padding()
        .onAppear { crownValue = viewModel.currentWeightLbs }
    }
}

private struct CountdownBar: View {
    let seconds: Int
    let total: Int

    var progress: Double { Double(seconds) / Double(total) }

    var body: some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: 2)
                .fill(progress > 0.33 ? Color.green : Color.orange)
                .frame(width: geo.size.width * progress)
                .animation(.linear(duration: 1), value: progress)
        }
        .background(Color.white.opacity(0.1))
    }
}
