import Foundation
import CoreMotion

// Detects reps for a single known exercise using CMDeviceMotion.userAcceleration.
// userAcceleration is gravity-free — clean dynamic signal from the lift only.
//
// Pipeline per sample:
//   raw userAcceleration → EMA filter (per axis) → dominant axis extraction
//   → direction sign → state machine (IDLE → ACTIVE → COMPLETE)
//
// Velocity estimate: peak filtered acceleration during ACTIVE phase.

protocol RepClassifierDelegate: AnyObject {
    func classifierDidDetectRep(repCount: Int, peakAcceleration: Double)
}

final class RepClassifier {
    private let exercise: ExerciseDefinition
    private let threshold: Double           // calibrated or catalog default

    private(set) var repCount: Int = 0
    private(set) var velocitySamples: [Double] = []

    weak var delegate: RepClassifierDelegate?

    // EMA filters — one per axis, reset between sets
    private var filterX: EMAFilter
    private var filterY: EMAFilter
    private var filterZ: EMAFilter

    // State machine
    private enum State { case idle, active }
    private var state: State = .idle
    private var phaseStartTime: Date?
    private var peakInPhase: Double = 0

    // Minimum time between rep completions — prevents double-count on oscillation
    private let repCooldown: Double = 0.25
    private var lastRepTime: Date?

    init(exercise: ExerciseDefinition, calibratedThreshold: Double? = nil) {
        self.exercise = exercise
        self.threshold = calibratedThreshold ?? exercise.accelerationThreshold
        let alpha = exercise.smoothingAlpha
        filterX = EMAFilter(alpha: alpha)
        filterY = EMAFilter(alpha: alpha)
        filterZ = EMAFilter(alpha: alpha)
    }

    func reset() {
        repCount = 0
        velocitySamples = []
        state = .idle
        phaseStartTime = nil
        peakInPhase = 0
        lastRepTime = nil
        filterX.reset()
        filterY.reset()
        filterZ.reset()
    }

    // Feed one CMDeviceMotion sample. Call at ~50Hz from MotionManager.
    func processSample(_ motion: CMDeviceMotion) {
        let ua = motion.userAcceleration

        // Apply EMA filter per axis
        let x = filterX.process(ua.x)
        let y = filterY.process(ua.y)
        let z = filterZ.process(ua.z)

        // Extract dominant axis, apply direction sign
        let raw = axisValue(x: x, y: y, z: z)
        let signed = exercise.motionDirection == .positive ? raw : -raw

        let now = Date()

        switch state {
        case .idle:
            guard signed >= threshold else { return }
            if let last = lastRepTime, now.timeIntervalSince(last) < repCooldown { return }
            state = .active
            phaseStartTime = now
            peakInPhase = signed

        case .active:
            peakInPhase = max(peakInPhase, signed)
            let elapsed = phaseStartTime.map { now.timeIntervalSince($0) } ?? 0

            if elapsed > exercise.repMaxDuration {
                // Movement lasted too long — not a rep, bail
                state = .idle
                phaseStartTime = nil
                peakInPhase = 0
                return
            }

            if signed < threshold {
                // Returned below threshold — valid rep if duration gate passes
                if elapsed >= exercise.repMinDuration {
                    repCount += 1
                    velocitySamples.append(peakInPhase)
                    lastRepTime = now
                    delegate?.classifierDidDetectRep(
                        repCount: repCount,
                        peakAcceleration: peakInPhase
                    )
                }
                state = .idle
                phaseStartTime = nil
                peakInPhase = 0
            }
        }
    }

    private func axisValue(x: Double, y: Double, z: Double) -> Double {
        switch exercise.dominantAxis {
        case .x: return x
        case .y: return y
        case .z: return z
        }
    }
}
