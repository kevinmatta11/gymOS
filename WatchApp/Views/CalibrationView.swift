import SwiftUI
import SwiftData
import CoreMotion

// One-time per-exercise calibration flow.
// User performs 5 real reps → app records peaks → computes personal threshold.
// Threshold stored in UserSettings, used by RepClassifier on every future set.

struct CalibrationView: View {
    let exercise: Exercise
    @Query private var allSettings: [UserSettings]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @StateObject private var calibrator = CalibrationManager()

    private var settings: UserSettings {
        allSettings.first ?? UserSettings()
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch calibrator.phase {
            case .ready:     readyView
            case .recording: recordingView
            case .done:      doneView
            case .failed:    failedView
            }
        }
        .navigationTitle("Calibrate")
        .onDisappear { calibrator.stop() }
    }

    // MARK: — Phase views

    private var readyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 32, weight: .thin))
                .foregroundStyle(.white)

            Text(exercise.shortName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.gray)

            Text("Do 5 reps at normal pace")
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Button("Start") {
                let definition = ExerciseCatalog.all.first { $0.name == exercise.name }
                    ?? ExerciseCatalog.benchPress
                calibrator.start(exercise: definition)
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
        .padding()
    }

    private var recordingView: some View {
        VStack(spacing: 16) {
            // Rep count display
            Text("\(calibrator.detectedReps)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            Text("of 5 reps")
                .font(.system(size: 13))
                .foregroundStyle(.gray)

            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(i < calibrator.detectedReps ? Color.white : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: calibrator.detectedReps)
                }
            }
        }
    }

    private var doneView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.green)

            Text("Calibrated")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            if let threshold = calibrator.computedThreshold {
                VStack(spacing: 2) {
                    Text(String(format: "Threshold: %.2fg", threshold))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                    Text(String(format: "Default: %.2fg", exercise.accelerationThreshold))
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }
            }

            HStack(spacing: 8) {
                Button("Save") {
                    if let threshold = calibrator.computedThreshold {
                        settings.setCalibrated(threshold: threshold, for: exercise.id)
                        try? context.save()
                    }
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.white)

                Button("Redo") {
                    calibrator.reset()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.gray)
                .font(.caption)
            }
        }
        .padding()
    }

    private var failedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(.orange)
            Text("Not enough reps detected")
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Button("Try Again") { calibrator.reset() }
                .buttonStyle(.bordered)
                .tint(.white)
        }
        .padding()
    }
}

// MARK: — CalibrationManager

@MainActor
final class CalibrationManager: ObservableObject {
    enum Phase { case ready, recording, done, failed }

    @Published private(set) var phase: Phase = .ready
    @Published private(set) var detectedReps: Int = 0
    @Published private(set) var computedThreshold: Double?

    private let motionManager = CMMotionManager()
    private var peaks: [Double] = []
    private var classifier: RepClassifier?

    private let targetReps = 5

    func start(exercise: ExerciseDefinition) {
        guard motionManager.isDeviceMotionAvailable else { return }
        peaks = []
        detectedReps = 0
        phase = .recording

        // Use a lower-than-default threshold for calibration to catch all reps
        let calibrationDefinition = ExerciseDefinition(
            name: exercise.name,
            shortName: exercise.shortName,
            muscleGroup: exercise.muscleGroup,
            dominantAxis: exercise.dominantAxis,
            motionDirection: exercise.motionDirection,
            repMinDuration: exercise.repMinDuration,
            repMaxDuration: exercise.repMaxDuration,
            accelerationThreshold: exercise.accelerationThreshold * 0.6,  // wider net
            smoothingAlpha: exercise.smoothingAlpha
        )

        let c = RepClassifier(exercise: calibrationDefinition)
        c.delegate = self
        classifier = c

        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.classifier?.processSample(motion)
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }

    func reset() {
        stop()
        peaks = []
        detectedReps = 0
        computedThreshold = nil
        classifier = nil
        phase = .ready
    }

    private func finish() {
        stop()
        guard peaks.count >= targetReps else {
            phase = .failed
            return
        }

        // threshold = mean(peaks) - 0.5 × stddev(peaks)
        // Sits below the mean but above noise floor — tolerates rep-to-rep variation
        let mean = peaks.reduce(0, +) / Double(peaks.count)
        let variance = peaks.map { pow($0 - mean, 2) }.reduce(0, +) / Double(peaks.count)
        let stddev = sqrt(variance)
        computedThreshold = max(0.3, mean - 0.5 * stddev)  // floor at 0.3g
        phase = .done
    }
}

extension CalibrationManager: RepClassifierDelegate {
    nonisolated func classifierDidDetectRep(repCount: Int, peakAcceleration: Double) {
        Task { @MainActor in
            self.peaks.append(peakAcceleration)
            self.detectedReps = repCount
            if repCount >= self.targetReps {
                self.finish()
            }
        }
    }
}
