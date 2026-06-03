import XCTest
import CoreMotion
@testable import gymOS

// Tests the RepClassifier state machine using synthetic accelerometer data.
// These are unit tests with fabricated CMAccelerometerData — not real motion.
// Real-world calibration is done separately (scripts/calibrate.sh).

final class RepClassifierTests: XCTestCase {

    private func makeClassifier() -> RepClassifier {
        RepClassifier(exercise: ExerciseCatalog.benchPress)
    }

    // Simulate a single clean rep: Y axis rises above threshold, holds, returns below.
    private func simulateRep(
        classifier: RepClassifier,
        peakAcceleration: Double = 2.0,
        durationSeconds: Double = 0.5,
        timestamp: TimeInterval = 0
    ) {
        let sampleInterval = 0.02   // 50Hz
        var t = timestamp
        let steps = Int(durationSeconds / sampleInterval)

        for i in 0..<steps {
            let progress = Double(i) / Double(steps)
            // Sine curve: rises to peak, returns below threshold
            let value = peakAcceleration * sin(.pi * progress)
            classifier.processSample(makeSample(y: value, timestamp: t))
            t += sampleInterval
        }
        // Final sample below threshold to complete the rep
        classifier.processSample(makeSample(y: 0.0, timestamp: t))
    }

    private func makeSample(x: Double = 0, y: Double = 0, z: Double = 0, timestamp: TimeInterval = 0) -> CMAccelerometerData {
        CMAccelerometerDataStub(x: x, y: y, z: z, timestamp: timestamp)
    }

    func test_single_rep_detected() {
        let classifier = makeClassifier()
        var count = 0
        classifier.delegate = RepDelegate { c, _ in count = c }

        simulateRep(classifier: classifier)

        XCTAssertEqual(count, 1)
        XCTAssertEqual(classifier.repCount, 1)
    }

    func test_five_reps_detected() {
        let classifier = makeClassifier()
        var t: TimeInterval = 0

        for _ in 0..<5 {
            simulateRep(classifier: classifier, timestamp: t)
            t += 0.7   // 0.5s rep + 0.2s rest between reps
        }

        XCTAssertEqual(classifier.repCount, 5)
    }

    func test_no_rep_below_threshold() {
        let classifier = makeClassifier()
        // Below threshold (1.5g for bench)
        for _ in 0..<100 {
            classifier.processSample(makeSample(y: 0.8))
        }
        XCTAssertEqual(classifier.repCount, 0)
    }

    func test_no_rep_when_duration_too_short() {
        let classifier = makeClassifier()
        // Peak above threshold but returns below before min duration (0.3s)
        classifier.processSample(makeSample(y: 2.0, timestamp: 0))
        classifier.processSample(makeSample(y: 0.0, timestamp: 0.1))  // only 0.1s
        XCTAssertEqual(classifier.repCount, 0)
    }

    func test_no_rep_when_duration_too_long() {
        let classifier = makeClassifier()
        // Above threshold for 4 seconds — exceeds repMaxDuration (3.0s), should timeout
        let sampleInterval = 0.02
        var t: TimeInterval = 0
        for _ in 0..<200 {  // 4 seconds
            classifier.processSample(makeSample(y: 2.0, timestamp: t))
            t += sampleInterval
        }
        classifier.processSample(makeSample(y: 0.0, timestamp: t))
        XCTAssertEqual(classifier.repCount, 0)
    }

    func test_velocity_sample_recorded_per_rep() {
        let classifier = makeClassifier()
        simulateRep(classifier: classifier, peakAcceleration: 2.5)
        XCTAssertEqual(classifier.velocitySamples.count, 1)
        XCTAssertGreaterThan(classifier.velocitySamples[0], 0)
    }

    func test_reset_clears_state() {
        let classifier = makeClassifier()
        simulateRep(classifier: classifier)
        XCTAssertEqual(classifier.repCount, 1)

        classifier.reset()
        XCTAssertEqual(classifier.repCount, 0)
        XCTAssertTrue(classifier.velocitySamples.isEmpty)
    }
}

// MARK: — Test helpers

private final class RepDelegate: RepClassifierDelegate {
    let handler: (Int, Double) -> Void
    init(_ handler: @escaping (Int, Double) -> Void) { self.handler = handler }
    func classifierDidDetectRep(repCount: Int, peakAcceleration: Double) {
        handler(repCount, peakAcceleration)
    }
}

// CMAccelerometerData is not directly instantiable — stub via subclass.
private final class CMAccelerometerDataStub: CMAccelerometerData {
    private let _x: Double, _y: Double, _z: Double, _ts: TimeInterval

    init(x: Double, y: Double, z: Double, timestamp: TimeInterval) {
        _x = x; _y = y; _z = z; _ts = timestamp
        super.init()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var acceleration: CMAcceleration {
        CMAcceleration(x: _x, y: _y, z: _z)
    }
    override var timestamp: TimeInterval { _ts }
}
