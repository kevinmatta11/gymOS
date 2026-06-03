import Foundation
import CoreMotion
import Combine

// Owns CMMotionManager. Uses deviceMotion (not raw accelerometer) for gravity-free
// userAcceleration — cleaner signal for both rep detection and rest detection.

@MainActor
final class MotionManager: ObservableObject {
    static let shared = MotionManager()

    @Published private(set) var repCount: Int = 0
    @Published private(set) var isDetecting: Bool = false

    var onSetEnded: ((_ reps: Int, _ velocitySamples: [Double]) -> Void)?

    private let motionManager = CMMotionManager()
    private var classifier: RepClassifier?
    private let restDetector = RestDetector()

    private let sampleFrequency: Double = 50  // Hz

    private init() {}

    func start(for exercise: ExerciseDefinition, calibratedThreshold: Double? = nil) {
        guard motionManager.isDeviceMotionAvailable else { return }

        let newClassifier = RepClassifier(
            exercise: exercise,
            calibratedThreshold: calibratedThreshold
        )
        newClassifier.delegate = self
        classifier = newClassifier
        restDetector.reset()

        restDetector.onRestDetected = { [weak self] in
            Task { @MainActor in self?.handleRestDetected() }
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / sampleFrequency
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.classifier?.processSample(motion)
            self.restDetector.processSample(motion)
        }

        repCount = 0
        isDetecting = true
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        isDetecting = false
    }

    private func handleRestDetected() {
        stop()
        let reps = classifier?.repCount ?? 0
        let samples = classifier?.velocitySamples ?? []
        onSetEnded?(reps, samples)
    }
}

extension MotionManager: RepClassifierDelegate {
    nonisolated func classifierDidDetectRep(repCount: Int, peakAcceleration: Double) {
        Task { @MainActor in self.repCount = repCount }
    }
}
