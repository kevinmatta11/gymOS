import Foundation
import CoreMotion

// Detects reps and measures velocity for a single known exercise.
// Stateful — one instance per active set. Reset between sets.
//
// Algorithm: state machine on the dominant accelerometer axis.
// IDLE → ACTIVE when acceleration exceeds threshold in expected direction.
// ACTIVE → COMPLETE when acceleration returns below threshold and duration is within gate.
// ACTIVE → IDLE (timeout) if duration exceeds repMaxDuration without returning.
//
// Velocity estimate: peak acceleration during the ACTIVE phase = proxy for bar velocity.
// Higher peak = more force = faster movement.

protocol RepClassifierDelegate: AnyObject {
    func classifierDidDetectRep(repCount: Int, peakAcceleration: Double)
}

final class RepClassifier {
    private let exercise: ExerciseDefinition

    private(set) var repCount: Int = 0
    private(set) var velocitySamples: [Double] = []

    weak var delegate: RepClassifierDelegate?

    // State machine
    private enum State { case idle, active }
    private var state: State = .idle
    private var phaseStartTime: Date?
    private var peakAccelerationInPhase: Double = 0

    // Cooldown after a completed rep — prevents double counting on noisy signal
    private let repCooldownSeconds: Double = 0.25
    private var lastRepTime: Date?

    init(exercise: ExerciseDefinition) {
        self.exercise = exercise
    }

    func reset() {
        repCount = 0
        velocitySamples = []
        state = .idle
        phaseStartTime = nil
        peakAccelerationInPhase = 0
        lastRepTime = nil
    }

    // Feed one accelerometer sample. Call at ~50Hz from MotionManager.
    func processSample(_ data: CMAccelerometerData) {
        let value = axisValue(from: data.acceleration)
        let signed = exercise.motionDirection == .positive ? value : -value
        let now = data.timestamp  // monotonic clock, seconds since boot

        switch state {
        case .idle:
            guard signed >= exercise.accelerationThreshold else { return }
            // Check cooldown — don't start a new rep immediately after the last one
            if let last = lastRepTime, Date().timeIntervalSince(last) < repCooldownSeconds { return }
            state = .active
            phaseStartTime = Date()
            peakAccelerationInPhase = signed

        case .active:
            peakAccelerationInPhase = max(peakAccelerationInPhase, signed)

            let elapsed = phaseStartTime.map { Date().timeIntervalSince($0) } ?? 0

            if elapsed > exercise.repMaxDuration {
                // Took too long — not a rep, reset
                state = .idle
                phaseStartTime = nil
                peakAccelerationInPhase = 0
                return
            }

            if signed < exercise.accelerationThreshold {
                // Returned below threshold — check minimum duration
                if elapsed >= exercise.repMinDuration {
                    repCount += 1
                    velocitySamples.append(peakAccelerationInPhase)
                    lastRepTime = Date()
                    delegate?.classifierDidDetectRep(
                        repCount: repCount,
                        peakAcceleration: peakAccelerationInPhase
                    )
                }
                state = .idle
                phaseStartTime = nil
                peakAccelerationInPhase = 0
            }
        }
    }

    private func axisValue(from acceleration: CMAcceleration) -> Double {
        switch exercise.dominantAxis {
        case .x: return acceleration.x
        case .y: return acceleration.y
        case .z: return acceleration.z
        }
    }
}
