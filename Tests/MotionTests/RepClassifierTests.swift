import XCTest
import CoreMotion
@testable import gymOS

// Tests RepClassifier state machine using synthetic CMDeviceMotion data.
// CMDeviceMotion.userAcceleration is gravity-free — at rest all axes = 0.

final class RepClassifierTests: XCTestCase {

    private func makeClassifier(alpha: Double = 1.0) -> RepClassifier {
        // alpha=1.0 disables EMA smoothing in tests — raw values pass through
        // so test assertions match exactly what we feed in.
        var def = ExerciseCatalog.benchPress
        def = ExerciseDefinition(
            name: def.name, shortName: def.shortName,
            muscleGroup: def.muscleGroup, dominantAxis: def.dominantAxis,
            motionDirection: def.motionDirection,
            repMinDuration: def.repMinDuration, repMaxDuration: def.repMaxDuration,
            accelerationThreshold: def.accelerationThreshold,
            smoothingAlpha: alpha
        )
        return RepClassifier(exercise: def)
    }

    private func simulateRep(
        classifier: RepClassifier,
        peakAcceleration: Double = 1.5,
        durationSeconds: Double = 0.5,
        startTimestamp: TimeInterval = 0
    ) {
        let sampleInterval = 0.02
        let steps = Int(durationSeconds / sampleInterval)

        for i in 0..<steps {
            let progress = Double(i) / Double(steps)
            let value = peakAcceleration * sin(.pi * progress)
            classifier.processSample(
                CMDeviceMotionStub(y: value, timestamp: startTimestamp + Double(i) * sampleInterval)
            )
        }
        classifier.processSample(
            CMDeviceMotionStub(y: 0.0, timestamp: startTimestamp + durationSeconds)
        )
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
        for i in 0..<5 {
            simulateRep(classifier: classifier, startTimestamp: Double(i) * 0.8)
        }
        XCTAssertEqual(classifier.repCount, 5)
    }

    func test_no_rep_below_threshold() {
        let classifier = makeClassifier()
        for i in 0..<100 {
            classifier.processSample(CMDeviceMotionStub(y: 0.3, timestamp: Double(i) * 0.02))
        }
        XCTAssertEqual(classifier.repCount, 0)
    }

    func test_no_rep_when_duration_too_short() {
        let classifier = makeClassifier()
        // Spike for 0.1s — below repMinDuration (0.3s)
        classifier.processSample(CMDeviceMotionStub(y: 1.5, timestamp: 0.0))
        classifier.processSample(CMDeviceMotionStub(y: 0.0, timestamp: 0.1))
        XCTAssertEqual(classifier.repCount, 0)
    }

    func test_no_rep_when_duration_exceeds_max() {
        let classifier = makeClassifier()
        let interval = 0.02
        // Hold above threshold for 4s — exceeds repMaxDuration (3.0s)
        for i in 0..<200 {
            classifier.processSample(CMDeviceMotionStub(y: 1.5, timestamp: Double(i) * interval))
        }
        classifier.processSample(CMDeviceMotionStub(y: 0.0, timestamp: 200 * interval))
        XCTAssertEqual(classifier.repCount, 0)
    }

    func test_velocity_sample_recorded_per_rep() {
        let classifier = makeClassifier()
        simulateRep(classifier: classifier, peakAcceleration: 2.0)
        XCTAssertEqual(classifier.velocitySamples.count, 1)
        XCTAssertGreaterThan(classifier.velocitySamples[0], 0)
    }

    func test_reset_clears_all_state() {
        let classifier = makeClassifier()
        simulateRep(classifier: classifier)
        XCTAssertEqual(classifier.repCount, 1)
        classifier.reset()
        XCTAssertEqual(classifier.repCount, 0)
        XCTAssertTrue(classifier.velocitySamples.isEmpty)
    }

    func test_ema_smoothing_blocks_single_spike() {
        // Use real alpha — spike should be dampened below threshold
        let classifier = makeClassifier(alpha: 0.25)
        // Warm up filter at zero
        for i in 0..<30 {
            classifier.processSample(CMDeviceMotionStub(y: 0.0, timestamp: Double(i) * 0.02))
        }
        // Single spike — one sample above threshold, immediately returns to 0
        classifier.processSample(CMDeviceMotionStub(y: 5.0, timestamp: 0.62))
        classifier.processSample(CMDeviceMotionStub(y: 0.0, timestamp: 0.64))
        // With alpha=0.25: filtered spike = 0.25×5 + 0.75×0 = 1.25g — just above threshold
        // but below duration gate (only 0.02s), so no rep
        XCTAssertEqual(classifier.repCount, 0)
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

// Stub CMDeviceMotion — inject userAcceleration values for testing
final class CMDeviceMotionStub: CMDeviceMotion {
    private let _x: Double, _y: Double, _z: Double, _ts: TimeInterval

    init(x: Double = 0, y: Double = 0, z: Double = 0, timestamp: TimeInterval = 0) {
        _x = x; _y = y; _z = z; _ts = timestamp
        super.init()
    }

    required init?(coder: NSCoder) { fatalError() }

    override var userAcceleration: CMAcceleration {
        CMAcceleration(x: _x, y: _y, z: _z)
    }
    override var timestamp: TimeInterval { _ts }
}
