import Foundation
import CoreMotion
import Combine

// Owns the CMMotionManager. Bridges raw accelerometer samples to RepClassifier and RestDetector.
// One instance per Watch session — start(for:) begins a set, stop() ends it.

@MainActor
final class MotionManager: ObservableObject {
    static let shared = MotionManager()

    @Published private(set) var repCount: Int = 0
    @Published private(set) var isDetecting: Bool = false

    var onSetEnded: ((_ reps: Int, _ velocitySamples: [Double]) -> Void)?

    private let motionManager = CMMotionManager()
    private var classifier: RepClassifier?
    private let restDetector = RestDetector()

    private let sampleFrequency: Double = 50   // Hz

    private init() {}

    func start(for exercise: ExerciseDefinition) {
        guard motionManager.isAccelerometerAvailable else { return }

        let newClassifier = RepClassifier(exercise: exercise)
        newClassifier.delegate = self
        classifier = newClassifier
        restDetector.reset()

        restDetector.onRestDetected = { [weak self] in
            Task { @MainActor in self?.handleRestDetected() }
        }

        motionManager.accelerometerUpdateInterval = 1.0 / sampleFrequency
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.classifier?.processSample(data)
            self.restDetector.processSample(data)
        }

        repCount = 0
        isDetecting = true
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
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
        Task { @MainActor in
            self.repCount = repCount
        }
    }
}
