import XCTest
@testable import gymOS

final class WorkoutSetTests: XCTestCase {

    func test_volume_equals_weight_times_reps() {
        let set = WorkoutSet(
            sessionId: UUID(), exerciseId: UUID(), exerciseName: "Bench",
            reps: 8, weightLbs: 135.0
        )
        XCTAssertEqual(set.volume, 1080.0, accuracy: 0.001)
    }

    func test_epley1RM_formula_exactness() {
        // 135 lbs × (1 + 8/30) = 135 × 1.2667 = 171.0
        let set = WorkoutSet(
            sessionId: UUID(), exerciseId: UUID(), exerciseName: "Bench",
            reps: 8, weightLbs: 135.0
        )
        let expected = 135.0 * (1 + 8.0 / 30.0)
        XCTAssertEqual(set.epley1RM, expected, accuracy: 0.001)
    }

    func test_epley1RM_confidence_band_is_10_percent() {
        let set = WorkoutSet(
            sessionId: UUID(), exerciseId: UUID(), exerciseName: "Bench",
            reps: 5, weightLbs: 225.0
        )
        XCTAssertEqual(set.epley1RMUpperBound, set.epley1RM * 1.10, accuracy: 0.001)
        XCTAssertEqual(set.epley1RMLowerBound, set.epley1RM * 0.90, accuracy: 0.001)
    }

    func test_epley1RM_returns_zero_for_zero_reps() {
        let set = WorkoutSet(
            sessionId: UUID(), exerciseId: UUID(), exerciseName: "Bench",
            reps: 0, weightLbs: 135.0
        )
        XCTAssertEqual(set.epley1RM, 0)
    }

    func test_averageVelocity_empty_samples_returns_zero() {
        let set = WorkoutSet(
            sessionId: UUID(), exerciseId: UUID(), exerciseName: "Bench",
            reps: 5, weightLbs: 135.0, velocitySamples: []
        )
        XCTAssertEqual(set.averageVelocity, 0)
    }

    func test_averageVelocity_computes_mean() {
        let set = WorkoutSet(
            sessionId: UUID(), exerciseId: UUID(), exerciseName: "Bench",
            reps: 3, weightLbs: 135.0, velocitySamples: [2.0, 1.8, 1.6]
        )
        XCTAssertEqual(set.averageVelocity, (2.0 + 1.8 + 1.6) / 3.0, accuracy: 0.001)
    }
}
