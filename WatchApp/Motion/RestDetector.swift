import Foundation
import CoreMotion

// Detects set-end via a 3-second quiet period using CMDeviceMotion.userAcceleration.
// userAcceleration is gravity-free — at rest all axes read ~0g.
// Quiet = total acceleration magnitude stays below quietThreshold for requiredQuietSeconds.

final class RestDetector {
    var onRestDetected: (() -> Void)?

    // Tighter threshold than the old gravity-offset approach — userAcceleration
    // has no 1g baseline to subtract, so noise floor is genuinely near zero.
    private let quietThreshold: Double = 0.08  // g
    private let requiredQuietSeconds: Double = 3.0

    private var quietStart: Date?
    private var hasFired = false

    func reset() {
        quietStart = nil
        hasFired = false
    }

    func processSample(_ motion: CMDeviceMotion) {
        guard !hasFired else { return }

        let ua = motion.userAcceleration
        let magnitude = sqrt(ua.x*ua.x + ua.y*ua.y + ua.z*ua.z)

        if magnitude > quietThreshold {
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
