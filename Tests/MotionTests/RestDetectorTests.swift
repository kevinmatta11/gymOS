import XCTest
import CoreMotion
@testable import gymOS

final class RestDetectorTests: XCTestCase {

    private func makeSample(magnitude: Double, timestamp: TimeInterval) -> CMAccelerometerData {
        // Z = magnitude (simulates device held still with variable activity)
        CMAccelerometerDataStubForRest(x: 0, y: 0, z: magnitude, timestamp: timestamp)
    }

    func test_fires_after_3_seconds_of_quiet() {
        let detector = RestDetector()
        var fired = false
        detector.onRestDetected = { fired = true }

        var t: TimeInterval = 0
        // 3.1 seconds of quiet (magnitude ≈ 1.0g = device at rest)
        while t < 3.1 {
            detector.processSample(makeSample(magnitude: 1.0, timestamp: t))
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
            detector.processSample(makeSample(magnitude: 1.0, timestamp: t))
            t += 0.02
        }

        XCTAssertFalse(fired)
    }

    func test_resets_timer_on_movement() {
        let detector = RestDetector()
        var fired = false
        detector.onRestDetected = { fired = true }

        // 2 seconds quiet
        var t: TimeInterval = 0
        while t < 2.0 {
            detector.processSample(makeSample(magnitude: 1.0, timestamp: t))
            t += 0.02
        }

        // Movement — magnitude spikes
        detector.processSample(makeSample(magnitude: 2.5, timestamp: t))
        t += 0.02

        // Another 2.8 seconds quiet — should NOT fire yet
        let afterMovement = t
        while t < afterMovement + 2.8 {
            detector.processSample(makeSample(magnitude: 1.0, timestamp: t))
            t += 0.02
        }

        XCTAssertFalse(fired)
    }

    func test_fires_only_once_per_reset() {
        let detector = RestDetector()
        var fireCount = 0
        detector.onRestDetected = { fireCount += 1 }

        var t: TimeInterval = 0
        while t < 6.0 {
            detector.processSample(makeSample(magnitude: 1.0, timestamp: t))
            t += 0.02
        }

        XCTAssertEqual(fireCount, 1)
    }
}

private final class CMAccelerometerDataStubForRest: CMAccelerometerData {
    private let _x: Double, _y: Double, _z: Double, _ts: TimeInterval

    init(x: Double, y: Double, z: Double, timestamp: TimeInterval) {
        _x = x; _y = y; _z = z; _ts = timestamp
        super.init()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var acceleration: CMAcceleration { CMAcceleration(x: _x, y: _y, z: _z) }
    override var timestamp: TimeInterval { _ts }
}
