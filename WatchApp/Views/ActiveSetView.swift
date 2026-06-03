import SwiftUI

// Shown during an active set — large live rep counter, exercise name.
// Picker is locked (not accessible) while detecting.
struct ActiveSetView: View {
    @ObservedObject var viewModel: SessionViewModel
    @ObservedObject private var motion = MotionManager.shared

    var body: some View {
        VStack(spacing: 4) {
            Text(viewModel.activeExercise?.shortName ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Text("\(motion.repCount)")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.spring(response: 0.2), value: motion.repCount)

            Text("reps")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
    }
}
