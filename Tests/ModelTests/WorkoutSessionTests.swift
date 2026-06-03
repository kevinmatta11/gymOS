import XCTest
@testable import gymOS

final class WorkoutSessionTests: XCTestCase {
    private let exerciseId = UUID()
    private let sessionId = UUID()

    func makeSets(repsWeights: [(Int, Double)], velocities: [[Double]] = []) -> [WorkoutSet] {
        repsWeights.enumerated().map { i, rw in
            WorkoutSet(
                sessionId: sessionId,
                exerciseId: exerciseId,
                exerciseName: "Bench",
                reps: rw.0,
                weightLbs: rw.1,
                velocitySamples: i < velocities.count ? velocities[i] : []
            )
        }
    }

    func test_totalVolume_sums_all_sets() {
        let session = WorkoutSession()
        session.sets = makeSets(repsWeights: [(5, 135), (5, 145), (3, 155)])
        // (5×135) + (5×145) + (3×155) = 675 + 725 + 465 = 1865
        XCTAssertEqual(session.totalVolume, 1865.0, accuracy: 0.001)
    }

    func test_bestSet_returns_highest_volume_set() {
        let session = WorkoutSession()
        session.sets = makeSets(repsWeights: [(5, 135), (10, 100), (3, 185)])
        // volumes: 675, 1000, 555 → best = 10×100
        XCTAssertEqual(session.bestSet?.volume, 1000.0)
    }

    func test_isApproachingFailure_true_when_last_under_60_percent() {
        let session = WorkoutSession()
        session.sets = makeSets(
            repsWeights: [(8, 135), (8, 135), (8, 135)],
            velocities: [[2.0], [1.5], [1.1]]   // last = 1.1 / 2.0 = 55% < 60%
        )
        XCTAssertTrue(session.isApproachingFailure(for: exerciseId))
    }

    func test_isApproachingFailure_false_when_last_above_60_percent() {
        let session = WorkoutSession()
        session.sets = makeSets(
            repsWeights: [(8, 135), (8, 135), (8, 135)],
            velocities: [[2.0], [1.8], [1.4]]   // last = 1.4 / 2.0 = 70% > 60%
        )
        XCTAssertFalse(session.isApproachingFailure(for: exerciseId))
    }

    func test_normalizedVelocityTrend_first_set_is_1() {
        let session = WorkoutSession()
        session.sets = makeSets(
            repsWeights: [(8, 135), (8, 135)],
            velocities: [[2.0], [1.6]]
        )
        let trend = session.normalizedVelocityTrend(for: exerciseId)
        XCTAssertEqual(trend.first, 1.0, accuracy: 0.001)
    }

    func test_normalizedVelocityTrend_empty_when_no_velocity_data() {
        let session = WorkoutSession()
        session.sets = makeSets(repsWeights: [(8, 135), (8, 135)])
        XCTAssertTrue(session.normalizedVelocityTrend(for: exerciseId).isEmpty)
    }
}
