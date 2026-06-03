import XCTest
import CoreMotion
@testable import gymOS

final class RestDetectorTests: XCTestCase {

    private func makeSample(magnitude: Double, timestamp: TimeInterval) -> CMDeviceMotion {
        // magnitude on Y axis — gravity-free userAcceleration
        CMDeviceMotionStub(y: magnitude, timestamp: timestamp)
    }

    func test_fires_after_3_seconds_of_quiet() {
        let detector = RestDetector()
        var fired = false
        detector.onRestDetected = { fired = true }

        var t: TimeInterval = 0
        while t < 3.1 {
            detector.processSample(makeSample(magnitude: 0.0, timestamp: t))
            t += 0.02
        }

        XCTAssertTrue(fired)
    }

    func test_does_not_fire_before_3_seconds() {
        let detector = RestDetector()
        var fired = false
        detector.onRestDetected = { fired = true }

        var t: TimeInterval = 0
        while t < 2.8 {
            detector.processSample(makeSample(magnitude: 0.0, timestamp: t))
            t += 0.02
        }

        XCTAssertFalse(fired)
    }

    func test_resets_timer_on_movement() {
        let detector = RestDetector()
        var fired = false
        detector.onRestDetected = { fired = true }

        var t: TimeInterval = 0
        while t < 2.0 {
            detector.processSample(makeSample(magnitude: 0.0, timestamp: t))
            t += 0.02
        }
        // Movement spike above quietThreshold (0.08g)
        detector.processSample(makeSample(magnitude: 0.5, timestamp: t))
        t += 0.02

        let afterMovement = t
        while t < afterMovement + 2.8 {
            detector.processSample(makeSample(magnitude: 0.0, timestamp: t))
            t += 0.02
        }

        XCTAssertFalse(fired)
    }

    func test_fires_only_once() {
        let detector = RestDetector()
        var fireCount = 0
        detector.onRestDetected = { fireCount += 1 }

        var t: TimeInterval = 0
        while t < 6.0 {
            detector.processSample(makeSample(magnitude: 0.0, timestamp: t))
            t += 0.02
        }

        XCTAssertEqual(fireCount, 1)
    }

    func test_quiet_threshold_respected() {
        let detector = RestDetector()
        var fired = false
        detector.onRestDetected = { fired = true }

        // 0.05g — below quietThreshold (0.08g) — should still be counted as quiet
        var t: TimeInterval = 0
        while t < 3.1 {
            detector.processSample(makeSample(magnitude: 0.05, timestamp: t))
            t += 0.02
        }

        XCTAssertTrue(fired)
    }
}
