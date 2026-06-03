import Foundation
import CoreMotion

// Detects the end of a set via a 3-second quiet period on the accelerometer.
// "Quiet" = total acceleration magnitude stays below a movement threshold.
// Fires onRestDetected once per quiet period; resets if motion resumes.

final class RestDetector {
    var onRestDetected: (() -> Void)?

    private let quietThreshold: Double = 0.15   // g — total magnitude above baseline (1g gravity)
    private let requiredQuietSeconds: Double = 3.0

    private var quietStart: Date?
    private var hasFired = false

    func reset() {
        quietStart = nil
        hasFired = false
    }

    func processSample(_ data: CMAccelerometerData) {
        guard !hasFired else { return }

        let a = data.acceleration
        // Remove gravity component (device at rest ≈ 1g on Z).
        // Total dynamic acceleration = magnitude minus 1g baseline.
        let magnitude = sqrt(a.x*a.x + a.y*a.y + a.z*a.z)
        let dynamic = abs(magnitude - 1.0)

        if dynamic > quietThreshold {
            // Movement detected — reset quiet timer
            quietStart = nil
            return
        }

        let now = Date()
        if quietStart == nil {
            quietStart = now
        } else if let start = quietStart, now.timeIntervalSince(start) >= requiredQuietSeconds {
            hasFired = true
            onRestDetected?()
        }
    }
}
